import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/experience.dart';
import '../widgets/insights.dart';
import 'experience.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'catalog.dart';
import 'circulation.dart';
import 'admin.dart';

class HomeShell extends StatefulWidget {
  final Api api;
  const HomeShell({super.key, required this.api});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  @override
  Widget build(BuildContext c) {
    final api = widget.api;
    final pages = [
      Dashboard(api: api, onTab: (i) => setState(() => tab = i)),
      Catalog(api: api),
      RequestsScreen(api: api),
      LoansScreen(api: api),
      ProfileScreen(api: api),
    ];
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => setState(() => tab = 0),
          borderRadius: BorderRadius.circular(12),
          child: const Brand(size: 25),
        ),
        titleSpacing: 24,
        toolbarHeight: 70,
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => NotificationsScreen(api: api)),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Quy định thư viện',
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => PoliciesScreen(api: api)),
            ),
            icon: const Icon(Icons.error_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(c)
                ? Duration.zero
                : const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, .025),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
          ),
        ),
      ),
      bottomNavigationBar: GlassDock(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.0,
          child: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_stories_outlined),
                label: 'Khám phá',
              ),
              NavigationDestination(
                icon: Icon(Icons.inbox_outlined),
                label: 'Yêu cầu',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                label: 'Mượn trả',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final Api api;
  final ValueChanged<int> onTab;
  const Dashboard({super.key, required this.api, required this.onTab});
  @override
  Widget build(BuildContext c) => DataView(
    api: api,
    path: api.isStaff ? '/reports' : '/me/report',
    builder: (c, d, reload) => RefreshIndicator(
      onRefresh: () async => reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
        children: [
          Row(
            children: [
              UserAvatar(api.user!),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      api.user?['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      roleLabel(api.user?['role']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(c).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Chạm vào trang sách.\nMở một chân trời.',
            style: Theme.of(c).textTheme.headlineLarge,
          ),
          const SizedBox(height: 20),
          HomeBookSearch(api: api),
          const SizedBox(height: 22),
          BookShelf(api: api, onExplore: () => onTab(1)),
          const SizedBox(height: 22),
          InsightPanel(
            data: d,
            staff: api.isStaff,
            onOpen: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => api.isStaff
                    ? ReportsScreen(api: api)
                    : PersonalReport(api: api),
              ),
            ),
          ),
          const SizedBox(height: 20),
          MonthlyChart(months: d['monthly'] ?? []),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onTab(2),
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('Yêu cầu'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onTab(3),
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Mượn trả'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class NotificationsScreen extends StatefulWidget {
  final Api api;
  const NotificationsScreen({super.key, required this.api});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool unreadOnly = false;
  Api get api => widget.api;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Hộp thư MỌT')),
    body: DataView(
      api: api,
      path: '/notifications',
      builder: (c, data, reload) {
        final all = data as List;
        final reminders = all.where((r) => (r['id'] as int) < 0).toList();
        final mail = all.where((r) => (r['id'] as int) > 0).toList();
        final unread = mail.where((r) => r['is_read'] != 1).length;
        final visible = mail
            .where((r) => !unreadOnly || r['is_read'] != 1)
            .toList();
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Panel(
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined, size: 34),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unread thông báo chưa đọc',
                            style: Theme.of(c).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          const Text('Lịch hẹn với những trang sách của bạn.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (api.isManager) ...[
                ActionButton(
                  label: 'Tạo thông báo',
                  icon: Icons.campaign_outlined,
                  action: () async {
                    final form = await editForm(c, 'Thông báo mới', [
                      const FieldSpec('title', 'Tiêu đề'),
                      const FieldSpec('body', 'Nội dung', lines: 4),
                      const FieldSpec(
                        'audience',
                        'Nhóm nhận',
                        value: 'all',
                        choices: ['all', 'reader', 'librarian', 'manager'],
                      ),
                    ]);
                    if (form == null || !c.mounted) return;
                    if (!await confirm(c, 'Gửi thông báo đến nhóm đã chọn?')) {
                      return;
                    }
                    final result = await api.call(
                      '/announcements',
                      method: 'POST',
                      data: form,
                    );
                    if (c.mounted) message(c, result['message']);
                    reload();
                  },
                ),
                const SizedBox(height: 14),
              ],

              if (unread > 0)
                ActionButton(
                  label: 'Đọc tất cả thông báo',
                  secondary: true,
                  icon: Icons.done_all,
                  action: () async {
                    await api.call('/notifications/read', method: 'POST');
                    reload();
                  },
                ),
              if (reminders.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'NHẮC HẠN TRẢ',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhắc hạn tự cập nhật khi sách được trả hoặc được gia hạn.',
                ),
                const SizedBox(height: 10),
                for (final r in reminders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Panel(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: Text(r['title']),
                        subtitle: Text(r['body']),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Sách đang mượn'),
                              ),
                              body: LoansScreen(api: api),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: !unreadOnly,
                    onSelected: (_) => setState(() => unreadOnly = false),
                  ),
                  ChoiceChip(
                    label: Text('Chưa đọc ($unread)'),
                    selected: unreadOnly,
                    onSelected: (_) => setState(() => unreadOnly = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Empty(
                  'Bạn đã cập nhật mọi thứ',
                  'Các thông báo mới sẽ xuất hiện tại đây.',
                ),
              for (final r in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Panel(
                    color: r['is_read'] == 1 ? Colors.white : sage,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              r['is_read'] == 1
                                  ? Icons.drafts_outlined
                                  : Icons.mark_email_unread_outlined,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r['title'],
                                style: Theme.of(c).textTheme.titleMedium,
                              ),
                            ),
                            if (r['is_read'] != 1) const MotBadge('Mới'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(r['body']),
                        const SizedBox(height: 12),
                        Text(
                          day(r['created_at']),
                          style: Theme.of(c).textTheme.bodySmall,
                        ),
                        if (r['is_read'] != 1)
                          ActionButton(
                            label: 'Đánh dấu đã đọc',
                            secondary: true,
                            icon: Icons.check,
                            action: () async {
                              await api.call(
                                '/notifications/${r['id']}/read',
                                method: 'POST',
                              );
                              reload();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  final Api api;
  const ProfileScreen({super.key, required this.api});
  @override
  Widget build(BuildContext c) {
    final u = api.user!;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const EditorialLabel('Không gian cá nhân'),
        const SizedBox(height: 12),
        Panel(
          color: const Color(0xFFEAF0EF),
          child: Column(
            children: [
              UserAvatar(u, radius: 38),
              const SizedBox(height: 12),
              Text(u['name'], style: Theme.of(c).textTheme.titleLarge),
              Text(u['email']),
              const SizedBox(height: 8),
              MotBadge(roleLabel(u['role'])),
              const SizedBox(height: 12),
              Text(
                'Mã bạn đọc: MOT-${u['id'].toString().padLeft(5, '0')}\nThẻ hết hạn: ${u['card_expires']}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _tile(
          c,
          Icons.palette_outlined,
          'Điều chỉnh trải nghiệm',
          () => _open(c, ExperienceScreen(api: api)),
        ),
        _tile(
          c,
          Icons.person_outline,
          'Chỉnh sửa hồ sơ',
          () => _open(c, ProfileEditor(api: api)),
        ),
        _tile(c, Icons.lock_outline, 'Đổi mật khẩu', () async {
          final d = await editForm(c, 'Đổi mật khẩu', [
            const FieldSpec('old_password', 'Mật khẩu hiện tại', secret: true),
            const FieldSpec(
              'password',
              'Mật khẩu mới từ 8 ký tự',
              secret: true,
            ),
          ]);
          if (d != null) {
            await api.call('/auth/password', method: 'POST', data: d);
            await api.logout();
          }
        }),
        _tile(
          c,
          Icons.rule,
          'Quy định thư viện',
          () => _open(c, PoliciesScreen(api: api)),
        ),
        if (!api.isStaff) ...[
          _tile(
            c,
            Icons.favorite_border,
            'Sách yêu thích',
            () => _open(
              c,
              Scaffold(
                appBar: AppBar(title: const Text('Sách yêu thích')),
                body: Catalog(api: api, favorites: true),
              ),
            ),
          ),
          _tile(
            c,
            Icons.insights,
            'Báo cáo cá nhân',
            () => _open(c, PersonalReport(api: api)),
          ),
        ],
        if (api.isStaff) ...[
          _tile(
            c,
            Icons.people_outline,
            api.isManager ? 'Tài khoản và phân quyền' : 'Quản lý độc giả',
            () => _open(c, UsersScreen(api: api)),
          ),
          _tile(
            c,
            Icons.update,
            'Duyệt gia hạn',
            () => _open(c, RenewalsScreen(api: api)),
          ),
          _tile(
            c,
            Icons.bar_chart,
            'Báo cáo thư viện',
            () => _open(c, ReportsScreen(api: api)),
          ),
        ],
        if (api.isManager)
          _tile(
            c,
            Icons.history,
            'Nhật ký hoạt động',
            () => _open(c, AuditScreen(api: api)),
          ),
        const SizedBox(height: 22),
        ActionButton(
          label: 'Đăng xuất',
          action: () async {
            if (await confirm(c, 'Bạn muốn đăng xuất khỏi MỌT?')) {
              await api.logout();
            }
          },
        ),
        const SizedBox(height: 24),
        const Center(child: Brand(size: 23)),
        const SizedBox(height: 10),
        const Text(
          'MỌT · Mỗi cuốn sách là một cuộc gặp.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext c, Widget w) async {
    await Navigator.push(c, MaterialPageRoute(builder: (_) => w));
  }

  Widget _tile(
    BuildContext c,
    IconData icon,
    String label,
    Future<void> Function() action,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: Theme.of(c).colorScheme.primary),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      try {
        await action();
      } catch (e) {
        if (c.mounted) message(c, e);
      }
    },
  );
}
