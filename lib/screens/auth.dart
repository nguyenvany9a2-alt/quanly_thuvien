import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  final Api api;
  const AuthScreen({super.key, required this.api});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  final form = GlobalKey<FormState>();
  bool signup = false, remember = true, hidden = true, accepted = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> recovery(Map r) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Giữ mã khôi phục của bạn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['message'] ?? 'Mã này dùng khi bạn quên mật khẩu.'),
            const SizedBox(height: 16),
            SelectableText(
              r['recovery_code'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không chia sẻ mã này. MỌT không gửi email khôi phục trong bản học phần.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: r['recovery_code']));
              if (c.mounted) message(c, 'Đã sao chép mã.');
            },
            child: const Text('Sao chép'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Đã lưu mã'),
          ),
        ],
      ),
    );
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (signup) {
      if (!accepted) {
        message(context, 'Vui lòng đồng ý quy định mượn sách.');
        return;
      }
      final r = await widget.api.call(
        '/auth/register',
        method: 'POST',
        data: {
          'name': name.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
        },
      );
      await recovery(Map.from(r));
      if (mounted) setState(() => signup = false);
    } else {
      await widget.api.login(email.text.trim(), password.text, remember);
    }
  }

  Future<void> forgot() async {
    final d = await editForm(context, 'Khôi phục mật khẩu', [
      FieldSpec('email', 'Email', value: email.text),
      const FieldSpec('recovery_code', 'Mã khôi phục đã lưu khi đăng ký'),
      const FieldSpec(
        'password',
        'Mật khẩu mới (ít nhất 8 ký tự)',
        secret: true,
      ),
    ]);
    if (d != null) {
      final r = await widget.api.call('/auth/reset', method: 'POST', data: d);
      await recovery(Map.from(r));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: Colors.transparent,
    body: LayoutBuilder(
      builder: (c, box) {
        final hero = (box.maxHeight * .33).clamp(200.0, 310.0);
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: hero,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/ocean.png', fit: BoxFit.cover),
                    Positioned(
                      right: 28,
                      top: 52,
                      bottom: 42,
                      child: Transform.rotate(
                        angle: .13,
                        child: const Cover(
                          'assets/images/book_07.jpg',
                          width: 108,
                          height: 162,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 100,
                      top: 70,
                      bottom: 30,
                      child: Transform.rotate(
                        angle: -.09,
                        child: const Cover(
                          'assets/images/book_01.png',
                          width: 108,
                          height: 162,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Theme(
                            data: motTheme(dark: true),
                            child: const Brand(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                transform: Matrix4.translationValues(0, -24, 0),
                decoration: BoxDecoration(
                  color: Theme.of(c).colorScheme.surface.withValues(alpha: .94),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const EditorialLabel(
                              'Một khoảng riêng cho tri thức',
                            ),
                            const SizedBox(height: 14),
                            Text(
                              signup ? 'Hello, book lover.' : 'Welcome Back',
                              style: Theme.of(c).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              signup
                                  ? 'Tạo tài khoản và bắt đầu hành trình đọc.'
                                  : 'Một cuốn sách hay đang đợi bạn trở lại.',
                              style: TextStyle(
                                color: Theme.of(c).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 26),
                            if (signup) ...[
                              TextFormField(
                                controller: name,
                                decoration: const InputDecoration(
                                  labelText: 'Họ và tên',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    signup && (v ?? '').trim().length < 2
                                    ? 'Nhập họ tên từ 2 ký tự'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (v) =>
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch((v ?? '').trim())
                                  ? 'Nhập email hợp lệ'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: password,
                              obscureText: hidden,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: hidden
                                      ? 'Hiện mật khẩu'
                                      : 'Ẩn mật khẩu',
                                  onPressed: () =>
                                      setState(() => hidden = !hidden),
                                  icon: Icon(
                                    hidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) => (v ?? '').length < 8
                                  ? 'Mật khẩu ít nhất 8 ký tự'
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            if (signup)
                              Material(
                                color: Colors.transparent,
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: accepted,
                                  onChanged: (v) =>
                                      setState(() => accepted = v!),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: const Text(
                                    'Tôi đồng ý giữ gìn sách và trả đúng hạn.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: remember,
                                        onChanged: (v) =>
                                            setState(() => remember = v!),
                                      ),
                                      const Text(
                                        'Keep me signed in',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await forgot();
                                      } catch (e) {
                                        if (mounted) message(context, e);
                                      }
                                    },
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            ActionButton(
                              label: signup ? 'Sign Up' : 'Login',
                              action: submit,
                              icon: Icons.arrow_forward_rounded,
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  signup
                                      ? 'Already have an account?'
                                      : "Don't have any account?",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => signup = !signup),
                                  child: Text(signup ? 'Login' : 'Sign Up'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Center(
                              child: Text(
                                'Đọc chậm một chút. Khám phá nhiều hơn.',
                                style: TextStyle(fontSize: 12, color: forest),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
