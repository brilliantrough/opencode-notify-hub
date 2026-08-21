import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../config/server_config.dart';
import 'auth_messages.dart';

/// Minimum accepted password length, matching the gateway's rule.
const minPasswordLength = 8;

/// Account registration: email, password, and password confirmation. A
/// successful registration moves the auth state machine to
/// `AwaitingVerification`; this page pops itself so the `AuthGate`'s
/// verification page (the new home) is revealed.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  /// Key of the email text field.
  static const Key emailFieldKey = ValueKey('register-email');

  /// Key of the password text field.
  static const Key passwordFieldKey = ValueKey('register-password');

  /// Key of the password-confirmation text field.
  static const Key confirmFieldKey = ValueKey('register-confirm');

  /// Key of the submit button.
  static const Key submitKey = ValueKey('register-submit');

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text;

  bool get _canSubmit =>
      !_submitting &&
      isValidEmail(_emailController.text.trim()) &&
      _passwordController.text.length >= minPasswordLength &&
      _passwordsMatch;

  Future<void> _submit() async {
    if (ref.read(serverConfigProvider).gatewayHttpBase.isEmpty) {
      setState(() => _error = '请先在登录页设置服务器地址');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(_emailController.text.trim(), _passwordController.text);
      if (mounted) {
        // The gate's home is now the verification page; drop this route.
        Navigator.of(context).pop();
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
    final showMismatch =
        _confirmController.text.isNotEmpty && !_passwordsMatch;
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                key: RegisterPage.emailFieldKey,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '邮箱'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: RegisterPage.passwordFieldKey,
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  helperText: '至少 $minPasswordLength 个字符',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: RegisterPage.confirmFieldKey,
                controller: _confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  errorText: showMismatch ? '两次输入的密码不一致' : null,
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
                key: RegisterPage.submitKey,
                onPressed: _canSubmit ? _submit : null,
                child: const Text('注册'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
