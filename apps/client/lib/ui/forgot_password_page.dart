import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../config/server_config.dart';
import 'auth_messages.dart';
import 'reset_password_page.dart';

/// Step one of the password-reset flow: collect the account email and ask
/// the gateway for a reset code, then continue to [ResetPasswordPage].
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  /// Key of the email text field.
  static const Key emailFieldKey = ValueKey('forgot-email');

  /// Key of the submit button.
  static const Key submitKey = ValueKey('forgot-submit');

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting && isValidEmail(_emailController.text.trim());

  Future<void> _submit() async {
    if (ref.read(serverConfigProvider).gatewayHttpBase.isEmpty) {
      setState(() => _error = '请先在登录页设置服务器地址');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResetPasswordPage(email: email),
          ),
        );
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = authFailureMessage(failure));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('忘记密码')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Text('输入账号邮箱，我们将发送重置验证码。'),
              const SizedBox(height: 12),
              TextField(
                key: ForgotPasswordPage.emailFieldKey,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '邮箱'),
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: ForgotPasswordPage.submitKey,
                onPressed: _canSubmit ? _submit : null,
                child: const Text('发送重置码'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
