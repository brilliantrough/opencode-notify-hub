import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'auth_messages.dart';

/// Verification-code length issued by the gateway.
const verificationCodeLength = 8;

/// Email verification with the SMTP-delivered 8-character code. A
/// successful verification completes the login inside the auth controller,
/// moving the state machine to `Authenticated`; the `AuthGate` swaps in the
/// authenticated shell automatically.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  /// The account email the code was sent to (display + resend target).
  final String email;

  /// Key of the code text field.
  static const Key codeFieldKey = ValueKey('verify-code');

  /// Key of the submit button.
  static const Key submitKey = ValueKey('verify-submit');

  /// Key of the resend-code button.
  static const Key resendKey = ValueKey('verify-resend');

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _codeController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _codeController.text.trim().length == verificationCodeLength;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyEmail(widget.email, _codeController.text.trim());
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

  Future<void> _resend() async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendVerification(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('验证码已重新发送')));
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = authFailureMessage(failure));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('验证邮箱')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text('验证码已发送至 ${widget.email}'),
              const SizedBox(height: 12),
              TextField(
                key: VerifyEmailPage.codeFieldKey,
                controller: _codeController,
                maxLength: verificationCodeLength,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  counterText: '',
                ),
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
                key: VerifyEmailPage.submitKey,
                onPressed: _canSubmit ? _submit : null,
                child: const Text('验证'),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: VerifyEmailPage.resendKey,
                onPressed: _resend,
                child: const Text('重新发送验证码'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
