import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../core/theme.dart';

class Splash extends StatefulWidget {
  final VoidCallback onDone;
  const Splash({super.key, required this.onDone});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: Center(
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (c, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 290,
                height: 310,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [for (var i = 0; i < 5; i++) _book(i)],
                ),
              ),
              const SizedBox(height: 34),
              Opacity(
                opacity: ((ctrl.value - .7) / .2).clamp(0, 1),
                child: const Column(
                  children: [
                    Brand(size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Một trang sách. Một thế giới mới.',
                      style: TextStyle(color: forest),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _book(int i) {
    final t = ((ctrl.value - i * .11) / .24).clamp(0.0, 1.0);
    final v = Curves.easeOutBack.transform(t);
    return Positioned(
      bottom: i * 35.0,
      left: 35 + (i % 2) * 12.0,
      child: Transform.translate(
        offset: Offset(0, -430 * (1 - v)),
        child: Transform.rotate(
          angle: (1 - v) * .35 * (i.isEven ? 1 : -1),
          child: Opacity(
            opacity: math.min(t * 5, 1),
            child: Container(
              width: 210 - (i % 3) * 13,
              height: 35,
              decoration: BoxDecoration(
                color: [
                  forest,
                  peach,
                  const Color(0xFFABCBD9),
                  const Color(0xFF7AADC5),
                  const Color(0xFF32566D),
                ][i],
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Container(
                    width: 4,
                    color: Colors.white.withValues(alpha: .45),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
