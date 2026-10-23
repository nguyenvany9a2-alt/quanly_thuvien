import 'dart:async';

import 'package:flutter/material.dart';

import 'reader.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class Catalog extends StatefulWidget {
  final Api api;
  final bool favorites;
  const Catalog({super.key, required this.api, this.favorites = false});
  @override
  State<Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<Catalog> {
  String query = '', category = 'Tất cả';
  bool available = false;
  @override
  Widget build(BuildContext c) => DataView(
    api: widget.api,
    path: '/books',
    builder: (c, data, reload) {
      final books = (data as List).cast<Map<String, dynamic>>();
      final cats = ['Tất cả', ...books.map((b) => '${b['category']}').toSet()];
      final list = books
          .where(
            (b) =>
                (!widget.favorites || b['favorite'] == 1) &&
                ('${b['title']} ${b['author']} ${b['isbn']}'
                    .toLowerCase()
                    .contains(query.toLowerCase())) &&
                (category == 'Tất cả' || b['category'] == category) &&
                (!available || b['available'] > 0),
          )
          .toList();
      return RefreshIndicator(
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.favorites
                        ? 'Kệ sách yêu thích'
                        : 'Những trang sách,\nnhững chân trời.',
                    style: Theme.of(c).textTheme.headlineMedium,
                  ),
                ),
                if (widget.api.isStaff)
                  IconButton.filled(
                    tooltip: 'Thêm đầu sách',
                    onPressed: () async {
                      await editBook(c, widget.api);
                      reload();
                    },
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (!widget.favorites) ...[
              BookShelf(api: widget.api, books: books),
              const SizedBox(height: 24),
            ],
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Tên sách, tác giả hoặc ISBN',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in cats)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: category == cat,
                        onSelected: (_) => setState(() => category = cat),
                      ),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${list.length} đầu sách'),
              subtitle: const Text('Chỉ hiện sách còn bản để mượn'),
              value: available,
              onChanged: (v) => setState(() => available = v),
            ),
            if (list.isEmpty)
              const Empty('Chưa tìm thấy sách', 'Thử đổi từ khóa hoặc bộ lọc.')
            else
              LayoutBuilder(
                builder: (c, constraints) {
                  final cols = constraints.maxWidth > 750
                      ? 4
                      : constraints.maxWidth > 500
                      ? 3
                      : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisExtent:
                          360 *
                          MediaQuery.textScalerOf(c).scale(1).clamp(1.0, 1.3),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: list.length,
                    itemBuilder: (c, i) {
                      final b = list[i];
                      return Material(
                        color: Theme.of(c).colorScheme.surface
                            .withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              c,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookDetail(api: widget.api, book: b),
                              ),
                            );
                            reload();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Hero(
                                      tag: 'cover-${b['id']}',
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: cream,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Cover(b['cover'], height: 185),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  b['title'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    fontFamily: displayFont,
                                  ),
                                ),
                                Text(
                                  b['author'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  b['rating'] == null
                                      ? 'Chưa có đánh giá'
                                      : '★ ${b['rating']} · ${b['review_count']} đánh giá',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8B713D),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['active'] == 0
                                      ? 'Ngừng phục vụ'
                                      : '${b['available']} bản sẵn sàng',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> editBook(
  BuildContext c,
  Api api, {
  Map<String, dynamic>? book,
}) async {
  final b = book ?? <String, dynamic>{};
  final d = await editForm(
    c,
    b.isEmpty ? 'Thêm đầu sách' : 'Chỉnh sửa đầu sách',
    [
      FieldSpec('title', 'Tên sách', value: b['title'] ?? ''),
      FieldSpec('author', 'Tác giả', value: b['author'] ?? ''),
      FieldSpec(
        'category',
        'Thể loại',
        value: b['category'] ?? 'Văn học Việt Nam',
      ),
      FieldSpec(
        'description',
        'Giới thiệu',
        value: b['description'] ?? '',
        required: false,
        lines: 3,
      ),
      FieldSpec(
        'cover',
        'Đường dẫn ảnh HTTPS hoặc asset',
        value: b['cover'] ?? '',
        required: false,
      ),
      FieldSpec(
        'source',
        'Nguồn tham khảo HTTPS',
        value: b['source'] ?? '',
        required: false,
      ),
      FieldSpec('isbn', 'ISBN', value: b['isbn'] ?? '', required: false),
      FieldSpec(
        'publisher',
        'Nhà xuất bản',
        value: b['publisher'] ?? '',
        required: false,
      ),
      FieldSpec(
        'year',
        'Năm xuất bản',
        value: b['year']?.toString() ?? '',
        required: false,
      ),
      FieldSpec(
        'active',
        'Phục vụ (1) / Ngừng (0)',
        value: '${b['active'] ?? 1}',
        choices: const ['1', '0'],
      ),
    ],
  );
  if (d == null) return;
  try {
    final year = d['year']!.isEmpty ? null : int.tryParse(d['year']!);
    if (d['year']!.isNotEmpty && year == null) {
      throw ApiError('Năm xuất bản phải là số.');
    }
    await api.call(
      b.isEmpty ? '/books' : '/books/${b['id']}',
      method: b.isEmpty ? 'POST' : 'PUT',
      data: {...d, 'year': year, 'active': d['active'] == '1'},
    );
    if (c.mounted) message(c, 'Đã lưu đầu sách.');
  } catch (e) {
    if (c.mounted) message(c, e);
  }
}

class BookDetail extends StatefulWidget {
  final Api api;
  final Map<String, dynamic> book;
  const BookDetail({super.key, required this.api, required this.book});
  @override
  State<BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends State<BookDetail> {
  late Map<String, dynamic> b = Map.from(widget.book);
  Future<void> refresh() async {
    final list = await widget.api.call('/books') as List;
    final found = list.where((e) => e['id'] == b['id']);
    if (mounted && found.isNotEmpty) setState(() => b = Map.from(found.first));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Chi tiết sách'),
      actions: [
        IconButton(
          tooltip: 'Lưu yêu thích',
          onPressed: () async {
            try {
              await widget.api.call(
                '/books/${b['id']}/favorite',
                method: 'POST',
              );
              await refresh();
            } catch (e) {
              if (c.mounted) message(c, e);
            }
          },
          icon: Icon(
            b['favorite'] == 1 ? Icons.favorite : Icons.favorite_border,
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Panel(
          color: sage,
          child: Center(
            child: Hero(
              tag: 'cover-${b['id']}',
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3319364A),
                      blurRadius: 28,
                      offset: Offset(10, 15),
                    ),
                  ],
                ),
                child: Cover(b['cover'], height: 250),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const EditorialLabel('Một thế giới trên trang giấy'),
        const SizedBox(height: 10),
        Text(b['title'], style: Theme.of(c).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(b['author'], style: const TextStyle(fontSize: 17)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MotBadge(b['category']),
            MotBadge('${b['available']}/${b['total']} bản sẵn sàng'),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        Text('Về cuốn sách', style: Theme.of(c).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(b['description']),
        const SizedBox(height: 16),
        if ('${b['isbn']}'.isNotEmpty) Text('ISBN: ${b['isbn']}'),
        if ('${b['publisher']}'.isNotEmpty)
          Text('Nhà xuất bản: ${b['publisher']}'),
        if (b['year'] != null) Text('Năm xuất bản: ${b['year']}'),
        const SizedBox(height: 24),
        if (!widget.api.isStaff)
          ActionButton(
            label: 'Gửi yêu cầu mượn',
            icon: Icons.auto_stories,
            action: () async {
              if (!await confirm(
                c,
                'Gửi yêu cầu mượn ${b['title']}? Thủ thư sẽ duyệt và giữ một bản trước khi bạn đến nhận.',
              )) {
                return;
              }
              final r = await widget.api.call(
                '/requests/${b['id']}',
                method: 'POST',
              );
              if (c.mounted) message(c, r['message']);
              await refresh();
            },
          ),
        if (widget.api.isStaff) ...[
          ActionButton(
            label: 'Chỉnh sửa thông tin',
            action: () async {
              await editBook(c, widget.api, book: b);
              await refresh();
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                c,
                MaterialPageRoute(
                  builder: (_) => CopiesScreen(api: widget.api, book: b),
                ),
              );
              await refresh();
            },
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Quản lý từng bản sách'),
          ),
        ],
        const SizedBox(height: 12),
        ActionButton(
          label: b['readable'] == 1 ? 'Đọc sách ngay' : 'Bản số chưa có',
          icon: Icons.chrome_reader_mode_outlined,
          action: () async {
            if (b['readable'] != 1) {
              message(
                c,
                'Thư viện chưa có bản số được phép phát hành. Bạn vẫn có thể mượn sách giấy.',
              );
              return;
            }
            await Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => ReaderScreen(api: widget.api, book: b),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.star_outline),
          label: Text(
            b['rating'] == null
                ? 'Đánh giá sách'
                : '${b['rating']} / 5 · ${b['review_count']} đánh giá',
          ),
          onPressed: () async {
            await Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => ReviewsScreen(api: widget.api, book: b),
              ),
            );
            await refresh();
          },
        ),
        if (widget.api.isStaff) ...[
          const SizedBox(height: 12),
          ActionButton(
            label: 'Biên tập nội dung đọc',
            secondary: true,
            action: () async {
              await editReadingContent(c, widget.api, b);
              await refresh();
            },
          ),
        ],
      ],
    ),
  );
}

class CopiesScreen extends StatelessWidget {
  final Api api;
  final Map<String, dynamic> book;
  const CopiesScreen({super.key, required this.api, required this.book});
  Future<void> edit(BuildContext c, VoidCallback reload, {Map? copy}) async {
    final d = await editForm(
      c,
      copy == null ? 'Thêm bản sách' : 'Cập nhật bản sách',
      [
        FieldSpec('code', 'Mã cuốn sách', value: copy?['code'] ?? ''),
        FieldSpec('shelf', 'Kệ sách', value: copy?['shelf'] ?? 'A1'),
        FieldSpec(
          'status',
          'Tình trạng',
          value: copy?['status'] ?? 'available',
          choices: const ['available', 'damaged', 'lost', 'withdrawn'],
        ),
      ],
    );
    if (d == null) return;
    try {
      await api.call(
        copy == null ? '/books/${book['id']}/copies' : '/copies/${copy['id']}',
        method: copy == null ? 'POST' : 'PUT',
        data: d,
      );
      reload();
    } catch (e) {
      if (c.mounted) message(c, e);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(book['title'])),
    body: DataView(
      api: api,
      path: '/books/${book['id']}/copies',
      builder: (c, data, reload) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ActionButton(
            label: 'Thêm bản sách',
            action: () async => edit(c, reload),
          ),
          const SizedBox(height: 20),
          for (final cp in data)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(cp['code']),
                  subtitle: Text(
                    'Kệ ${cp['shelf']} · ${statusLabel(cp['status'])}',
                  ),
                  trailing: ['reserved', 'on_loan'].contains(cp['status'])
                      ? const Icon(Icons.lock_outline)
                      : IconButton(
                          tooltip: 'Chỉnh sửa',
                          onPressed: () => edit(c, reload, copy: cp),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class BookShelf extends StatelessWidget {
  final Api api;
  final VoidCallback? onExplore;
  final List? books;
  const BookShelf({super.key, required this.api, this.onExplore, this.books});
  @override
  Widget build(BuildContext c) => books == null
      ? DataView(
          api: api,
          path: '/books',
          builder: (c, d, reload) => _shelf(c, d),
        )
      : _shelf(c, books!);
  Widget _shelf(BuildContext c, List list) => Container(
    decoration: BoxDecoration(
      color: forest.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: forest.withValues(alpha: .2),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TUYỂN SÁCH MỌT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Color(0xFFBCD9E7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Một khoảng lặng để đọc.',
                        style: Theme.of(c).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontFamily: accentFont,
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onExplore != null)
                  IconButton(
                    tooltip: 'Đến Khám phá',
                    onPressed: onExplore,
                    icon: const Icon(
                      Icons.north_east,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const Text(
              'Kệ sách đang được cập nhật.',
              style: TextStyle(color: Colors.white),
            )
          else
            AutoBookRail(books: list, api: api),
        ],
      ),
    ),
  );
}

String searchKey(String value) {
  const groups = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ',
  ];
  var result = value.toLowerCase();
  for (var i = 0; i < groups.length; i++) {
    for (final rune in groups[i].runes) {
      result = result.replaceAll(String.fromCharCode(rune), 'aeiouyd'[i]);
    }
  }
  return result.trim();
}

class HomeBookSearch extends StatefulWidget {
  final Api api;
  const HomeBookSearch({super.key, required this.api});
  @override
  State<HomeBookSearch> createState() => _HomeBookSearchState();
}

class _HomeBookSearchState extends State<HomeBookSearch> {
  final controller = TextEditingController();
  bool available = false, readable = false;
  String category = 'Tất cả';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DataView(
    api: widget.api,
    path: '/books',
    builder: (context, data, reload) {
      final books = (data as List).cast<Map<String, dynamic>>();
      final categories = [
        'Tất cả',
        ...books.map((b) => '${b['category']}').toSet(),
      ];
      final active =
          controller.text.trim().isNotEmpty ||
          available ||
          readable ||
          category != 'Tất cả';
      final results = books
          .where(
            (b) =>
                searchKey('${b['title']} ${b['author']} ${b['isbn'] ?? ''}')
                    .contains(searchKey(controller.text)) &&
                (!available || (b['available'] as num? ?? 0) > 0) &&
                (!readable || b['readable'] == 1 || b['readable'] == true) &&
                (category == 'Tất cả' || b['category'] == category),
          )
          .toList();
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm tên sách, tác giả, ISBN…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(controller.clear),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('Còn sách'),
                  selected: available,
                  onSelected: (v) => setState(() => available = v),
                ),
                FilterChip(
                  label: const Text('Đọc trong app'),
                  selected: readable,
                  onSelected: (v) => setState(() => readable = v),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Lọc thể loại',
                  initialValue: category,
                  onSelected: (v) => setState(() => category = v),
                  itemBuilder: (_) => categories
                      .map((v) => PopupMenuItem(value: v, child: Text(v)))
                      .toList(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('$category ▾'),
                  ),
                ),
              ],
            ),
            if (active) ...[
              const Divider(),
              Text(
                '${results.length} kết quả',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Chưa tìm thấy sách. Thử tên tác giả hoặc bỏ bớt bộ lọc.',
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final b = results[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      leading: Cover(b['cover'], width: 36, height: 54),
                      title: Text(b['title']),
                      subtitle: Text(b['author']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetail(api: widget.api, book: b),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class AutoBookRail extends StatefulWidget {
  final List books;
  final Api api;
  const AutoBookRail({super.key, required this.books, required this.api});
  @override
  State<AutoBookRail> createState() => _AutoBookRailState();
}

class _AutoBookRailState extends State<AutoBookRail>
    with WidgetsBindingObserver {
  final scroll = ScrollController();
  Timer? timer;
  bool paused = false, touching = false, foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||
          paused ||
          touching ||
          !foreground ||
          !scroll.hasClients ||
          MediaQuery.disableAnimationsOf(context) ||
          !TickerMode.valuesOf(context).enabled ||
          ModalRoute.of(context)?.isCurrent == false ||
          scroll.position.isScrollingNotifier.value)
        return;
      final end = scroll.position.maxScrollExtent;
      if (end <= 0) return;
      final next = scroll.offset >= end - 1
          ? 0.0
          : (scroll.offset + 141).clamp(0.0, end);
      scroll.animateTo(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 190,
        child: Listener(
          onPointerDown: (_) => touching = true,
          onPointerUp: (_) => touching = false,
          onPointerCancel: (_) => touching = false,
          child: ListView.separated(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            itemCount: widget.books.length,
            separatorBuilder: (_, i) => const SizedBox(width: 15),
            itemBuilder: (context, i) {
              final b = Map<String, dynamic>.from(widget.books[i]);
              return Semantics(
                button: true,
                label: 'Mở sách ${b['title']}',
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetail(api: widget.api, book: b),
                    ),
                  ),
                  child: SizedBox(
                    width: 126,
                    child: Center(
                      child: Cover(b['cover'], width: 120, height: 180),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () => setState(() => paused = !paused),
          icon: Icon(
            paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            size: 18,
          ),
          label: Text(paused ? 'Tiếp tục trượt' : 'Tạm dừng'),
        ),
      ),
    ],
  );
}
