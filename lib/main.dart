import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api.dart';
import 'core/theme.dart';
import 'core/experience.dart';
import 'screens/auth.dart';
import 'screens/splash.dart';
import 'screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MotApp(api: Api()));
}

class MotApp extends StatefulWidget {
  final Api api;
  final bool showSplash;
  const MotApp({super.key, required this.api, this.showSplash = true});
  @override
  State<MotApp> createState() => _MotAppState();
}

class _MotAppState extends State<MotApp> {
  bool splash = true, ready = false;
  @override
  void initState() {
    super.initState();
    splash = widget.showSplash;
    restore();
  }

  Future<void> restore() async {
    try {
      await widget.api.restore();
    } catch (_) {
      // Hiển thị form đăng nhập nếu phiên chưa thể khôi phục.
    }
    if (mounted) setState(() => ready = true);
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(
    listenable: widget.api,
    builder: (c, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      key: ValueKey(widget.api.user?['id']),
      title: 'MỌT',
      theme: motTheme(dark: preferences(widget.api)['dark'] == true),
      builder: (context, child) {
        final prefs = preferences(widget.api);
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              (prefs['scale'] as num? ?? 1).toDouble(),
            ),
            disableAnimations:
                media.disableAnimations || prefs['reduce_motion'] == true,
          ),
          child: OceanBackground(
            prefs: prefs,
            child: child ?? const SizedBox(),
          ),
        );
      },
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: splash
          ? Splash(
              onDone: () {
                if (mounted) setState(() => splash = false);
              },
            )
          : !ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : widget.api.user == null
          ? AuthScreen(api: widget.api)
          : HomeShell(api: widget.api),
    ),
  );
}
