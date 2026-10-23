import 'package:flutter/material.dart';

const cream = Color(0xFFEAF3F8),
    forest = Color(0xFF12344D),
    peach = Color(0xFFE4EEF6),
    ink = Color(0xFF132E43),
    sage = Color(0xFFD8EAF2);
// Enable the requested fonts after licensed files have been supplied and declared in pubspec.
const useEditorialFonts = bool.fromEnvironment(
  'MOT_LICENSED_FONTS',
  defaultValue: false,
);
const bodyFont = useEditorialFonts ? 'DreamAvenue' : 'MotSans';
const displayFont = useEditorialFonts ? 'TanBuster' : 'MotSerif';
const accentFont = useEditorialFonts ? 'Slight' : 'MotSerif';
ThemeData motTheme({bool dark = false}) {
  final cs =
      ColorScheme.fromSeed(
        seedColor: forest,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: dark ? const Color(0xFFB4DAEB) : forest,
        onPrimary: dark ? forest : Colors.white,
        surface: dark ? const Color(0xFF122D42) : const Color(0xFFF7FBFE),
        onSurface: dark ? const Color(0xFFEBF5FA) : ink,
        secondary: const Color(0xFF6298AD),
      );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: bodyFont,
    fontFamilyFallback: const ['MotSans'],
    colorScheme: cs,
    scaffoldBackgroundColor: Colors.transparent,
  );
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide.none,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 32,
        height: 1.2,
        color: cs.onSurface,
        letterSpacing: -.8,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 26,
        height: 1.25,
        color: cs.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 22,
        height: 1.25,
        color: cs.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        height: 1.55,
        color: cs.onSurface,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface.withValues(alpha: .9),
      contentPadding: const EdgeInsets.all(18),
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(
        borderSide: BorderSide(color: cs.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: cs.outlineVariant.withValues(alpha: .4),
      space: 28,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cs.surface,
      selectedColor: cs.primaryContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: forest,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      height: 72,
      elevation: 0,
      indicatorColor: cs.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: bodyFont, fontSize: 10, color: cs.onSurface),
      ),
    ),
  );
}

String roleLabel(String? v) =>
    {'reader': 'Độc giả', 'librarian': 'Thủ thư', 'manager': 'Quản lý'}[v] ??
    '';
String statusLabel(dynamic v) =>
    {
      'all': 'Tất cả',
      'reader': 'Độc giả',
      'librarian': 'Thủ thư',
      'manager': 'Quản lý',
      'pending': 'Chờ duyệt',
      'approved': 'Chờ nhận sách',
      'fulfilled': 'Đã giao',
      'rejected': 'Từ chối',
      'cancelled': 'Đã hủy',
      'expired': 'Hết hạn giữ',
      'borrowed': 'Đang mượn',
      'returned': 'Đã trả',
      'available': 'Sẵn sàng',
      'reserved': 'Đang giữ',
      'on_loan': 'Đang mượn',
      'damaged': 'Hỏng',
      'lost': 'Mất',
      'withdrawn': 'Ngừng lưu hành',
    }[v] ??
    '$v';
String day(dynamic v) {
  if (v == null) return '—';
  final d = DateTime.tryParse('$v')?.toLocal();
  return d == null
      ? '$v'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
