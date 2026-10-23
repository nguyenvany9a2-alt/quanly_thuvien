import 'photo_covers.dart';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'cover_data.dart';
import 'editorial_cover.dart';
import '../core/api.dart';

class Brand extends StatelessWidget {
  final double size;
  const Brand({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size * 1.45,
        height: size * 1.45,
        decoration: BoxDecoration(
          color: forest,
          borderRadius: BorderRadius.circular(size * .4),
          border: Border.all(color: const Color(0xFF6B99AD)),
        ),
        child: CustomPaint(painter: _MotMark()),
      ),
      const SizedBox(width: 8),
      Text(
        'MỌT',
        style: TextStyle(
          fontFamily: displayFont,
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: 2,
        ),
      ),
    ],
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark
        ? const Color(0x88142F44)
        : color.withValues(alpha: .46);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: forest.withValues(alpha: dark ? .18 : .07),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? .12 : .8),
              ),
            ),
            child: Material(color: Colors.transparent, child: child),
          ),
        ),
      ),
    );
  }
}

class Cover extends StatelessWidget {
  final String path;
  final double? width, height;
  const Cover(this.path, {super.key, this.width, this.height});
  @override
  Widget build(BuildContext context) {
    final imagePath = photoCovers[path] ?? path;
    final design = photoCovers.containsKey(path) ? null : coverData[path];
    if (design != null) {
      return SizedBox(
        width: width,
        height: height,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: EditorialCover(
            title: design['title'] as String,
            author: design['author'] as String,
            index: design['index'] as int,
          ),
        ),
      );
    }
    Widget fallback(BuildContext c, Object e, StackTrace? s) => Container(
      color: sage,
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_rounded, size: 40, color: forest),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imagePath.startsWith('assets/')
          ? Image.asset(
              imagePath,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: fallback,
            )
          : Image.network(
              imagePath,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: fallback,
            ),
    );
  }
}

void message(BuildContext c, Object text) {
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(content: Text('$text'), behavior: SnackBarBehavior.floating),
  );
}

class ActionButton extends StatefulWidget {
  final String label;
  final Future<void> Function() action;
  final IconData? icon;
  final bool secondary;
  const ActionButton({
    super.key,
    required this.label,
    required this.action,
    this.icon,
    this.secondary = false,
  });
  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool busy = false;
  @override
  Widget build(BuildContext c) => FilledButton(
    style: widget.secondary
        ? FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: forest,
            side: const BorderSide(color: Color(0xFFD9E1E2)),
          )
        : null,
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            try {
              await widget.action();
            } catch (e) {
              if (mounted) message(context, e);
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.secondary ? forest : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(widget.label)),
      ],
    ),
  );
}

class DataView extends StatefulWidget {
  final Api api;
  final String path;
  final Widget Function(BuildContext, dynamic, VoidCallback) builder;
  const DataView({
    super.key,
    required this.api,
    required this.path,
    required this.builder,
  });
  @override
  State<DataView> createState() => _DataViewState();
}

class _DataViewState extends State<DataView> {
  late Future<dynamic> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.call(widget.path);
  }

  void reload() {
    if (!mounted) return;

    final next = widget.api.call(widget.path);
    setState(() {
      future = next;
    });
  }

  @override
  Widget build(BuildContext c) => FutureBuilder(
    future: future,
    builder: (c, s) {
      if (s.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 42),
                const SizedBox(height: 12),
                Text('${s.error}', textAlign: TextAlign.center),
                TextButton(onPressed: reload, child: const Text('Thử lại')),
              ],
            ),
          ),
        );
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return widget.builder(c, s.data, reload);
    },
  );
}

class Empty extends StatelessWidget {
  final String title, body;
  const Empty(this.title, this.body, {super.key});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Column(
      children: [
        Icon(
          Icons.local_library_outlined,
          size: 50,
          color: Theme.of(c).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(c).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
      ],
    ),
  );
}

