import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/experience.dart';
import '../widgets/common.dart';

class ExperienceScreen extends StatefulWidget {
  final Api api;
  const ExperienceScreen({super.key, required this.api});
  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  late Map<String, dynamic> prefs = {
    'dark': false,
    'palette': 'ocean',
    'scale': 1.0,
    'background': '',
    'reduce_motion': false,
    ...preferences(widget.api),
  };
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Trải nghiệm của bạn')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Một không gian, đúng ý bạn.',
                style: Theme.of(c).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text('Màu nền'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in {
                    'ocean': 'Biển xanh',
                    'mist': 'Sương trắng',
                    'ivory': 'Ngà ấm',
                  }.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: prefs['palette'] == e.key,
                      onSelected: (_) =>
                          setState(() => prefs['palette'] = e.key),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Giao diện tối'),
                value: prefs['dark'] == true,
                onChanged: (v) => setState(() => prefs['dark'] = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Giảm chuyển động'),
                value: prefs['reduce_motion'] == true,
                onChanged: (v) => setState(() => prefs['reduce_motion'] = v),
              ),
              Text('Cỡ chữ · ${((prefs['scale'] as num) * 100).round()}%'),
              Slider(
                value: (prefs['scale'] as num).toDouble(),
                min: .85,
                max: 1.3,
                divisions: 9,
                onChanged: (v) => setState(() => prefs['scale'] = v),
              ),
              Text(
                'Mỗi cuốn sách mở ra một chân trời.',
                style: TextStyle(
                  fontSize: 16 * (prefs['scale'] as num).toDouble(),
                ),
              ),
              const SizedBox(height: 20),
              ActionButton(
                label: 'Chọn ảnh nền từ thiết bị',
                icon: Icons.photo_library_outlined,
                action: () async {
                  final image = await pickPhoto();
                  if (image != null && mounted) {
                    setState(() => prefs['background'] = image);
                  }
                },
              ),
              if ((prefs['background'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image(
                    image: photoProvider(prefs['background'])!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => prefs['background'] = ''),
                  child: const Text('Dùng lại nền biển'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        ActionButton(
          label: 'Lưu trải nghiệm',
          action: () async {
            await widget.api.call('/me/experience', method: 'PUT', data: prefs);
            await widget.api.refreshUser();
            if (c.mounted) message(c, 'Đã áp dụng giao diện.');
          },
        ),
      ],
    ),
  );
}

class ProfileEditor extends StatefulWidget {
  final Api api;
  const ProfileEditor({super.key, required this.api});
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final name = TextEditingController(text: widget.api.user?['name']);
  late final phone = TextEditingController(text: widget.api.user?['phone']);
  String? chosen;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Panel(
          child: Column(
            children: [
              UserAvatar({
                ...widget.api.user!,
                'avatar': chosen ?? widget.api.user?['avatar'],
              }, radius: 48),
              const SizedBox(height: 14),
              ActionButton(
                label: 'Chọn ảnh đại diện',
                secondary: true,
                icon: Icons.photo_camera_outlined,
                action: () async {
                  final image = await pickPhoto();
                  if (image != null && mounted) setState(() => chosen = image);
                },
              ),
              TextButton(
                onPressed: () => setState(() => chosen = ''),
                child: const Text('Xóa ảnh đại diện'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: name,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Họ tên',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: phone,
          maxLength: 30,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Điện thoại',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 20),
        ActionButton(
          label: 'Lưu hồ sơ',
          action: () async {
            if (name.text.trim().length < 2) {
              throw ApiError('Họ tên cần ít nhất 2 ký tự.');
            }
            await widget.api.call(
              '/me',
              method: 'PUT',
              data: {'name': name.text.trim(), 'phone': phone.text.trim()},
            );
            if (chosen != null) {
              await widget.api.call(
                '/me/avatar',
                method: 'PUT',
                data: {'image': chosen},
              );
            }
            await widget.api.refreshUser();
            if (c.mounted) Navigator.pop(c);
          },
        ),
      ],
    ),
  );
}
