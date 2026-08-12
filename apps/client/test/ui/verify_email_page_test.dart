import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:client/ui/home_page.dart';
import 'package:client/ui/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_controller.dart';

void main() {
  late FakeAuthController auth;

  Future<void> pumpVerify(
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
        child: MaterialApp(
          home: home ?? const VerifyEmailPage(email: 'user@example.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(VerifyEmailPage.submitKey));

  setUp(() {
    auth = FakeAuthController(const AwaitingVerification('user@example.com'));
  });

  testWidgets('submit stays disabled until an 8-character code is entered', (
    tester,
  ) async {
    await pumpVerify(tester);
    expect(submitButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(VerifyEmailPage.codeFieldKey), '1234567');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(VerifyEmailPage.codeFieldKey),
      '12345678',
    );
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('successful verification lands on the home page', (
    tester,
  ) async {
    await pumpVerify(
      tester,
      extraOverrides: [
        wsStatusProvider.overrideWith(
          (ref) => Stream.value(WsStatus.connected),
        ),
      ],
      home: const AuthGate(),
    );
    expect(find.byType(VerifyEmailPage), findsOneWidget);

    await tester.enterText(
      find.byKey(VerifyEmailPage.codeFieldKey),
      'AB12CD34',
    );
    await tester.pump();
    await tester.tap(find.byKey(VerifyEmailPage.submitKey));
    await tester.pumpAndSettle();

    expect(auth.verifyCodes, ['AB12CD34']);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('invalid code shows 验证码无效或已过期', (tester) async {
    auth.verifyFailure = const AuthInvalidCode();
    await pumpVerify(tester);

    await tester.enterText(
      find.byKey(VerifyEmailPage.codeFieldKey),
      'DEADBEEF',
    );
    await tester.pump();
    await tester.tap(find.byKey(VerifyEmailPage.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('验证码无效或已过期'), findsOneWidget);
    // Still on the verify page.
    expect(find.byKey(VerifyEmailPage.submitKey), findsOneWidget);
  });

  testWidgets('resend calls resendVerification and confirms', (tester) async {
    await pumpVerify(tester);

    await tester.tap(find.byKey(VerifyEmailPage.resendKey));
    await tester.pumpAndSettle();

    expect(auth.resentEmails, ['user@example.com']);
    expect(find.text('验证码已重新发送'), findsOneWidget);
  });
}
