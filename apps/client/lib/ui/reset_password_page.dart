import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'auth_messages.dart';
import 'register_page.dart' show minPasswordLength;
import 'verify_email_page.dart' show verificationCodeLength;

/// Step two of the password-reset flow: the emailed code plus the new
/// password. A successful reset revokes every session, so this pops the
/// whole auth flow back to the login page and confirms with a snackbar.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  /// The account email the reset code was sent to.
  final String email;

  /// Key of the code text field.
  static const Key codeFieldKey = ValueKey('reset-code');

  /// Key of the new-password text field.
  static const Key passwordFieldKey = ValueKey('reset-password');

  /// Key of the password-confirmation text field.
  static const Key confirmFieldKey = ValueKey('reset-confirm');

  /// Key of the submit button.
  static const Key submitKey = ValueKey('reset-submit');

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _codeController.text.trim().length == verificationCodeLength &&
      _passwordController.text.length >= minPasswordLength &&
      _passwordController.text == _confirmController.text;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    // Captured up front: after the pop below this page's context is gone.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            widget.email,
            _codeController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        // Every session was revoked and the state machine is back to
        // Unauthenticated: return to the login page (the flow's root).
        Navigator.of(context).popUntil((route) => route.isFirst);
        messenger.showSnackBar(
          const SnackBar(content: Text('密码已重置，请重新登录')),
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
      appBar: AppBar(title: const Text('重置密码')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text('重置验证码已发送至 ${widget.email}'),
              const SizedBox(height: 12),
              TextField(
                key: ResetPasswordPage.codeFieldKey,
                controller: _codeController,
                maxLength: verificationCodeLength,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: ResetPasswordPage.passwordFieldKey,
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  helperText: '至少 $minPasswordLength 个字符',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: ResetPasswordPage.confirmFieldKey,
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '确认新密码'),
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
                key: ResetPasswordPage.submitKey,
                onPressed: _canSubmit ? _submit : null,
                child: const Text('重置密码'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
