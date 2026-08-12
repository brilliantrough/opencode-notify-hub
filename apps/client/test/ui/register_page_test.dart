import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/ui/register_page.dart';
import 'package:client/ui/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_controller.dart';

void main() {
  late FakeAuthController auth;

  Future<void> pumpRegister(WidgetTester tester, {Widget? home}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => auth)],
        child: MaterialApp(home: home ?? const RegisterPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(RegisterPage.submitKey));

  Future<void> enterForm(
    WidgetTester tester, {
    required String email,
    required String password,
    required String confirm,
  }) async {
    await tester.enterText(find.byKey(RegisterPage.emailFieldKey), email);
    await tester.enterText(
      find.byKey(RegisterPage.passwordFieldKey),
      password,
    );
    await tester.enterText(find.byKey(RegisterPage.confirmFieldKey), confirm);
    await tester.pump();
  }

  setUp(() {
    auth = FakeAuthController(const Unauthenticated());
  });

  testWidgets('submit stays disabled for invalid input', (tester) async {
    await pumpRegister(tester);
    expect(submitButton(tester).onPressed, isNull);

    // Bad email.
    await enterForm(
      tester,
      email: 'not-an-email',
      password: 'password1',
      confirm: 'password1',
    );
    expect(submitButton(tester).onPressed, isNull);

    // Password too short.
    await enterForm(
      tester,
      email: 'user@example.com',
      password: 'short',
      confirm: 'short',
    );
    expect(submitButton(tester).onPressed, isNull);

    // Confirm mismatch.
    await enterForm(
      tester,
      email: 'user@example.com',
      password: 'password1',
      confirm: 'password2',
    );
    expect(submitButton(tester).onPressed, isNull);
    expect(find.text('两次输入的密码不一致'), findsOneWidget);

    // All valid.
    await enterForm(
      tester,
      email: 'user@example.com',
      password: 'password1',
      confirm: 'password1',
    );
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('successful registration navigates to the verify-email page', (
    tester,
  ) async {
    await pumpRegister(tester, home: const AuthGate());

    // Open the register page from the login page link.
    await tester.tap(find.text('注册账号'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);

    await enterForm(
      tester,
      email: 'new@example.com',
      password: 'password1',
      confirm: 'password1',
    );
    await tester.tap(find.byKey(RegisterPage.submitKey));
    await tester.pumpAndSettle();

    expect(auth.registrations, [
      (email: 'new@example.com', password: 'password1'),
    ]);
    expect(find.byType(VerifyEmailPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
  });

  testWidgets('taken email shows 该邮箱已被注册', (tester) async {
    auth.registerFailure = const AuthEmailTaken();
    await pumpRegister(tester);

    await enterForm(
      tester,
      email: 'taken@example.com',
      password: 'password1',
      confirm: 'password1',
    );
    await tester.tap(find.byKey(RegisterPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('该邮箱已被注册'), findsOneWidget);
    // Still on the register page.
    expect(find.byKey(RegisterPage.submitKey), findsOneWidget);
  });
}
