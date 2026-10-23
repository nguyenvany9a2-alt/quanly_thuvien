"""MỌT API. SQLite transactions own stock and authorization; Flutter is a client."""

from contextlib import contextmanager, asynccontextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
import hashlib, hmac, json, os, secrets, sqlite3, re, base64
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

ROOT = Path(__file__).resolve().parent
DB = Path(os.environ.get("MOT_DB", str(ROOT / "data" / "mot.db")))


@asynccontextmanager
async def lifespan(application):
    initialize()
    yield


app = FastAPI(title="MỌT Library API", version="2.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)
bearer = HTTPBearer(auto_error=False)


def now():
    return datetime.now(timezone.utc).isoformat()


def after(days):
    return (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()


def fail(message, status=400):
    raise HTTPException(status, message)


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def password_hash(password):
    salt = secrets.token_hex(16)
    return (
        salt
        + ":"
        + hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 600000).hex()
    )


def verify(password, hashed):
    salt, value = hashed.split(":")
    return hmac.compare_digest(
        value,
        hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 600000).hex(),
    )


def validate_password(value):
    if len(value) < 8 or len(value) > 128:
        fail("Mật khẩu cần từ 8 đến 128 ký tự.")


def email_value(value):
    value = value.strip().lower()
    if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", value) or len(value) > 200:
        fail("Email không hợp lệ.")
    return value


@contextmanager
def db():
    DB.parent.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(DB, timeout=20)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA foreign_keys=ON")
    try:
        c.execute("BEGIN IMMEDIATE")
        yield c
        c.commit()
    except Exception:
        c.rollback()
        raise
    finally:
        c.close()


def rows(c, sql, args=()):
    return [dict(r) for r in c.execute(sql, args).fetchall()]


def one(c, sql, args=()):
    r = c.execute(sql, args).fetchone()
    return dict(r) if r else None


def get(c, table, i):
    r = one(c, f"SELECT * FROM {table} WHERE id=?", (i,))
    if not r:
        fail("Không tìm thấy dữ liệu.", 404)
    return r


def public(u):
    return {
        k: u[k]
        for k in [
            "id",
            "name",
            "email",
            "phone",
            "role",
            "active",
            "card_expires",
            "avatar",
            "preferences",
        ]
    }


def audit(c, u, action, detail):
    c.execute(
        "INSERT INTO audit(actor_id,action,detail,created_at) VALUES(?,?,?,?)",
        (u["id"], action, detail, now()),
    )


def notify(c, uid, title, body):
    c.execute(
        "INSERT INTO notifications(user_id,title,body,created_at) VALUES(?,?,?,?)",
        (uid, title, body, now()),
    )


def expire(c):
    for r in rows(
        c, "SELECT * FROM requests WHERE status='approved' AND pickup_until<?", (now(),)
    ):
        c.execute(
            "UPDATE copies SET status='available' WHERE id=? AND status='reserved'",
            (r["copy_id"],),
        )
        c.execute("UPDATE requests SET status='expired' WHERE id=?", (r["id"],))


def policy(c):
    return json.loads(c.execute("SELECT value FROM settings WHERE id=1").fetchone()[0])


def eligible(c, uid, extra=0):
    u = get(c, "users", uid)
    p = policy(c)
    if not u["active"] or u["card_expires"] < now()[:10]:
        fail("Thẻ thư viện bị khóa hoặc hết hạn.")
    if c.execute(
        "SELECT 1 FROM loans WHERE user_id=? AND status='borrowed' AND due_at<?",
        (uid, now()),
    ).fetchone():
        fail("Vui lòng trả sách quá hạn trước khi mượn thêm.")
    count = c.execute(
        "SELECT count(*) FROM loans WHERE user_id=? AND status='borrowed'", (uid,)
    ).fetchone()[0]
    count += c.execute(
        "SELECT count(*) FROM requests WHERE user_id=? AND status IN ('pending','approved')",
        (uid,),
    ).fetchone()[0]
    if count + extra > p["max_books"]:
        fail("Đã đạt số sách mượn và yêu cầu tối đa.")


