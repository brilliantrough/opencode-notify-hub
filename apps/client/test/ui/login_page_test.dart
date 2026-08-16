import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/config/server_config.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:client/ui/home_page.dart';
import 'package:client/ui/login_page.dart';
import 'package:client/ui/register_page.dart';
import 'package:client/ui/server_settings_dialog.dart';
import 'package:client/ui/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_controller.dart';

void main() {
  late FakeAuthController auth;

  Future<void> pumpLogin(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
    Widget? home,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          ...extraOverrides,
        ],
        child: MaterialApp(home: home ?? const LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(LoginPage.submitKey));

  Future<void> enterCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(LoginPage.emailFieldKey), email);
    await tester.enterText(find.byKey(LoginPage.passwordFieldKey), password);
    await tester.pump();
  }

  setUp(() {
    auth = FakeAuthController(const Unauthenticated());
  });

  testWidgets('submit stays disabled until email and password are valid', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(submitButton(tester).onPressed, isNull);

    await enterCredentials(tester, email: 'not-an-email', password: 'secret1');
    expect(submitButton(tester).onPressed, isNull);

    await enterCredentials(tester, email: 'user@example.com', password: '');
    expect(submitButton(tester).onPressed, isNull);

    await enterCredentials(
      tester,
      email: 'user@example.com',
      password: 'secret1',
    );
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('server selector changes the persisted login origin', (
    tester,
  ) async {
    final store = MemoryServerConfigStore('https://old.example.com');
    await pumpLogin(
      tester,
      extraOverrides: [serverConfigStoreProvider.overrideWithValue(store)],
    );

    expect(find.text('https://old.example.com'), findsOneWidget);
    await tester.tap(find.byKey(LoginPage.serverKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ServerSettingsDialog.addressFieldKey),
      'https://new.example.com',
    );
    await tester.tap(find.byKey(ServerSettingsDialog.saveKey));
    await tester.pumpAndSettle();

    expect(store.read(), 'https://new.example.com');
    expect(find.text('https://new.example.com'), findsOneWidget);
  });

  testWidgets('tapping 登录 calls login with the entered credentials', (
    tester,
  ) async {
    await pumpLogin(
      tester,
      extraOverrides: [
        wsStatusProvider.overrideWith(
          (ref) => Stream.value(WsStatus.connected),
        ),
      ],
      home: const AuthGate(),
    );

    await enterCredentials(
      tester,
      email: 'user@example.com',
      password: 'secret1',
    );
    await tester.tap(find.byKey(LoginPage.submitKey));
    await tester.pumpAndSettle();

    expect(auth.logins, [(email: 'user@example.com', password: 'secret1')]);
  });

  testWidgets('401 invalid credentials shows 邮箱或密码错误', (tester) async {
    auth.loginFailure = const AuthInvalidCredentials();
    await pumpLogin(tester);

    await enterCredentials(
      tester,
      email: 'user@example.com',
      password: 'wrong-pass',
    );
    await tester.tap(find.byKey(LoginPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('邮箱或密码错误'), findsOneWidget);
    // Still on the login page.
    expect(find.byKey(LoginPage.submitKey), findsOneWidget);
  });

  testWidgets('network failure shows a concise localized message', (
    tester,
  ) async {
    auth.loginFailure = const AuthNetwork();
    await pumpLogin(tester);

    await enterCredentials(
      tester,
      email: 'user@example.com',
      password: 'secret1',
    );
    await tester.tap(find.byKey(LoginPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('网络连接失败，请稍后重试'), findsOneWidget);
  });

  testWidgets('unverified login routes to the verify-email page', (
    tester,
  ) async {
    auth.loginFailure = const AuthUnverified();
    await pumpLogin(tester, home: const AuthGate());

    await enterCredentials(
      tester,
      email: 'user@example.com',
      password: 'secret1',
    );
    await tester.tap(find.byKey(LoginPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyEmailPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.textContaining('user@example.com'), findsWidgets);
  });

  testWidgets('注册账号 link opens the register page', (tester) async {
    await pumpLogin(tester, home: const AuthGate());

    await tester.tap(find.byKey(LoginPage.registerLinkKey));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
  });
}