class MotBadge extends StatelessWidget {
  final String text;
  final bool warning;
  const MotBadge(this.text, {super.key, this.warning = false});
  @override
  Widget build(BuildContext c) {
    final negative =
        warning || ['Từ chối', 'Hết hạn giữ', 'Mất', 'Hỏng'].contains(text);
    final waiting = ['Chờ duyệt', 'Chờ nhận sách'].contains(text);
    final foreground = negative
        ? const Color(0xFF995342)
        : waiting
        ? const Color(0xFF856638)
        : forest;
    final background = negative
        ? const Color(0xFFF6E7E0)
        : waiting
        ? const Color(0xFFF4EDDF)
        : sage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'MotSans',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

Future<bool> confirm(BuildContext c, String text) async =>
    await showDialog<bool>(
      context: c,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận thao tác'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ??
    false;

class FieldSpec {
  final String key, label, value;
  final bool required, secret;
  final int lines;
  final List<String>? choices;
  const FieldSpec(
    this.key,
    this.label, {
    this.value = '',
    this.required = true,
    this.secret = false,
    this.lines = 1,
    this.choices,
  });
}

Future<Map<String, String>?> editForm(
  BuildContext c,
  String title,
  List<FieldSpec> fields,
) => showDialog<Map<String, String>>(
  context: c,
  builder: (_) => _EditForm(title, fields),
);

class _EditForm extends StatefulWidget {
  final String title;
  final List<FieldSpec> fields;
  const _EditForm(this.title, this.fields);
  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> ctrls = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.value),
  };
  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: f.choices != null
                      ? DropdownButtonFormField<String>(
                          initialValue: f.choices!.contains(ctrls[f.key]!.text)
                              ? ctrls[f.key]!.text
                              : f.choices!.first,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: f.label),
                          items: f.choices!
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(statusLabel(s)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => ctrls[f.key]!.text = v!,
                        )
                      : TextFormField(
                          controller: ctrls[f.key],
                          obscureText: f.secret,
                          maxLines: f.secret ? 1 : f.lines,
                          decoration: InputDecoration(labelText: f.label),
                          validator: (v) =>
                              f.required && (v ?? '').trim().isEmpty
                              ? 'Vui lòng nhập ${f.label.toLowerCase()}'
                              : null,
                        ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            for (final f in widget.fields) {
              if (f.choices != null && ctrls[f.key]!.text.isEmpty) {
                ctrls[f.key]!.text = f.choices!.first;
              }
            }
            Navigator.pop(c, {
              for (final f in widget.fields) f.key: ctrls[f.key]!.text.trim(),
            });
          }
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}

/// A single clipped blur keeps the navigation light without blurring the page.
class GlassDock extends StatelessWidget {
  final Widget child;
  const GlassDock({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1419364A),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: .86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: .4),
              ),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class EditorialLabel extends StatelessWidget {
  final String text;
  const EditorialLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontFamily: 'MotSans',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.1,
      color: Color(0xFF8A7455),
    ),
  );
}

/// Open pages meet at the spine to form the M in MỌT.
class _MotMark extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final ink = Paint()
      ..color = const Color(0xFFE8D7AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final inset in [0.0, 8.0]) {
      final page = Path()
        ..moveTo(20 + inset, 30 + inset)
        ..quadraticBezierTo(37, 27 + inset, 50, 46 + inset)
        ..quadraticBezierTo(63, 27 + inset, 80 - inset, 30 + inset)
        ..lineTo(80 - inset, 67 + inset)
        ..quadraticBezierTo(62, 63 + inset, 50, 77)
        ..quadraticBezierTo(38, 63 + inset, 20 + inset, 67 + inset)
        ..close();
      canvas.drawPath(page, ink);
    }
    canvas.drawLine(const Offset(50, 46), const Offset(50, 77), ink);
    canvas.drawCircle(
      const Offset(50, 22),
      3,
      Paint()..color = const Color(0xFFE8D7AF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CirculationPanel extends StatelessWidget {
  final String cover;
  final Widget child;
  final Color color;
  const CirculationPanel({
    super.key,
    required this.cover,
    required this.child,
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Panel(
    color: color,
    padding: const EdgeInsets.all(14),
    child: LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Cover(
            cover,
            width: box.maxWidth < 320 ? 58 : 76,
            height: box.maxWidth < 320 ? 87 : 114,
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
