import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../widgets/insights.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class UsersScreen extends StatelessWidget {
  final Api api;
  const UsersScreen({super.key, required this.api});
  Future<void> edit(BuildContext c, Map u, VoidCallback reload) async {
    final d = await editForm(c, 'Cập nhật tài khoản', [
      FieldSpec('name', 'Họ tên', value: u['name']),
      FieldSpec('phone', 'Điện thoại', value: u['phone'], required: false),
      FieldSpec(
        'card_expires',
        'Thẻ hết hạn YYYY-MM-DD',
        value: u['card_expires'],
      ),
      FieldSpec(
        'active',
        'Hoạt động (1) / Khóa (0)',
        value: '${u['active']}',
        choices: const ['1', '0'],
      ),
      if (api.isManager)
        FieldSpec(
          'role',
          'Vai trò',
          value: u['role'],
          choices: const ['reader', 'librarian', 'manager'],
        ),
    ]);
    if (d == null) return;
    try {
      await api.call(
        '/users/${u['id']}',
        method: 'PUT',
        data: {
          ...d,
          'role': d['role'] ?? u['role'],
          'active': d['active'] == '1',
        },
      );
      reload();
    } catch (e) {
      if (c.mounted) message(c, e);
    }
  }

  Future<void> add(BuildContext c, VoidCallback reload) async {
    final d = await editForm(c, 'Tạo tài khoản', [
      const FieldSpec('name', 'Họ tên'),
      const FieldSpec('email', 'Email'),
      const FieldSpec('password', 'Mật khẩu từ 8 ký tự', secret: true),
      const FieldSpec(
        'role',
        'Vai trò',
        value: 'librarian',
        choices: ['reader', 'librarian', 'manager'],
      ),
    ]);
    if (d == null) return;
    final r = await api.call('/users', method: 'POST', data: d);
    reload();
    if (c.mounted) {
      await showDialog(
        context: c,
        builder: (c) => AlertDialog(
          title: const Text('Đã tạo tài khoản'),
          content: SelectableText(
            '${r['message']}\n\nMã khôi phục: ${r['recovery_code']}',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: r['recovery_code'])),
              child: const Text('Sao chép mã'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        api.isManager ? 'Tài khoản và phân quyền' : 'Quản lý độc giả',
      ),
    ),
    body: DataView(
      api: api,
      path: '/users',
      builder: (c, data, reload) => _UserList(
        data: List<Map<String, dynamic>>.from(data),
        onEdit: (u) => edit(c, u, reload),
        onAdd: api.isManager ? () => add(c, reload) : null,
      ),
    ),
  );
}

class _UserList extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final Function(Map) onEdit;
  final Future<void> Function()? onAdd;
  const _UserList({required this.data, required this.onEdit, this.onAdd});
  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  String query = '';
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      if (widget.onAdd != null) ...[
        ActionButton(label: 'Tạo tài khoản', action: widget.onAdd!),
        const SizedBox(height: 16),
      ],
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(
          hintText: 'Tìm tên hoặc email',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 16),
      for (final u in widget.data.where(
        (u) => '${u['name']} ${u['email']}'.toLowerCase().contains(
          query.toLowerCase(),
        ),
      ))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: sage,
                child: Text(u['name'].toString().substring(0, 1)),
              ),
              title: Text(u['name']),
              subtitle: Text(
                '${u['email']}\n${roleLabel(u['role'])} · ${u['active'] == 1 ? 'Hoạt động' : 'Đã khóa'}\nHạn thẻ: ${u['card_expires']}',
              ),
              trailing: IconButton(
                tooltip: 'Sửa tài khoản',
                onPressed: () => widget.onEdit(u),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
          ),
        ),
    ],
  );
}

