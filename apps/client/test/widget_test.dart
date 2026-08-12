// Smoke test: the app boots into the auth gate and, without a stored
// session, shows the login page.

import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/ui/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui/fake_auth_controller.dart';

void main() {
  testWidgets('app boots to the login page when unauthenticated', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => FakeAuthController(const Unauthenticated()),
          ),
        ],
        child: const NotifyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
