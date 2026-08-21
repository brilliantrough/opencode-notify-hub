import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../config/server_config.dart';
import 'auth_messages.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'server_settings_dialog.dart';

/// Email + password login. Submit stays disabled until both fields are
/// valid; failures surface as concise localized messages. An unverified
/// login moves the auth state machine to `AwaitingVerification`, and the
/// `AuthGate` swaps this page for the verification page automatically.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  /// Key of the email text field.
  static const Key emailFieldKey = ValueKey('login-email');

  /// Key of the password text field.
  static const Key passwordFieldKey = ValueKey('login-password');

  /// Key of the submit button.
  static const Key submitKey = ValueKey('login-submit');

  /// Key of the link to the registration page.
  static const Key registerLinkKey = ValueKey('login-register-link');

  /// Key of the link to the forgot-password page.
  static const Key forgotLinkKey = ValueKey('login-forgot-link');
  static const Key serverKey = ValueKey('login-server');

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      isValidEmail(_emailController.text.trim()) &&
      _passwordController.text.isNotEmpty;

  Future<void> _submit() async {
    if (ref.read(serverConfigProvider).gatewayHttpBase.isEmpty) {
      setState(() => _error = '请先点击上方"服务器"设置服务器地址');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    } on AuthUnverified {
      // The state machine moved to AwaitingVerification; the AuthGate
      // swaps in the verification page. No error to show here.
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
    final server = ref.watch(serverConfigProvider).gatewayHttpBase;
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              ListTile(
                key: LoginPage.serverKey,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dns_outlined),
                title: const Text('服务器'),
                subtitle: Text(
                  server.isEmpty ? '未设置，点击配置' : server,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => showServerSettingsDialog(context),
              ),
              const SizedBox(height: 12),
              TextField(
                key: LoginPage.emailFieldKey,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '邮箱'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: LoginPage.passwordFieldKey,
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码'),
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: LoginPage.submitKey,
                onPressed: _canSubmit ? _submit : null,
                child: const Text('登录'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    key: LoginPage.registerLinkKey,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterPage(),
                      ),
                    ),
                    child: const Text('注册账号'),
                  ),
                  TextButton(
                    key: LoginPage.forgotLinkKey,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    ),
                    child: const Text('忘记密码'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