class PoliciesScreen extends StatelessWidget {
  final Api api;
  const PoliciesScreen({super.key, required this.api});
  static const labels = {
    'max_books': 'Số sách mượn và yêu cầu tối đa',
    'loan_days': 'Số ngày mượn',
    'hold_days': 'Số ngày giữ sách',
    'renew_days': 'Số ngày thêm khi gia hạn',
    'max_renewals': 'Số lần gia hạn tối đa',
  };
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Quy định thư viện')),
    body: DataView(
      api: api,
      path: '/policies',
      builder: (c, data, reload) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Hãy giữ gìn sách và trả đúng hẹn để người tiếp theo cũng có cơ hội đọc.',
          ),
          const SizedBox(height: 20),
          for (final k in labels.keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Row(
                  children: [
                    Expanded(child: Text(labels[k]!)),
                    Text('${data[k]}', style: Theme.of(c).textTheme.titleLarge),
                  ],
                ),
              ),
            ),
          const Text(
            'Ngày đến hạn của phiếu đã giao được giữ nguyên khi thay đổi chính sách.',
          ),
          const SizedBox(height: 20),
          if (api.isManager)
            ActionButton(
              label: 'Điều chỉnh chính sách',
              action: () async {
                final d = await editForm(c, 'Chính sách mượn sách', [
                  for (final k in labels.keys)
                    FieldSpec(k, labels[k]!, value: '${data[k]}'),
                ]);
                if (d == null) return;
                final v = <String, dynamic>{};
                for (final k in d.keys) {
                  final n = int.tryParse(d[k]!);
                  if (n == null) throw ApiError('Vui lòng nhập số nguyên.');
                  v[k] = n;
                }
                await api.call('/policies', method: 'PUT', data: v);
                reload();
              },
            ),
        ],
      ),
    ),
  );
}

class ReportsScreen extends StatelessWidget {
  final Api api;
  const ReportsScreen({super.key, required this.api});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Báo cáo thư viện')),
    body: DataView(
      api: api,
      path: '/reports',
      builder: (c, d, reload) => RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InsightPanel(data: d, staff: true),
            const SizedBox(height: 20),
            MonthlyChart(months: d['monthly']),
            const SizedBox(height: 20),
            MonthlyChart(months: d['monthly'], line: true),
            const SizedBox(height: 24),
            const Text(
              'Tổng quan hiện tại',
              style: TextStyle(
                fontFamily: 'MotSerif',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28,
                  columns: const [
                    DataColumn(label: Text('Chỉ số')),
                    DataColumn(label: Text('Số lượng'), numeric: true),
                  ],
                  rows: [
                    for (final e in {
                      'books': 'Đầu sách',
                      'copies': 'Bản sách',
                      'available': 'Sẵn sàng',
                      'borrowed': 'Đang mượn',
                      'overdue': 'Quá hạn',
                      'readers': 'Độc giả',
                      'pending': 'Chờ duyệt',
                    }.entries)
                      DataRow(
                        cells: [
                          DataCell(Text(e.value)),
                          DataCell(Text('${d[e.key]}')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Sách được mượn nhiều',
              style: Theme.of(c).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if ((d['popular'] as List).isEmpty)
              const Text('Chưa có lượt giao sách để thống kê.'),
            for (final b in d['popular'])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${b['title']} · ${b['count']} lượt'),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: b['count'] / (d['popular'][0]['count'] as num),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: sage,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Lượt giao sách theo tháng',
              style: Theme.of(c).textTheme.titleLarge,
            ),
            for (final b in d['monthly'])
              ListTile(
                title: Text(b['month']),
                trailing: Text('${b['count']} lượt'),
              ),
            const Text(
              'Mỗi lượt tương ứng một bản sách thực tế được giao. Thống kê từ dữ liệu thư viện, không dùng số liệu minh họa cố định.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuditScreen extends StatelessWidget {
  final Api api;
  const AuditScreen({super.key, required this.api});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Nhật ký hoạt động')),
    body: DataView(
      api: api,
      path: '/audit',
      builder: (c, data, reload) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('100 thao tác quản trị gần nhất'),
          for (final r in data)
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('${r['action']} · ${r['detail']}'),
              subtitle: Text('${r['name']} · ${day(r['created_at'])}'),
            ),
        ],
      ),
    ),
  );
}
