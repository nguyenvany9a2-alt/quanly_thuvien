import 'package:flutter/material.dart';

import '../core/theme.dart';

class EditorialCover extends StatelessWidget {
  final String title, author;
  final int index;
  const EditorialCover({
    super.key,
    required this.title,
    required this.author,
    required this.index,
  });
  @override
  Widget build(BuildContext c) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: LayoutBuilder(
      builder: (c, b) {
        final w = b.maxWidth;
        final h = b.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: w * 5,
                maxWidth: w * 5,
                minHeight: h * 4,
                maxHeight: h * 4,
                child: Transform.translate(
                  offset: Offset(-(index % 5) * w, -(index ~/ 5) * h),
                  child: Image.asset(
                    'assets/images/cover_atlas.png',
                    width: w * 5,
                    height: h * 4,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66071724),
                    Color(0x00071724),
                    Color(0xF2071724),
                  ],
                  stops: [0, .3, 1],
                ),
              ),
            ),
            Positioned(
              left: w * .1,
              right: w * .1,
              top: h * .07,
              child: Text(
                'MỌT  /  VĂN CHƯƠNG',
                style: TextStyle(
                  fontSize: w * .048,
                  color: const Color(0xFFF4E9D6),
                  letterSpacing: 1.3,
                ),
              ),
            ),
            Positioned(
              left: w * .1,
              right: w * .08,
              bottom: h * .075,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: displayFont,
                      fontSize: w * .115,
                      color: const Color(0xFFFFF5E1),
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: h * .035),
                  Text(
                    author,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: w * .057,
                      color: const Color(0xFFDFD8C9),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: w * .04,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x99000000), Color(0x11FFFFFF)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
