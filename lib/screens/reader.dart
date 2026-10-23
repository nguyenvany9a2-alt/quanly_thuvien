import 'package:flutter/material.dart';

import '../core/api.dart';
import '../widgets/common.dart';

class ReaderScreen extends StatelessWidget {
  final Api api;
  final Map book;
  const ReaderScreen({super.key, required this.api, required this.book});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(book['title'])),
    body: DataView(
      api: api,
      path: '/books/${book['id']}/content',
      builder: (c, d, reload) => ReadingPages(
        api: api,
        book: book,
        content: Map<String, dynamic>.from(d),
      ),
    ),
  );
}

class ReadingPages extends StatefulWidget {
  final Api api;
  final Map book;
  final Map<String, dynamic> content;
  const ReadingPages({
    super.key,
    required this.api,
    required this.book,
    required this.content,
  });
  @override
  State<ReadingPages> createState() => _ReadingPagesState();
}

class _ReadingPagesState extends State<ReadingPages> {
  late final List<String> pages;
  late int page;
  double fontSize = 19;
  final scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    final lines = (widget.content['text'] as String).split('\n');
    pages = [];
    var part = '';
    for (final line in lines) {
      if (part.length + line.length > 1500 && part.isNotEmpty) {
        pages.add(part);
        part = '';
      }
      part += '$line\n';
    }
    if (part.isNotEmpty) pages.add(part);
    if (pages.isEmpty) pages.add('');
    page = (widget.content['page'] as int? ?? 0).clamp(0, pages.length - 1);
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> go(int value) async {
    await widget.api.call(
      '/books/${widget.book['id']}/progress',
      method: 'PUT',
      data: {'page': value},
    );
    if (!mounted) return;
    setState(() => page = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext c) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mục lục',
              icon: const Icon(Icons.format_list_numbered),
              onPressed: () async {
                final v = await showModalBottomSheet<int>(
                  context: c,
                  isScrollControlled: true,
                  builder: (c) => SafeArea(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(c).height * .7,
                      child: ListView(
                        children: [
                          const ListTile(title: Text('Chọn phần đọc')),
                          for (var i = 0; i < pages.length; i++)
                            ListTile(
                              selected: i == page,
                              title: Text('Phần ${i + 1}'),
                              subtitle: Text(
                                pages[i].split('\n').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.pop(c, i),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
                if (v != null) {
                  try {
                    await go(v);
                  } catch (e) {
                    if (c.mounted) message(c, e);
                  }
                }
              },
            ),
            Expanded(
              child: Text(
                'Phần ${page + 1}/${pages.length}',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Giảm cỡ chữ',
              onPressed: fontSize > 14
                  ? () => setState(() => fontSize -= 1)
                  : null,
              icon: const Icon(Icons.text_decrease),
            ),
            IconButton(
              tooltip: 'Tăng cỡ chữ',
              onPressed: fontSize < 28
                  ? () => setState(() => fontSize += 1)
                  : null,
              icon: const Icon(Icons.text_increase),
            ),
          ],
        ),
      ),
      LinearProgressIndicator(value: (page + 1) / pages.length, minHeight: 2),
      Expanded(
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
          children: [
            SelectableText(
              pages[page],
              style: TextStyle(
                fontFamily: 'MotSerif',
                fontSize: fontSize,
                height: 1.85,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.content['credit'],
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(c).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (page > 0)
                Expanded(
                  child: ActionButton(
                    label: '← Phần trước',
                    secondary: true,
                    action: () => go(page - 1),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 12),
              if (page < pages.length - 1)
                Expanded(
                  child: ActionButton(
                    label: 'Phần tiếp →',
                    action: () => go(page + 1),
                  ),
                )
              else
                const Expanded(
                  child: Center(child: Text('Đã đến cuối tác phẩm')),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

Future<void> editReadingContent(BuildContext c, Api api, Map book) async {
  String text = '', credit = '';
  if (book['readable'] == 1) {
    final old = await api.call('/books/${book['id']}/content');
    text = old['text'];
    credit = old['credit'];
  }
  if (!c.mounted) return;
  await Navigator.push(
    c,
    MaterialPageRoute(
      builder: (_) => ContentEditor(
        api: api,
        book: book,
        initialText: text,
        initialCredit: credit,
      ),
    ),
  );
}

class ContentEditor extends StatefulWidget {
  final Api api;
  final Map book;
  final String initialText, initialCredit;
  const ContentEditor({
    super.key,
    required this.api,
    required this.book,
    required this.initialText,
    required this.initialCredit,
  });
  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  late final text = TextEditingController(text: widget.initialText),
      credit = TextEditingController(text: widget.initialCredit);
  bool rights = false;
  @override
  void dispose() {
    text.dispose();
    credit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Biên tập bản số')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(widget.book['title'], style: Theme.of(c).textTheme.headlineMedium),
        const SizedBox(height: 18),
        TextField(
          controller: credit,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Tác giả, nguồn và quyền sử dụng',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: text,
          minLines: 12,
          maxLines: 24,
          maxLength: 2000000,
          decoration: const InputDecoration(
            labelText:
                'Nội dung (ghi rõ loại bản đọc)',
            alignLabelWithHint: true,
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: rights,
          onChanged: (v) => setState(() => rights = v ?? false),
          title: const Text(
            'Tôi có quyền cung cấp nội dung này trong thư viện.',
          ),
        ),
        const SizedBox(height: 18),
        ActionButton(
          label: 'Lưu bản đọc',
          action: () async {
            if (!rights) {
              throw ApiError('Vui lòng xác nhận quyền sử dụng nội dung.');
            }
            await widget.api.call(
              '/books/${widget.book['id']}/content',
              method: 'PUT',
              data: {'text': text.text, 'credit': credit.text},
            );
            if (c.mounted) Navigator.pop(c);
          },
        ),
      ],
    ),
  );
}

class ReviewsScreen extends StatelessWidget {
  final Api api;
  final Map book;
  const ReviewsScreen({super.key, required this.api, required this.book});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Đánh giá sách')),
    body: DataView(
      api: api,
      path: '/books/${book['id']}/reviews',
      builder: (c, data, reload) => ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(book['title'], style: Theme.of(c).textTheme.headlineMedium),
          const SizedBox(height: 20),
          ActionButton(
            label: 'Viết / sửa đánh giá của bạn',
            icon: Icons.star_outline,
            action: () async {
              final mine = (data as List).where(
                (e) => e['user_id'] == api.user?['id'],
              );
              final old = mine.isEmpty ? null : mine.first;
              final form = await editForm(c, 'Cảm nhận của bạn', [
                FieldSpec(
                  'rating',
                  'Số sao',
                  value: '${old?['rating'] ?? 5}',
                  choices: const ['1', '2', '3', '4', '5'],
                ),
                FieldSpec(
                  'comment',
                  'Nhận xét',
                  lines: 4,
                  required: false,
                  value: old?['comment'] ?? '',
                ),
              ]);
              if (form == null) return;
              await api.call(
                '/books/${book['id']}/review',
                method: 'PUT',
                data: {
                  'rating': int.parse(form['rating']!),
                  'comment': form['comment'] ?? '',
                },
              );
              reload();
            },
          ),
          const SizedBox(height: 20),
          if ((data as List).isEmpty)
            const Empty('Chưa có đánh giá', 'Hãy chia sẻ cảm nhận đầu tiên.'),
          for (final r in data)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '★' * (r['rating'] as int),
                      style: const TextStyle(
                        color: Color(0xFFB68B43),
                        fontSize: 19,
                      ),
                    ),
                    if ('${r['comment']}'.isNotEmpty) Text(r['comment']),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
