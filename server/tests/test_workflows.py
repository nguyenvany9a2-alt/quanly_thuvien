import concurrent.futures
import pytest
from fastapi.testclient import TestClient
import app as a


@pytest.fixture()
def client(tmp_path, monkeypatch):
    monkeypatch.setattr(a, "DB", tmp_path / "test.db")
    a.initialize(demo=True)
    with TestClient(a.app) as c:
        yield c


def login(c, role="reader", password="MotDemo@123"):
    r = c.post("/auth/login", json={"email": f"{role}@mot.local", "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": "Bearer " + r.json()["token"]}


def action(c, h, rid, name):
    return c.post(f"/requests/{rid}/action", headers=h, json={"action": name})


def request(c, h, bid=1):
    r = c.post(f"/requests/{bid}", headers=h)
    assert r.status_code == 200, r.text
    return c.get("/requests", headers=h).json()[0]["id"]


def test_registration_persistence_reset_and_private_data(client):
    c = client
    r = c.post(
        "/auth/register",
        json={
            "email": "new@mot.local",
            "password": "Password123",
            "name": "New Reader",
            "role": "manager",
        },
    )
    assert r.status_code == 200
    key = r.json()["recovery_code"]
    h = login(c, "new", "Password123")
    assert c.get("/me", headers=h).json()["role"] == "reader"
    a.initialize()
    assert c.get("/me", headers=h).status_code == 200
    assert c.get("/users", headers=h).status_code == 403
    assert c.get("/audit", headers=h).status_code == 403
    assert (
        c.post(
            "/auth/reset",
            json={
                "email": "new@mot.local",
                "password": "NewPass123",
                "recovery_code": "wrong",
            },
        ).status_code
        == 400
    )
    r = c.post(
        "/auth/reset",
        json={"email": "new@mot.local", "password": "NewPass123", "recovery_code": key},
    )
    assert r.status_code == 200
    assert c.get("/me", headers=h).status_code == 401
    assert (
        c.post(
            "/auth/reset",
            json={
                "email": "new@mot.local",
                "password": "NewPass123",
                "recovery_code": key,
            },
        ).status_code
        == 400
    )
    login(c, "new", "NewPass123")


def test_circulation_return_and_duplicate_protection(client):
    c = client
    reader = login(c)
    staff = login(c, "librarian")
    rid = request(c, reader)
    assert action(c, reader, rid, "approve").status_code == 403
    assert action(c, staff, rid, "approve").status_code == 200
    assert action(c, staff, rid, "issue").status_code == 200
    assert action(c, staff, rid, "issue").status_code == 400
    loan = c.get("/loans", headers=reader).json()[0]
    assert (
        c.post(f"/loans/{loan['id']}/return", headers=reader, json={}).status_code
        == 403
    )
    assert (
        c.post(
            f"/loans/{loan['id']}/return", headers=staff, json={"condition": "damaged"}
        ).status_code
        == 200
    )
    assert (
        c.post(f"/loans/{loan['id']}/return", headers=staff, json={}).status_code == 409
    )
    with a.db() as db:
        assert a.get(db, "copies", loan["copy_id"])["status"] == "damaged"


def test_renewal_and_policy_snapshot(client):
    c = client
    r = login(c)
    s = login(c, "librarian")
    m = login(c, "manager")
    rid = request(c, r)
    action(c, s, rid, "approve")
    action(c, s, rid, "issue")
    loan = c.get("/loans", headers=r).json()[0]
    p = c.get("/policies", headers=m).json()
    p["loan_days"] = 2
    assert c.put("/policies", headers=s, json=p).status_code == 403
    assert c.put("/policies", headers=m, json=p).status_code == 200
    assert c.get("/loans", headers=r).json()[0]["due_at"] == loan["due_at"]
    assert c.post(f"/loans/{loan['id']}/renew", headers=r).status_code == 200
    renewal = c.get("/renewals", headers=s).json()[0]
    assert (
        c.post(
            f"/renewals/{renewal['id']}/action", headers=s, json={"action": "approve"}
        ).status_code
        == 200
    )
    assert c.get("/loans", headers=r).json()[0]["renewals"] == 1
    assert c.post(f"/loans/{loan['id']}/renew", headers=r).status_code == 400


def test_expiry_limits_and_overdue(client):
    c = client
    r = login(c)
    s = login(c, "librarian")
    for bid in [1, 2, 3]:
        request(c, r, bid)
    assert c.post("/requests/4", headers=r).status_code == 400
    rid = c.get("/requests", headers=r).json()[0]["id"]
    action(c, s, rid, "approve")
    with a.db() as db:
        db.execute("UPDATE requests SET pickup_until=? WHERE id=?", (a.after(-1), rid))
    requests = c.get("/requests", headers=r).json()
    assert requests[0]["status"] == "expired"
    rid = request(c, r, 4)
    action(c, s, rid, "approve")
    action(c, s, rid, "issue")
    with a.db() as db:
        db.execute("UPDATE loans SET due_at=?", (a.after(-1),))
    assert c.post("/requests/5", headers=r).status_code == 400
    assert c.get("/reports", headers=s).json()["overdue"] == 1


def test_last_copy_and_account_controls(client):
    c = client
    r = login(c)
    s = login(c, "librarian")
    m = login(c, "manager")
    c.post(
        "/auth/register",
        json={
            "email": "other@mot.local",
            "password": "Password123",
            "name": "Other Reader",
        },
    )
    r2 = login(c, "other", "Password123")
    with a.db() as db:
        db.execute("UPDATE copies SET status='withdrawn' WHERE book_id=1 AND id!=1")
    id1 = request(c, r)
    id2 = request(c, r2)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(
            pool.map(lambda i: action(c, s, i, "approve").status_code, [id1, id2])
        )
    assert sorted(results) == [200, 409]
    assert len(c.get("/requests", headers=r).json()) == 1
    assert action(c, r, id2, "cancel").status_code == 403
    user = c.get("/me", headers=m).json()
    assert (
        c.put(
            f"/users/{user['id']}", headers=m, json={**user, "active": False}
        ).status_code
        == 400
    )
    u = c.get("/me", headers=r).json()
    assert (
        c.put(f"/users/{u['id']}", headers=s, json={**u, "role": "manager"}).status_code
        == 403
    )
    assert (
        c.put(f"/users/{u['id']}", headers=m, json={**u, "active": False}).status_code
        == 200
    )
    assert c.get("/me", headers=r).status_code == 401


def test_login_throttle(client):
    c = client
    for _ in range(8):
        assert (
            c.post(
                "/auth/login", json={"email": "reader@mot.local", "password": "bad"}
            ).status_code
            == 401
        )
    assert (
        c.post(
            "/auth/login", json={"email": "reader@mot.local", "password": "MotDemo@123"}
        ).status_code
        == 429
    )


def test_individual_notification_read_is_private(client):
    reader = login(client)
    manager = login(client, 'manager')
    assert client.post('/announcements', headers=manager, json={
        'title': 'Lịch đọc', 'body': 'Mời bạn ghé thư viện.', 'audience': 'reader'
    }).status_code == 200
    notice = next(n for n in client.get('/notifications', headers=reader).json() if n['id'] > 0)
    path = f"/notifications/{notice['id']}/read"
    assert client.post(path, headers=manager).status_code == 404
    assert client.post(path, headers=reader).status_code == 200
    assert client.post(path, headers=reader).status_code == 200
    notices = client.get('/notifications', headers=reader).json()
    assert next(n for n in notices if n['id'] == notice['id'])['is_read'] == 1
    assert client.post('/notifications/-1/read', headers=reader).status_code == 404
