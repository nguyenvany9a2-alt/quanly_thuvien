import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class RequestsScreen extends StatefulWidget {
  final Api api;
  const RequestsScreen({super.key, required this.api});
  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String filter = 'all';
  @override
  Widget build(BuildContext c) => DataView(
    api: widget.api,
    path: '/requests',
    builder: (c, data, reload) {
      final list = (data as List)
          .where((r) => filter == 'all' || r['status'] == filter)
          .toList();
      return RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.api.isStaff ? 'Bàn tiếp nhận' : 'Yêu cầu của bạn',
              style: Theme.of(c).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Theo dõi từ lúc gửi yêu cầu đến khi nhận sách.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final f in [
                  'all',
                  'pending',
                  'approved',
                  'fulfilled',
                  'rejected',
                  'cancelled',
                  'expired',
                ])
                  ChoiceChip(
                    label: Text(f == 'all' ? 'Tất cả' : statusLabel(f)),
                    selected: filter == f,
                    onSelected: (_) => setState(() => filter = f),
                  ),
              ],
            ),
            if (widget.api.isStaff)
              TextButton.icon(
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => RenewalsScreen(api: widget.api),
                  ),
                ),
                icon: const Icon(Icons.update),
                label: const Text('Xử lý yêu cầu gia hạn'),
              ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Empty(
                'Chưa có yêu cầu',
                'Khám phá sách và chọn một cuốn bạn muốn đọc.',
              ),
            for (final r in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: CirculationPanel(
                  cover: r['cover'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '#${r['id']} · ${day(r['created_at'])}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (widget.api.isStaff)
                                  Text(
                                    '${r['name']} · ${r['email']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MotBadge(statusLabel(r['status'])),
                      if (r['pickup_until'] != null)
                        Text(
                          'Nhận trước: ${day(r['pickup_until'])} · ${r['code'] ?? ''}',
                        ),
                      if (r['note'] != '') Text(r['note']),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (widget.api.isStaff && r['status'] == 'pending')
                            _action(c, reload, r, 'approve', 'Duyệt giữ sách'),
                          if (widget.api.isStaff && r['status'] == 'approved')
                            _action(
                              c,
                              reload,
                              r,
                              'issue',
                              'Xác nhận giao sách',
                            ),
                          if (widget.api.isStaff &&
                              ['pending', 'approved'].contains(r['status']))
                            _action(c, reload, r, 'reject', 'Từ chối'),
                          if (!widget.api.isStaff &&
                              ['pending', 'approved'].contains(r['status']))
                            _action(c, reload, r, 'cancel', 'Hủy yêu cầu'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
  Widget _action(
    BuildContext c,
    VoidCallback reload,
    Map r,
    String action,
    String label,
  ) => ActionButton(
    label: label,
    icon: action == 'approve' || action == 'issue'
        ? Icons.check_rounded
        : Icons.close_rounded,
    secondary: action == 'reject' || action == 'cancel',
    action: () async {
      String note = '';
      if (action == 'reject') {
        final d = await editForm(c, 'Lý do từ chối', [
          const FieldSpec('note', 'Lý do', lines: 3),
        ]);
        if (d == null) return;
        note = d['note']!;
      } else if (!await confirm(c, '$label cho ${r['title']}?')) {
        return;
      }
      final v = await widget.api.call(
        '/requests/${r['id']}/action',
        method: 'POST',
        data: {'action': action, 'note': note},
      );
      if (c.mounted) message(c, v['message']);
      reload();
    },
  );
}

class LoansScreen extends StatefulWidget {
  final Api api;
  const LoansScreen({super.key, required this.api});
  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  String filter = 'borrowed', query = '';
  DateTime? selected;
  @override
  Widget build(BuildContext c) => DataView(
    api: widget.api,
    path: '/loans',
    builder: (c, data, reload) {
      final all = (data as List);
      final list = all
          .where(
            (l) =>
                (filter == 'all' ||
                    filter == 'overdue' && l['overdue'] == 1 ||
                    l['status'] == filter) &&
                ('${l['title']} ${l['name']} ${l['code']}'
                    .toLowerCase()
                    .contains(query.toLowerCase())) &&
                (selected == null ||
                    day(l['due_at']) == day(selected!.toIso8601String())),
          )
          .toList();
      return RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.api.isStaff ? 'Mượn và trả' : 'Sách của tôi',
              style: Theme.of(c).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Tên sách, độc giả, mã bản sách',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final f in [
                  'borrowed',
                  'overdue',
                  'returned',
                  'lost',
                  'all',
                ])
                  ChoiceChip(
                    label: Text(
                      f == 'all'
                          ? 'Tất cả'
                          : f == 'overdue'
                          ? 'Quá hạn'
                          : statusLabel(f),
                    ),
                    selected: filter == f,
                    onSelected: (_) => setState(() => filter = f),
                  ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: c,
                      initialDate: selected ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null && mounted) setState(() => selected = d);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    selected == null
                        ? 'Lọc theo hạn trả'
                        : 'Hạn trả ${day(selected!.toIso8601String())}',
                  ),
                ),
                if (selected != null)
                  IconButton(
                    tooltip: 'Xóa lọc ngày',
                    onPressed: () => setState(() => selected = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            if (list.isEmpty)
              const Empty(
                'Không có phiếu phù hợp',
                'Thử đổi bộ lọc hoặc kiểm tra yêu cầu đang chờ nhận.',
              ),
            for (final l in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: CirculationPanel(
                  cover: l['cover'],
                  color: l['overdue'] == 1
                      ? const Color(0xFFFFF0E6)
                      : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${l['code']} · Phiếu #${l['id']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (widget.api.isStaff) Text(l['name']),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MotBadge(
                        l['overdue'] == 1
                            ? 'Quá hạn'
                            : statusLabel(l['status']),
                        warning: l['overdue'] == 1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ngày mượn: ${day(l['issued_at'])}\nHạn trả: ${day(l['due_at'])}',
                      ),
                      if (l['returned_at'] != null)
                        Text('Ngày trả: ${day(l['returned_at'])}'),
                      if (l['renewal_pending'] == 1)
                        const Text(
                          'Đang chờ duyệt gia hạn',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      if (l['status'] == 'borrowed') ...[
                        const SizedBox(height: 12),
                        if (widget.api.isStaff)
                          ActionButton(
                            label: 'Nhận trả sách',
                            icon: Icons.assignment_turned_in_outlined,
                            action: () async {
                              final d = await editForm(
                                c,
                                'Tình trạng khi nhận trả',
                                [
                                  const FieldSpec(
                                    'condition',
                                    'Tình trạng',
                                    value: 'available',
                                    choices: ['available', 'damaged', 'lost'],
                                  ),
                                  const FieldSpec(
                                    'note',
                                    'Ghi chú',
                                    required: false,
                                    lines: 2,
                                  ),
                                ],
                              );
                              if (d == null) return;
                              final r = await widget.api.call(
                                '/loans/${l['id']}/return',
                                method: 'POST',
                                data: d,
                              );
                              if (c.mounted) message(c, r['message']);
                              reload();
                            },
                          )
                        else if (l['overdue'] != 1 && l['renewal_pending'] != 1)
                          ActionButton(
                            label: 'Yêu cầu gia hạn',
                            icon: Icons.update_rounded,
                            action: () async {
                              final r = await widget.api.call(
                                '/loans/${l['id']}/renew',
                                method: 'POST',
                              );
                              if (c.mounted) message(c, r['message']);
                              reload();
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class RenewalsScreen extends StatelessWidget {
  final Api api;
  const RenewalsScreen({super.key, required this.api});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Yêu cầu gia hạn')),
    body: DataView(
      api: api,
      path: '/renewals',
      builder: (c, data, reload) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if ((data as List).isEmpty)
            const Empty(
              'Chưa có yêu cầu',
              'Các yêu cầu gia hạn sẽ hiện tại đây.',
            ),
          for (final r in data)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['title'], style: Theme.of(c).textTheme.titleMedium),
                    Text('${r['name']} · ${day(r['created_at'])}'),
                    Text(
                      r['status'] == 'approved'
                          ? 'Đã gia hạn'
                          : statusLabel(r['status']),
                    ),
                    if (r['status'] == 'pending')
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final a in ['approve', 'reject'])
                            ActionButton(
                              label: a == 'approve'
                                  ? 'Duyệt gia hạn'
                                  : 'Từ chối',
                              action: () async {
                                await api.call(
                                  '/renewals/${r['id']}/action',
                                  method: 'POST',
                                  data: {'action': a},
                                );
                                reload();
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
