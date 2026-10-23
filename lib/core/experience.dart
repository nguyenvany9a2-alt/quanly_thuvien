import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';

Map<String, dynamic> preferences(Api api) {
  try {
    return Map<String, dynamic>.from(
      jsonDecode(api.user?['preferences'] ?? '{}'),
    );
  } catch (_) {
    return {};
  }
}

Future<String?> pickPhoto() async {
  try {
    return await const MethodChannel('mot/photos').invokeMethod<String>('pick');
  } on MissingPluginException {
    throw ApiError('Chọn ảnh từ thiết bị được hỗ trợ trên ứng dụng Android.');
  } on PlatformException catch (e) {
    throw ApiError(e.message ?? 'Chưa đọc được ảnh.');
  }
}

ImageProvider? photoProvider(String? value) {
  if (value == null || !value.startsWith('data:image/')) return null;
  try {
    return MemoryImage(base64Decode(value.split(',').last));
  } catch (_) {
    return null;
  }
}

class UserAvatar extends StatelessWidget {
  final Map user;
  final double radius;
  const UserAvatar(this.user, {super.key, this.radius = 25});
  @override
  Widget build(BuildContext c) {
    final photo = photoProvider(user['avatar']);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD9EAF1),
      backgroundImage: photo,
      child: photo == null
          ? Text(
              (user['name'] as String? ?? 'M').characters.first,
              style: TextStyle(
                fontSize: radius * .75,
                color: const Color(0xFF12344D),
              ),
            )
          : null,
    );
  }
}

class OceanBackground extends StatelessWidget {
  final Widget child;
  final Map<String, dynamic> prefs;
  const OceanBackground({super.key, required this.child, required this.prefs});
  @override
  Widget build(BuildContext c) {
    final dark = prefs['dark'] == true;
    final custom = photoProvider(prefs['background']);
    final base = switch (prefs['palette']) {
      'ivory' => const Color(0xFFF6F3EB),
      'mist' => const Color(0xFFF0F5FA),
      _ => const Color(0xFFE7F1F7),
    };
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: dark ? const Color(0xFF061827) : base),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: dark ? .34 : .24,
            child: Image(
              image: custom ?? const AssetImage('assets/images/ocean.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (dark ? const Color(0xFF061827) : base).withValues(alpha: .1),
                  (dark ? const Color(0xFF061827) : base).withValues(
                    alpha: .75,
                  ),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