def initialize(demo=False):
    with db() as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY,name TEXT NOT NULL,email TEXT UNIQUE NOT NULL,password TEXT NOT NULL,recovery TEXT NOT NULL,phone TEXT NOT NULL DEFAULT '',role TEXT NOT NULL CHECK(role IN ('reader','librarian','manager')),active INTEGER NOT NULL DEFAULT 1,card_expires TEXT NOT NULL,created_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY,user_id INTEGER REFERENCES users(id),expires TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS attempts(email TEXT PRIMARY KEY,count INTEGER NOT NULL DEFAULT 0,until TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS books(id INTEGER PRIMARY KEY,title TEXT NOT NULL,author TEXT NOT NULL,category TEXT NOT NULL,description TEXT NOT NULL DEFAULT '',cover TEXT NOT NULL DEFAULT '',source TEXT NOT NULL DEFAULT '',isbn TEXT NOT NULL DEFAULT '',publisher TEXT NOT NULL DEFAULT '',year INTEGER,active INTEGER NOT NULL DEFAULT 1);
        CREATE TABLE IF NOT EXISTS copies(id INTEGER PRIMARY KEY,book_id INTEGER NOT NULL REFERENCES books(id),code TEXT UNIQUE NOT NULL,shelf TEXT NOT NULL DEFAULT 'A1',status TEXT NOT NULL CHECK(status IN ('available','reserved','on_loan','damaged','lost','withdrawn')));
        CREATE TABLE IF NOT EXISTS requests(id INTEGER PRIMARY KEY,user_id INTEGER NOT NULL REFERENCES users(id),book_id INTEGER NOT NULL REFERENCES books(id),copy_id INTEGER REFERENCES copies(id),status TEXT NOT NULL,created_at TEXT NOT NULL,pickup_until TEXT,processed_by INTEGER REFERENCES users(id),note TEXT NOT NULL DEFAULT '');
        CREATE UNIQUE INDEX IF NOT EXISTS request_active ON requests(user_id,book_id) WHERE status IN ('pending','approved');
        CREATE TABLE IF NOT EXISTS loans(id INTEGER PRIMARY KEY,request_id INTEGER UNIQUE REFERENCES requests(id),user_id INTEGER NOT NULL REFERENCES users(id),copy_id INTEGER NOT NULL REFERENCES copies(id),issued_by INTEGER REFERENCES users(id),issued_at TEXT NOT NULL,due_at TEXT NOT NULL,returned_at TEXT,received_by INTEGER REFERENCES users(id),status TEXT NOT NULL,condition TEXT NOT NULL DEFAULT '',renewals INTEGER NOT NULL DEFAULT 0);
        CREATE UNIQUE INDEX IF NOT EXISTS copy_active ON loans(copy_id) WHERE status='borrowed';
        CREATE TABLE IF NOT EXISTS renewals(id INTEGER PRIMARY KEY,loan_id INTEGER NOT NULL REFERENCES loans(id),status TEXT NOT NULL DEFAULT 'pending',created_at TEXT NOT NULL,processed_by INTEGER REFERENCES users(id));
        CREATE UNIQUE INDEX IF NOT EXISTS renewal_active ON renewals(loan_id) WHERE status='pending';
        CREATE TABLE IF NOT EXISTS favorites(user_id INTEGER REFERENCES users(id),book_id INTEGER REFERENCES books(id),PRIMARY KEY(user_id,book_id));
        CREATE TABLE IF NOT EXISTS notifications(id INTEGER PRIMARY KEY,user_id INTEGER REFERENCES users(id),title TEXT NOT NULL,body TEXT NOT NULL,created_at TEXT NOT NULL,is_read INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE IF NOT EXISTS settings(id INTEGER PRIMARY KEY,value TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS audit(id INTEGER PRIMARY KEY,actor_id INTEGER REFERENCES users(id),action TEXT NOT NULL,detail TEXT NOT NULL,created_at TEXT NOT NULL);
        """)
        # Additive migrations: preserve accounts, loans and existing catalogue.
        columns = {r[1] for r in c.execute("PRAGMA table_info(users)")}
        for name, definition in [
            ("avatar", "TEXT NOT NULL DEFAULT ''"),
            ("preferences", "TEXT NOT NULL DEFAULT '{}'"),
        ]:
            if name not in columns:
                c.execute(f"ALTER TABLE users ADD COLUMN {name} {definition}")
        c.executescript("""
        CREATE TABLE IF NOT EXISTS reviews(user_id INTEGER REFERENCES users(id),book_id INTEGER REFERENCES books(id),rating INTEGER CHECK(rating BETWEEN 1 AND 5),comment TEXT NOT NULL,updated_at TEXT NOT NULL,PRIMARY KEY(user_id,book_id));
        CREATE TABLE IF NOT EXISTS reading_content(book_id INTEGER PRIMARY KEY REFERENCES books(id),text TEXT NOT NULL,credit TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS reading_progress(user_id INTEGER REFERENCES users(id),book_id INTEGER REFERENCES books(id),page INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(user_id,book_id));
        """)
        c.execute(
            "INSERT OR IGNORE INTO settings VALUES(1,?)",
            (
                json.dumps(
                    dict(
                        max_books=3,
                        loan_days=14,
                        hold_days=2,
                        renew_days=7,
                        max_renewals=1,
                    )
                ),
            ),
        )
        catalog = ROOT / "catalog.json"
        if not c.execute("SELECT 1 FROM books").fetchone() and catalog.exists():
            for b in json.loads(catalog.read_text(encoding="utf-8")):
                i = c.execute(
                    "INSERT INTO books(title,author,category,description,cover,source) VALUES(?,?,?,?,?,?)",
                    tuple(
                        b[k]
                        for k in [
                            "title",
                            "author",
                            "category",
                            "description",
                            "cover",
                            "source",
                        ]
                    ),
                ).lastrowid
                for j in range(1, 4):
                    c.execute(
                        "INSERT INTO copies(book_id,code,shelf,status) VALUES(?,?,?,'available')",
                        (i, f"MOT-{i:03}-{j:02}", f"A{(i-1)//5+1}"),
                    )
        if demo:
            for role, name in [
                ("manager", "Quản lý MỌT"),
                ("librarian", "Thủ thư MỌT"),
                ("reader", "Bạn đọc MỌT"),
            ]:
                email = f"{role}@mot.local"
                if not c.execute(
                    "SELECT 1 FROM users WHERE email=?", (email,)
                ).fetchone():
                    c.execute(
                        "INSERT INTO users(name,email,password,recovery,role,card_expires,created_at) VALUES(?,?,?,?,?,?,?)",
                        (
                            name,
                            email,
                            password_hash("MotDemo@123"),
                            digest(secrets.token_urlsafe(32)),
                            role,
                            after(365)[:10],
                            now(),
                        ),
                    )

        text_path = ROOT / "kieu.json"
        if text_path.exists():
            book = one(
                c,
                "SELECT id FROM books WHERE title=? AND author=?",
                ("Truyện Kiều", "Nguyễn Du"),
            )
            if not book:
                bid = c.execute(
                    "INSERT INTO books(title,author,category,description,cover,source) VALUES(?,?,?,?,?,?)",
                    (
                        "Truyện Kiều",
                        "Nguyễn Du",
                        "Văn học Việt Nam",
                        "Truyện thơ lục bát của Nguyễn Du. Bản số gồm 3.254 câu, có mục lục và lưu vị trí đọc.",
                        "assets/images/kieu.png",
                        "https://vi.wikisource.org/wiki/Truyện_Kiều",
                    ),
                ).lastrowid
            else:
                bid = book["id"]
            k = json.loads(text_path.read_text(encoding="utf-8"))
            text = "\n\n".join(section["text"] for section in k["sections"])
            c.execute(
                "INSERT OR IGNORE INTO reading_content VALUES(?,?,?)",
                (
                    bid,
                    text,
                    "Nguyễn Du · Truyện Kiều. Văn bản từ Wikisource: https://vi.wikisource.org/wiki/Truyện_Kiều. Tác phẩm thuộc phạm vi công cộng.",
                ),
            )


# Explicit bootstrap: python manage.py init --demo. Importing app never creates accounts.
def current(auth: HTTPAuthorizationCredentials | None = Depends(bearer)):
    if not auth:
        fail("Vui lòng đăng nhập.", 401)
    with db() as c:
        u = one(
            c,
            "SELECT u.* FROM users u JOIN sessions s ON s.user_id=u.id WHERE s.token=? AND s.expires>?",
            (digest(auth.credentials), now()),
        )
        if not u or not u["active"]:
            fail("Phiên đăng nhập đã hết hạn.", 401)
        return u


def staff(u=Depends(current)):
    if u["role"] not in ["librarian", "manager"]:
        fail("Chỉ nhân viên được thực hiện.", 403)
    return u


def manager(u=Depends(current)):
    if u["role"] != "manager":
        fail("Chỉ quản lý được thực hiện.", 403)
    return u


class Login(BaseModel):
    email: str
    password: str = Field(max_length=128)
    remember: bool = False


class Register(Login):
    name: str = Field(min_length=2, max_length=100)
    phone: str = Field(default="", max_length=30)


class Reset(BaseModel):
    email: str
    recovery_code: str = Field(max_length=200)
    password: str = Field(max_length=128)


class Profile(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    phone: str = Field(default="", max_length=30)


class ChangePassword(BaseModel):
    old_password: str = Field(max_length=128)
    password: str = Field(max_length=128)


@app.get("/health")
def health():
    return {"status": "ok", "app": "MỌT"}


@app.post("/auth/register")
def register(v: Register):
    email = email_value(v.email)
    validate_password(v.password)
    key = secrets.token_urlsafe(24)
    with db() as c:
        if c.execute("SELECT 1 FROM users WHERE email=?", (email,)).fetchone():
            fail("Email đã được đăng ký.", 409)
        if not v.name.strip():
            fail("Vui lòng nhập họ tên.")
        c.execute(
            "INSERT INTO users(name,email,password,recovery,phone,role,card_expires,created_at) VALUES(?,?,?,?,?,'reader',?,?)",
            (
                v.name.strip(),
                email,
                password_hash(v.password),
                digest(key),
                v.phone,
                after(365)[:10],
                now(),
            ),
        )
    return {
        "message": "Đăng ký thành công. Hãy lưu mã khôi phục ở nơi an toàn.",
        "recovery_code": key,
    }


@app.post("/auth/login")
def login(v: Login):
    email = email_value(v.email)
    error = False
    blocked = False
    with db() as c:
        a = one(c, "SELECT * FROM attempts WHERE email=?", (email,))
        if a and a["count"] >= 8 and a["until"] > now():
            blocked = True
        else:
            u = one(c, "SELECT * FROM users WHERE email=?", (email,))
            if not u or not verify(v.password, u["password"]) or not u["active"]:
                n = a["count"] + 1 if a and a["until"] > now() else 1
                c.execute(
                    "INSERT OR REPLACE INTO attempts VALUES(?,?,?)",
                    (email, n, after(10 / 1440)),
                )
                error = True
            else:
                c.execute("DELETE FROM attempts WHERE email=?", (email,))
                token = secrets.token_urlsafe(32)
                c.execute(
                    "INSERT INTO sessions VALUES(?,?,?)",
                    (digest(token), u["id"], after(30 if v.remember else 0.5)),
                )
    if blocked:
        fail("Thử quá nhiều lần. Vui lòng chờ 10 phút.", 429)
    if error:
        fail("Email hoặc mật khẩu không đúng, hoặc tài khoản bị khóa.", 401)
    return {"token": token, "user": public(u)}


@app.post("/auth/reset")
def reset(v: Reset):
    email = email_value(v.email)
    validate_password(v.password)
    with db() as c:
        u = one(c, "SELECT * FROM users WHERE email=?", (email,))
        if not u or not hmac.compare_digest(
            u["recovery"], digest(v.recovery_code.strip())
        ):
            fail("Email hoặc mã khôi phục không đúng.")
        key = secrets.token_urlsafe(24)
        c.execute(
            "UPDATE users SET password=?,recovery=? WHERE id=?",
            (password_hash(v.password), digest(key), u["id"]),
        )
        c.execute("DELETE FROM sessions WHERE user_id=?", (u["id"],))
        c.execute("DELETE FROM attempts WHERE email=?", (email,))
    return {
        "recovery_code": key,
        "message": "Đã đổi mật khẩu. Mã khôi phục cũ không còn hiệu lực.",
    }


@app.get("/me")
def me(u=Depends(current)):
    return public(u)


@app.put("/me")
def profile(v: Profile, u=Depends(current)):
    if not v.name.strip():
        fail("Vui lòng nhập họ tên.")
    with db() as c:
        c.execute(
            "UPDATE users SET name=?,phone=? WHERE id=?",
            (v.name.strip(), v.phone, u["id"]),
        )
    return {"message": "Đã cập nhật hồ sơ."}


@app.post("/auth/password")
def change_password(v: ChangePassword, u=Depends(current)):
    validate_password(v.password)
    if not verify(v.old_password, u["password"]):
        fail("Mật khẩu hiện tại chưa đúng.")
    with db() as c:
        c.execute(
            "UPDATE users SET password=? WHERE id=?",
            (password_hash(v.password), u["id"]),
        )
        c.execute("DELETE FROM sessions WHERE user_id=?", (u["id"],))
    return {"message": "Đã đổi mật khẩu. Hãy đăng nhập lại."}


@app.post("/auth/logout")
def logout(auth: HTTPAuthorizationCredentials | None = Depends(bearer)):
    if auth:
        with db() as c:
            c.execute("DELETE FROM sessions WHERE token=?", (digest(auth.credentials),))
    return {"message": "Đã đăng xuất."}


@app.get("/books")
def books(u=Depends(current)):
    with db() as c:
        expire(c)
        return rows(
            c,
            """SELECT b.*, (SELECT count(*) FROM copies WHERE book_id=b.id AND status='available') available,
        (SELECT count(*) FROM copies WHERE book_id=b.id AND status!='withdrawn') total,
        (SELECT round(avg(rating),1) FROM reviews WHERE book_id=b.id) rating,
        (SELECT count(*) FROM reviews WHERE book_id=b.id) review_count,
        EXISTS(SELECT 1 FROM reading_content WHERE book_id=b.id) readable,
        EXISTS(SELECT 1 FROM favorites WHERE user_id=? AND book_id=b.id) favorite FROM books b WHERE b.active=1 OR ?!='reader' ORDER BY b.id DESC""",
            (u["id"], u["role"]),
        )


@app.post("/books/{bid}/favorite")
def favorite(bid: int, u=Depends(current)):
    with db() as c:
        get(c, "books", bid)
        if c.execute(
            "SELECT 1 FROM favorites WHERE user_id=? AND book_id=?", (u["id"], bid)
        ).fetchone():
            c.execute(
                "DELETE FROM favorites WHERE user_id=? AND book_id=?", (u["id"], bid)
            )
        else:
            c.execute("INSERT INTO favorites VALUES(?,?)", (u["id"], bid))
    return {"message": "Đã cập nhật sách yêu thích."}


class BookInput(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    author: str = Field(min_length=1, max_length=150)
    category: str = Field(min_length=1, max_length=80)
    description: str = Field(default="", max_length=2000)
    cover: str = Field(default="", max_length=1000)
    source: str = Field(default="", max_length=1000)
    isbn: str = Field(default="", max_length=40)
    publisher: str = Field(default="", max_length=150)
    year: int | None = Field(default=None, ge=1000, le=2200)
    active: bool = True


@app.post("/books")
def create_book(v: BookInput, u=Depends(staff)):
    with db() as c:
        d = v.model_dump()
        i = c.execute(
            "INSERT INTO books("
            + ",".join(d)
            + ") VALUES("
            + ",".join("?" for _ in d)
            + ")",
            tuple(d.values()),
        ).lastrowid
        audit(c, u, "create_book", str(i))
    return {"id": i, "message": "Đã thêm đầu sách. Thêm bản sách để cho mượn."}


@app.put("/books/{bid}")
def update_book(bid: int, v: BookInput, u=Depends(staff)):
    with db() as c:
        get(c, "books", bid)
        d = v.model_dump()
        c.execute(
            "UPDATE books SET " + ",".join(k + "=?" for k in d) + " WHERE id=?",
            (*d.values(), bid),
        )
        audit(c, u, "update_book", str(bid))
    return {"message": "Đã cập nhật sách."}


@app.get("/books/{bid}/copies")
def copies(bid: int, u=Depends(staff)):
    with db() as c:
        return rows(c, "SELECT * FROM copies WHERE book_id=? ORDER BY id", (bid,))


class CopyInput(BaseModel):
    code: str = Field(min_length=1, max_length=60)
    shelf: str = Field(min_length=1, max_length=60)
    status: str = "available"


@app.post("/books/{bid}/copies")
def create_copy(bid: int, v: CopyInput, u=Depends(staff)):
    if v.status not in ["available", "damaged", "lost", "withdrawn"]:
        fail("Trạng thái bản sách không hợp lệ.")
    with db() as c:
        get(c, "books", bid)
        if c.execute("SELECT 1 FROM copies WHERE code=?", (v.code.strip(),)).fetchone():
            fail("Mã bản sách đã tồn tại.", 409)
        c.execute(
            "INSERT INTO copies(book_id,code,shelf,status) VALUES(?,?,?,?)",
            (bid, v.code.strip(), v.shelf, v.status),
        )
        audit(c, u, "add_copy", v.code)
    return {"message": "Đã thêm bản sách."}


@app.put("/copies/{cid}")
def update_copy(cid: int, v: CopyInput, u=Depends(staff)):
    with db() as c:
        old = get(c, "copies", cid)
        if old["status"] in ["on_loan", "reserved"]:
            fail("Bản sách đang mượn/giữ; xử lý phiếu trước.")
        if v.status not in ["available", "damaged", "lost", "withdrawn"]:
            fail("Trạng thái không hợp lệ.")
        if c.execute(
            "SELECT 1 FROM copies WHERE code=? AND id!=?", (v.code, cid)
        ).fetchone():
            fail("Trùng mã bản sách.")
        c.execute(
            "UPDATE copies SET code=?,shelf=?,status=? WHERE id=?",
            (v.code, v.shelf, v.status, cid),
        )
        audit(c, u, "update_copy", str(cid))
    return {"message": "Đã cập nhật bản sách."}


@app.get("/requests")
def requests(u=Depends(current)):
    with db() as c:
        expire(c)
        return rows(
            c,
            "SELECT r.*,b.title,b.cover,u.name,u.email,cp.code FROM requests r JOIN books b ON b.id=r.book_id JOIN users u ON u.id=r.user_id LEFT JOIN copies cp ON cp.id=r.copy_id WHERE ?!='reader' OR r.user_id=? ORDER BY r.id DESC",
            (u["role"], u["id"]),
        )


@app.post("/requests/{bid}")
def request_book(bid: int, u=Depends(current)):
    if u["role"] != "reader":
        fail("Đăng nhập độc giả để gửi yêu cầu.", 403)
    with db() as c:
        expire(c)
        eligible(c, u["id"], 1)
        b = get(c, "books", bid)
        if not b["active"]:
            fail("Sách đã ngừng phục vụ.")
        if c.execute(
            "SELECT 1 FROM requests WHERE user_id=? AND book_id=? AND status IN ('pending','approved')",
            (u["id"], bid),
        ).fetchone():
            fail("Bạn đã có yêu cầu cho sách này.")
        if c.execute(
            "SELECT 1 FROM loans l JOIN copies cp ON l.copy_id=cp.id WHERE l.user_id=? AND cp.book_id=? AND l.status='borrowed'",
            (u["id"], bid),
        ).fetchone():
            fail("Bạn đang mượn sách này.")
        if not c.execute(
            "SELECT 1 FROM copies WHERE book_id=? AND status='available'", (bid,)
        ).fetchone():
            fail("Hiện chưa có bản sách sẵn sàng.")
        c.execute(
            "INSERT INTO requests(user_id,book_id,status,created_at) VALUES(?,?,'pending',?)",
            (u["id"], bid, now()),
        )
    return {"message": "Đã gửi yêu cầu. Chờ thủ thư duyệt trước khi đến nhận."}


class Action(BaseModel):
    action: str
    note: str = Field(default="", max_length=500)


@app.post("/requests/{rid}/action")
def request_action(rid: int, v: Action, u=Depends(current)):
    with db() as c:
        expire(c)
        r = get(c, "requests", rid)
        p = policy(c)
        if u["role"] == "reader" and (v.action != "cancel" or r["user_id"] != u["id"]):
            fail("Không có quyền xử lý yêu cầu.", 403)
        if v.action == "approve":
            if r["status"] != "pending":
                fail("Yêu cầu không còn chờ duyệt.")
            eligible(c, r["user_id"])
            b = get(c, "books", r["book_id"])
            if not b["active"]:
                fail("Sách đã ngừng phục vụ.")
            cp = one(
                c,
                "SELECT * FROM copies WHERE book_id=? AND status='available' ORDER BY id LIMIT 1",
                (r["book_id"],),
            )
            if not cp:
                fail("Không còn bản sách sẵn sàng.", 409)
            c.execute("UPDATE copies SET status='reserved' WHERE id=?", (cp["id"],))
            c.execute(
                "UPDATE requests SET status='approved',copy_id=?,pickup_until=?,processed_by=? WHERE id=?",
                (cp["id"], after(p["hold_days"]), u["id"], rid),
            )
            notify(
                c,
                r["user_id"],
                "Đã duyệt yêu cầu",
                f"Mời đến nhận {b['title']} trong {p['hold_days']} ngày.",
            )
        elif v.action in ["reject", "cancel"]:
            if r["status"] not in ["pending", "approved"]:
                fail("Không thể hủy/từ chối yêu cầu đã kết thúc.")
            if r["copy_id"]:
                c.execute(
                    "UPDATE copies SET status='available' WHERE id=? AND status='reserved'",
                    (r["copy_id"],),
                )
            c.execute(
                "UPDATE requests SET status=?,note=?,processed_by=? WHERE id=?",
                (
                    "rejected" if v.action == "reject" else "cancelled",
                    v.note,
                    u["id"],
                    rid,
                ),
            )
            notify(
                c,
                r["user_id"],
                "Yêu cầu đã được cập nhật",
                v.note or "Yêu cầu đã hủy hoặc bị từ chối.",
            )
        elif v.action == "issue":
            if r["status"] != "approved":
                fail("Chỉ giao sách cho yêu cầu đã duyệt.")
            eligible(c, r["user_id"])
            cp = get(c, "copies", r["copy_id"])
            if cp["status"] != "reserved":
                fail("Bản sách không còn được giữ.", 409)
            c.execute(
                "INSERT INTO loans(request_id,user_id,copy_id,issued_by,issued_at,due_at,status) VALUES(?,?,?,?,?,?,'borrowed')",
                (
                    rid,
                    r["user_id"],
                    r["copy_id"],
                    u["id"],
                    now(),
                    after(p["loan_days"]),
                ),
            )
            c.execute("UPDATE copies SET status='on_loan' WHERE id=?", (r["copy_id"],))
            c.execute(
                "UPDATE requests SET status='fulfilled',processed_by=? WHERE id=?",
                (u["id"], rid),
            )
            notify(
                c,
                r["user_id"],
                "Đã nhận sách",
                f"Hạn trả sau {p['loan_days']} ngày. Xem trong mục Sách của tôi.",
            )
        else:
            fail("Thao tác không hợp lệ.")
        audit(c, u, v.action, f"request:{rid}")
    return {"message": "Đã xử lý yêu cầu."}


@app.get("/loans")
def loans(u=Depends(current)):
    with db() as c:
        return rows(
            c,
            """SELECT l.*,b.title,b.cover,b.id book_id,cp.code,u.name,u.email,
    EXISTS(SELECT 1 FROM renewals r WHERE r.loan_id=l.id AND r.status='pending') renewal_pending,
    (l.status='borrowed' AND l.due_at<?) overdue FROM loans l JOIN copies cp ON cp.id=l.copy_id JOIN books b ON b.id=cp.book_id JOIN users u ON u.id=l.user_id WHERE ?!='reader' OR l.user_id=? ORDER BY l.id DESC""",
            (now(), u["role"], u["id"]),
        )


class ReturnInput(BaseModel):
    condition: str = "available"
    note: str = Field(default="", max_length=500)


@app.post("/loans/{lid}/return")
def return_book(lid: int, v: ReturnInput, u=Depends(staff)):
    if v.condition not in ["available", "damaged", "lost"]:
        fail("Tình trạng không hợp lệ.")
    with db() as c:
        l = get(c, "loans", lid)
        if l["status"] != "borrowed":
            fail("Phiếu này đã được nhận trả.", 409)
        c.execute(
            "UPDATE loans SET status=?,returned_at=?,received_by=?,condition=? WHERE id=?",
            (
                "lost" if v.condition == "lost" else "returned",
                now(),
                u["id"],
                v.note or v.condition,
                lid,
            ),
        )
        c.execute("UPDATE copies SET status=? WHERE id=?", (v.condition, l["copy_id"]))
        c.execute(
            "UPDATE renewals SET status='rejected',processed_by=? WHERE loan_id=? AND status='pending'",
            (u["id"], lid),
        )
        notify(
            c,
            l["user_id"],
            "Đã xử lý trả sách",
            f"Phiếu #{lid} đã được thủ thư xác nhận.",
        )
        audit(c, u, "return", str(lid))
    return {"message": "Đã ghi nhận trả sách và cập nhật kho."}


@app.post("/loans/{lid}/renew")
def ask_renew(lid: int, u=Depends(current)):
    with db() as c:
        l = get(c, "loans", lid)
        p = policy(c)
        if l["user_id"] != u["id"]:
            fail("Không có quyền.", 403)
        if (
            l["status"] != "borrowed"
            or l["due_at"] < now()
            or l["renewals"] >= p["max_renewals"]
        ):
            fail("Không đủ điều kiện gia hạn.")
        if c.execute(
            "SELECT 1 FROM renewals WHERE loan_id=? AND status='pending'", (lid,)
        ).fetchone():
            fail("Đã có yêu cầu gia hạn.")
        c.execute("INSERT INTO renewals(loan_id,created_at) VALUES(?,?)", (lid, now()))
    return {"message": "Đã gửi yêu cầu gia hạn."}


@app.get("/renewals")
def renewals(u=Depends(staff)):
    with db() as c:
        return rows(
            c,
            "SELECT r.*,b.title,u.name FROM renewals r JOIN loans l ON l.id=r.loan_id JOIN users u ON u.id=l.user_id JOIN copies cp ON cp.id=l.copy_id JOIN books b ON b.id=cp.book_id ORDER BY r.id DESC",
        )


@app.post("/renewals/{rid}/action")
def renew_action(rid: int, v: Action, u=Depends(staff)):
    if v.action not in ["approve", "reject"]:
        fail("Thao tác không hợp lệ.")
    with db() as c:
        r = get(c, "renewals", rid)
        l = get(c, "loans", r["loan_id"])
        p = policy(c)
        if r["status"] != "pending":
            fail("Yêu cầu đã được xử lý.")
        if v.action == "approve":
            eligible(c, l["user_id"])
            if (
                l["status"] != "borrowed"
                or l["due_at"] < now()
                or l["renewals"] >= p["max_renewals"]
            ):
                fail("Không đủ điều kiện gia hạn.")
            bid = get(c, "copies", l["copy_id"])["book_id"]
            if c.execute(
                "SELECT 1 FROM requests WHERE book_id=? AND status IN ('pending','approved') AND user_id!=?",
                (bid, l["user_id"]),
            ).fetchone():
                fail("Có độc giả khác đang chờ sách.")
            due = (
                datetime.fromisoformat(l["due_at"]) + timedelta(days=p["renew_days"])
            ).isoformat()
            c.execute(
                "UPDATE loans SET due_at=?,renewals=renewals+1 WHERE id=?",
                (due, l["id"]),
            )
        c.execute(
            "UPDATE renewals SET status=?,processed_by=? WHERE id=?",
            ("approved" if v.action == "approve" else "rejected", u["id"], rid),
        )
        notify(
            c,
            l["user_id"],
            "Kết quả gia hạn",
            "Được duyệt." if v.action == "approve" else "Chưa được duyệt.",
        )
        audit(c, u, "renew_" + v.action, str(rid))
    return {"message": "Đã xử lý gia hạn."}


@app.get("/notifications")
def notifications(u=Depends(current)):
    with db() as c:
        result = rows(
            c,
            "SELECT * FROM notifications WHERE user_id=? ORDER BY id DESC LIMIT 100",
            (u["id"],),
        )
        for l in rows(
            c,
            "SELECT id,due_at FROM loans WHERE user_id=? AND status='borrowed' AND due_at<?",
            (u["id"], after(2)),
        ):
            result.insert(
                0,
                dict(
                    id=-l["id"],
                    title="Nhắc hạn trả sách",
                    body=f"Phiếu #{l['id']} đến hạn {l['due_at'][:10]}",
                    is_read=0,
                    created_at=now(),
                ),
            )
        return result


@app.post("/notifications/{notification_id}/read")
def read_one_notification(notification_id: int, u=Depends(current)):
    with db() as c:
        result = c.execute(
            "UPDATE notifications SET is_read=1 WHERE id=? AND user_id=?",
            (notification_id, u["id"]),
        )
        if result.rowcount == 0:
            raise HTTPException(404, "Không tìm thấy thông báo.")
    return {"message": "Đã đọc thông báo."}


@app.post("/notifications/read")
def read_notifications(u=Depends(current)):
    with db() as c:
        c.execute("UPDATE notifications SET is_read=1 WHERE user_id=?", (u["id"],))
    return {"message": "Đã đánh dấu đã đọc."}


@app.get("/users")
def users(u=Depends(staff)):
    with db() as c:
        return [
            public(x)
            for x in rows(
                c,
                "SELECT * FROM users WHERE role='reader' OR ?='manager' ORDER BY id DESC",
                (u["role"],),
            )
        ]


class UserEdit(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    phone: str = Field(default="", max_length=30)
    role: str = "reader"
    active: bool = True
    card_expires: str


@app.put("/users/{uid}")
def edit_user(uid: int, v: UserEdit, u=Depends(staff)):
    if v.role not in ["reader", "librarian", "manager"]:
        fail("Vai trò không hợp lệ.")
    try:
        datetime.strptime(v.card_expires, "%Y-%m-%d")
    except ValueError:
        fail("Ngày hết hạn phải theo YYYY-MM-DD.")
    with db() as c:
        target = get(c, "users", uid)
        if u["role"] != "manager" and (
            target["role"] != "reader" or v.role != "reader"
        ):
            fail("Không có quyền đổi vai trò.", 403)
        if uid == u["id"] and (not v.active or v.role != u["role"]):
            fail("Không thể tự khóa hoặc tự đổi quyền.")
        if (
            target["role"] == "manager"
            and target["active"]
            and (not v.active or v.role != "manager")
            and c.execute(
                "SELECT count(*) FROM users WHERE role='manager' AND active=1"
            ).fetchone()[0]
            <= 1
        ):
            fail("Phải giữ ít nhất một quản lý hoạt động.")
        c.execute(
            "UPDATE users SET name=?,phone=?,role=?,active=?,card_expires=? WHERE id=?",
            (v.name, v.phone, v.role, v.active, v.card_expires, uid),
        )
        if target["role"] != v.role or not v.active:
            c.execute("DELETE FROM sessions WHERE user_id=?", (uid,))
        audit(c, u, "update_user", str(uid))
    return {"message": "Đã cập nhật tài khoản."}


class StaffInput(Register):
    role: str = "librarian"


@app.post("/users")
def add_staff(v: StaffInput, u=Depends(manager)):
    if v.role not in ["reader", "librarian", "manager"]:
        fail("Vai trò không hợp lệ.")
    email = email_value(v.email)
    validate_password(v.password)
    key = secrets.token_urlsafe(24)
    with db() as c:
        if c.execute("SELECT 1 FROM users WHERE email=?", (email,)).fetchone():
            fail("Email đã tồn tại.")
        c.execute(
            "INSERT INTO users(name,email,password,recovery,phone,role,card_expires,created_at) VALUES(?,?,?,?,?,?,?,?)",
            (
                v.name,
                email,
                password_hash(v.password),
                digest(key),
                v.phone,
                v.role,
                after(365)[:10],
                now(),
            ),
        )
        audit(c, u, "create_user", email)
    return {
        "message": "Đã tạo tài khoản. Bàn giao mật khẩu và mã khôi phục riêng cho người dùng.",
        "recovery_code": key,
    }


class PolicyInput(BaseModel):
    max_books: int = Field(ge=1, le=20)
    loan_days: int = Field(ge=1, le=90)
    hold_days: int = Field(ge=1, le=14)
    renew_days: int = Field(ge=1, le=30)
    max_renewals: int = Field(ge=0, le=5)


@app.get("/policies")
def policies(u=Depends(current)):
    with db() as c:
        return policy(c)


@app.put("/policies")
def save_policies(v: PolicyInput, u=Depends(manager)):
    with db() as c:
        c.execute(
            "UPDATE settings SET value=? WHERE id=1", (json.dumps(v.model_dump()),)
        )
        audit(c, u, "update_policy", json.dumps(v.model_dump()))
    return {"message": "Đã lưu chính sách. Hạn trả phiếu cũ giữ nguyên."}


@app.get("/audit")
def audits(u=Depends(manager)):
    with db() as c:
        return rows(
            c,
            "SELECT a.*,u.name FROM audit a JOIN users u ON a.actor_id=u.id ORDER BY a.id DESC LIMIT 100",
        )


@app.get("/reports")
def reports(u=Depends(staff)):
    with db() as c:
        expire(c)
        counts = {
            k: c.execute(sql, args).fetchone()[0]
            for k, sql, args in [
                ("books", "SELECT count(*) FROM books WHERE active=1", ()),
                ("copies", "SELECT count(*) FROM copies WHERE status!='withdrawn'", ()),
                (
                    "available",
                    "SELECT count(*) FROM copies WHERE status='available'",
                    (),
                ),
                ("borrowed", "SELECT count(*) FROM loans WHERE status='borrowed'", ()),
                (
                    "overdue",
                    "SELECT count(*) FROM loans WHERE status='borrowed' AND due_at<?",
                    (now(),),
                ),
                ("readers", "SELECT count(*) FROM users WHERE role='reader'", ()),
                ("pending", "SELECT count(*) FROM requests WHERE status='pending'", ()),
            ]
        }
        counts["popular"] = rows(
            c,
            "SELECT b.title,count(*) count FROM loans l JOIN copies cp ON cp.id=l.copy_id JOIN books b ON b.id=cp.book_id GROUP BY b.id ORDER BY count DESC LIMIT 5",
        )
        counts["monthly"] = rows(
            c,
            "SELECT substr(issued_at,1,7) month,count(*) count FROM loans GROUP BY month ORDER BY month DESC LIMIT 6",
        )
        counts["monthly"] = monthly_series(counts["monthly"])
        return counts


class ReviewInput(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str = Field(default="", max_length=1500)


@app.get("/books/{bid}/reviews")
def book_reviews(bid: int, u=Depends(current)):
    with db() as c:
        get(c, "books", bid)
        return rows(
            c,
            "SELECT r.*,u.name FROM reviews r JOIN users u ON u.id=r.user_id WHERE book_id=? ORDER BY updated_at DESC",
            (bid,),
        )


@app.put("/books/{bid}/review")
def save_review(bid: int, v: ReviewInput, u=Depends(current)):
    with db() as c:
        b = get(c, "books", bid)
        if not b["active"]:
            fail("Sách đã ngừng phục vụ.")
        c.execute(
            "INSERT INTO reviews VALUES(?,?,?,?,?) ON CONFLICT(user_id,book_id) DO UPDATE SET rating=excluded.rating,comment=excluded.comment,updated_at=excluded.updated_at",
            (u["id"], bid, v.rating, v.comment.strip(), now()),
        )
    return {"message": "Đã lưu đánh giá."}


class AnnouncementInput(BaseModel):
    title: str = Field(min_length=1, max_length=150)
    body: str = Field(min_length=1, max_length=3000)
    audience: str = "all"


@app.post("/announcements")
def announce(v: AnnouncementInput, u=Depends(manager)):
    if not v.title.strip() or not v.body.strip():
        fail("Nhập tiêu đề và nội dung.")
    if v.audience not in ("all", "reader", "librarian", "manager"):
        fail("Nhóm nhận không hợp lệ.")
    with db() as c:
        recipients = rows(
            c,
            "SELECT id FROM users WHERE active=1 AND (?='all' OR role=?)",
            (v.audience, v.audience),
        )
        for recipient in recipients:
            notify(c, recipient["id"], v.title.strip(), v.body.strip())
        audit(c, u, "announcement", f"{v.audience}: {v.title}")
    return {"message": f"Đã gửi tới {len(recipients)} tài khoản."}


class ExperienceInput(BaseModel):
    dark: bool = False
    palette: str = "ocean"
    scale: float = Field(default=1, ge=0.85, le=1.3)
    background: str = Field(default="", max_length=600000)
    reduce_motion: bool = False


def validate_image(value):
    if not value:
        return
    if not value.startswith("data:image/jpeg;base64,"):
        fail("Chọn ảnh JPEG hợp lệ.")
    try:
        data = base64.b64decode(value.split(",", 1)[1], validate=True)
    except Exception:
        fail("Ảnh không hợp lệ.")
    if len(data) > 450000 or not data.startswith(bytes.fromhex("ffd8ff")):
        fail("Ảnh quá lớn hoặc không hợp lệ.")


@app.put("/me/experience")
def experience(v: ExperienceInput, u=Depends(current)):
    if v.palette not in ("ocean", "mist", "ivory"):
        fail("Màu nền không hợp lệ.")
    validate_image(v.background)
    with db() as c:
        c.execute(
            "UPDATE users SET preferences=? WHERE id=?",
            (json.dumps(v.model_dump()), u["id"]),
        )
    return {"message": "Đã lưu trải nghiệm."}


class AvatarInput(BaseModel):
    image: str = Field(max_length=600000)


@app.put("/me/avatar")
def avatar(v: AvatarInput, u=Depends(current)):
    validate_image(v.image)
    with db() as c:
        c.execute("UPDATE users SET avatar=? WHERE id=?", (v.image, u["id"]))
    return {"message": "Đã cập nhật ảnh đại diện."}


class ContentInput(BaseModel):
    text: str = Field(min_length=20, max_length=2000000)
    credit: str = Field(min_length=3, max_length=500)


@app.put("/books/{bid}/content")
def save_content(bid: int, v: ContentInput, u=Depends(staff)):
    with db() as c:
        get(c, "books", bid)
        c.execute(
            "INSERT INTO reading_content VALUES(?,?,?) ON CONFLICT(book_id) DO UPDATE SET text=excluded.text,credit=excluded.credit",
            (bid, v.text, v.credit),
        )
        audit(c, u, "reading_content", str(bid))
    return {"message": "Đã lưu nội dung đọc."}


@app.get("/books/{bid}/content")
def read_content(bid: int, u=Depends(current)):
    with db() as c:
        b = get(c, "books", bid)
        if not b["active"] and u["role"] == "reader":
            fail("Sách đã ngừng phục vụ.", 404)
        item = one(c, "SELECT * FROM reading_content WHERE book_id=?", (bid,))
        if not item:
            fail("Thư viện chưa có bản số được phép phát hành cho sách này.", 404)
        progress = one(
            c,
            "SELECT page FROM reading_progress WHERE user_id=? AND book_id=?",
            (u["id"], bid),
        )
        return {**item, "page": progress["page"] if progress else 0}


class ProgressInput(BaseModel):
    page: int = Field(ge=0, le=100000)


@app.put("/books/{bid}/progress")
def save_progress(bid: int, v: ProgressInput, u=Depends(current)):
    with db() as c:
        get(c, "books", bid)
        c.execute(
            "INSERT INTO reading_progress VALUES(?,?,?) ON CONFLICT(user_id,book_id) DO UPDATE SET page=excluded.page",
            (u["id"], bid, v.page),
        )
    return {"message": "Đã lưu vị trí đọc."}


@app.get("/me/report")
def personal_report(u=Depends(current)):
    with db() as c:
        borrowed = c.execute(
            "SELECT count(*) FROM loans WHERE user_id=? AND status='borrowed'",
            (u["id"],),
        ).fetchone()[0]
        returned = c.execute(
            "SELECT count(*) FROM loans WHERE user_id=? AND status='returned'",
            (u["id"],),
        ).fetchone()[0]
        overdue = c.execute(
            "SELECT count(*) FROM loans WHERE user_id=? AND status='borrowed' AND due_at<?",
            (u["id"], now()),
        ).fetchone()[0]
        return {
            "borrowed": borrowed,
            "returned": returned,
            "overdue": overdue,
            "monthly": monthly_series(
                rows(
                    c,
                    "SELECT substr(issued_at,1,7) month,count(*) count FROM loans WHERE user_id=? GROUP BY month ORDER BY month DESC LIMIT 6",
                    (u["id"],),
                )
            ),
        }


def monthly_series(items):
    if not items:
        return []
    today = datetime.now(timezone.utc)
    total = today.year * 12 + today.month - 1
    counts = {r["month"]: r["count"] for r in items}
    keys = [f"{n//12:04d}-{n%12+1:02d}" for n in range(total - 5, total + 1)]
    return [{"month": k, "count": counts.get(k, 0)} for k in keys]
