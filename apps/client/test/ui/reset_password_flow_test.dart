import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/ui/forgot_password_page.dart';
import 'package:client/ui/login_page.dart';
import 'package:client/ui/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_controller.dart';

void main() {
  late FakeAuthController auth;

  Future<void> pumpFlow(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => auth)],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton forgotSubmit(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(ForgotPasswordPage.submitKey));

  FilledButton resetSubmit(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(ResetPasswordPage.submitKey));

  setUp(() {
    auth = FakeAuthController(const Unauthenticated());
  });

  testWidgets('forgot: submit stays disabled until the email is valid', (
    tester,
  ) async {
    await pumpFlow(tester);
    await tester.tap(find.byKey(LoginPage.forgotLinkKey));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordPage), findsOneWidget);

    expect(forgotSubmit(tester).onPressed, isNull);
    await tester.enterText(
      find.byKey(ForgotPasswordPage.emailFieldKey),
      'not-an-email',
    );
    await tester.pump();
    expect(forgotSubmit(tester).onPressed, isNull);
    await tester.enterText(
      find.byKey(ForgotPasswordPage.emailFieldKey),
      'user@example.com',
    );
    await tester.pump();
    expect(forgotSubmit(tester).onPressed, isNotNull);
  });

  testWidgets('forgot failure shows a concise localized message', (
    tester,
  ) async {
    auth.forgotFailure = const AuthNetwork();
    await pumpFlow(tester);
    await tester.tap(find.byKey(LoginPage.forgotLinkKey));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(ForgotPasswordPage.emailFieldKey),
      'user@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(ForgotPasswordPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('网络连接失败，请稍后重试'), findsOneWidget);
    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('reset success returns to the login page', (tester) async {
    await pumpFlow(tester);

    // Login → forgot.
    await tester.tap(find.byKey(LoginPage.forgotLinkKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ForgotPasswordPage.emailFieldKey),
      'user@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(ForgotPasswordPage.submitKey));
    await tester.pumpAndSettle();

    // Forgot → reset.
    expect(auth.forgotEmails, ['user@example.com']);
    expect(find.byType(ResetPasswordPage), findsOneWidget);
    expect(resetSubmit(tester).onPressed, isNull);

    // Incomplete form keeps the submit disabled.
    await tester.enterText(
      find.byKey(ResetPasswordPage.codeFieldKey),
      '1234567',
    );
    await tester.enterText(
      find.byKey(ResetPasswordPage.passwordFieldKey),
      'new-password-1',
    );
    await tester.enterText(
      find.byKey(ResetPasswordPage.confirmFieldKey),
      'new-password-1',
    );
    await tester.pump();
    expect(resetSubmit(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(ResetPasswordPage.codeFieldKey),
      '12345678',
    );
    await tester.pump();
    expect(resetSubmit(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(ResetPasswordPage.submitKey));
    await tester.pumpAndSettle();

    expect(auth.resets, [
      (email: 'user@example.com', code: '12345678', password: 'new-password-1'),
    ]);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(ResetPasswordPage), findsNothing);
    expect(find.text('密码已重置，请重新登录'), findsOneWidget);
  });

  testWidgets('invalid reset code keeps the page and shows an error', (
    tester,
  ) async {
    auth.resetFailure = const AuthInvalidCode();
    await pumpFlow(tester);
    await tester.tap(find.byKey(LoginPage.forgotLinkKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ForgotPasswordPage.emailFieldKey),
      'user@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(ForgotPasswordPage.submitKey));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(ResetPasswordPage.codeFieldKey),
      'DEADBEEF',
    );
    await tester.enterText(
      find.byKey(ResetPasswordPage.passwordFieldKey),
      'new-password-1',
    );
    await tester.enterText(
      find.byKey(ResetPasswordPage.confirmFieldKey),
      'new-password-1',
    );
    await tester.pump();
    await tester.tap(find.byKey(ResetPasswordPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('验证码无效或已过期'), findsOneWidget);
    expect(find.byType(ResetPasswordPage), findsOneWidget);
  });
}
