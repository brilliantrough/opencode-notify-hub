import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/devices/devices_controller.dart';
import 'package:client/history/notification_history.dart';
import 'package:client/realtime/realtime_controller.dart';
import 'package:client/realtime/ws_client.dart';
import 'package:client/settings/settings_controller.dart';
import 'package:client/ui/history_page.dart';
import 'package:client/ui/home_page.dart';
import 'package:client/ui/login_page.dart';
import 'package:client/ui/plugin_setup_page.dart';
import 'package:client/ui/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_controller.dart';

void main() {
  late FakeAuthController auth;

  test('Windows theme uses Microsoft YaHei UI consistently', () {
    final theme = notifyThemeFor(TargetPlatform.windows);

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Microsoft YaHei UI');
    expect(theme.textTheme.bodyMedium?.fontFamilyFallback, [
      'Microsoft YaHei',
      'Segoe UI',
      'Arial',
    ]);
  });

  test('non-Windows themes keep their platform typography', () {
    final linuxTheme = notifyThemeFor(TargetPlatform.linux);
    final androidTheme = notifyThemeFor(TargetPlatform.android);

    expect(
      linuxTheme.textTheme.bodyMedium?.fontFamily,
      isNot('Microsoft YaHei UI'),
    );
    expect(
      androidTheme.textTheme.bodyMedium?.fontFamily,
      isNot('Microsoft YaHei UI'),
    );
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    bool? isAndroid,
    bool settle = true,
    Map<String, Object> settings = const {},
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    SharedPreferences.setMockInitialValues(settings);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          wsStatusProvider.overrideWith(
            (ref) => Stream.value(WsStatus.connected),
          ),
          notificationHistoryProvider.overrideWithValue(
            InMemoryNotificationHistory(),
          ),
          sharedPreferencesProvider.overrideWithValue(Future.value(prefs)),
          if (isAndroid != null) isAndroidProvider.overrideWithValue(isAndroid),
          if (navigatorKey != null)
            appNavigatorKeyProvider.overrideWithValue(navigatorKey),
        ],
        child: const NotifyApp(),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('AuthUnknown shows a loading indicator', (tester) async {
    auth = FakeAuthController(const AuthUnknown());
    // No pumpAndSettle: the progress indicator animates forever.
    await pumpApp(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Unauthenticated routes to the login page', (tester) async {
    auth = FakeAuthController(const Unauthenticated());
    await pumpApp(tester);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('MaterialApp attaches the app navigator key provider', (
    tester,
  ) async {
    auth = FakeAuthController(const Unauthenticated());
    final navigatorKey = GlobalKey<NavigatorState>();
    await pumpApp(tester, navigatorKey: navigatorKey);

    expect(navigatorKey.currentState, isNotNull);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('AwaitingVerification routes to the verify-email page', (
    tester,
  ) async {
    auth = FakeAuthController(const AwaitingVerification('user@example.com'));
    await pumpApp(tester);
    expect(find.byType(VerifyEmailPage), findsOneWidget);
  });

  testWidgets('Authenticated routes to the home page with a navigation rail '
      'on desktop', (tester) async {
    auth = FakeAuthController(
      const Authenticated(accessToken: 'token', email: 'user@example.com'),
    );
    await pumpApp(tester, isAndroid: false);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('desktop uses app scale instead of GTK text scaling', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    auth = FakeAuthController(const Unauthenticated());

    await pumpApp(
      tester,
      isAndroid: false,
      settings: {SettingsController.textScaleKey: 1.2},
    );

    final context = tester.element(find.byType(LoginPage));
    expect(MediaQuery.textScalerOf(context).scale(10), 12);
  });

  testWidgets('Android continues to use the platform text scale', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    auth = FakeAuthController(const Unauthenticated());

    await pumpApp(tester, isAndroid: true);

    final context = tester.element(find.byType(LoginPage));
    expect(MediaQuery.textScalerOf(context).scale(10), 20);
  });

  testWidgets('desktop zoom shortcuts update and reset text scale', (
    tester,
  ) async {
    auth = FakeAuthController(const Unauthenticated());
    await pumpApp(tester, isAndroid: false);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    var context = tester.element(find.byType(LoginPage));
    expect(MediaQuery.textScalerOf(context).scale(10), 11);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    context = tester.element(find.byType(LoginPage));
    expect(MediaQuery.textScalerOf(context).scale(10), 10);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    context = tester.element(find.byType(LoginPage));
    expect(MediaQuery.textScalerOf(context).scale(10), 11);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    context = tester.element(find.byType(LoginPage));
    expect(MediaQuery.textScalerOf(context).scale(10), 10);
  });

  testWidgets('Authenticated on Android uses bottom navigation instead of a '
      'rail', (tester) async {
    auth = FakeAuthController(
      const Authenticated(accessToken: 'token', email: 'user@example.com'),
    );
    await pumpApp(tester, isAndroid: true);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('rail destinations switch the visible page', (tester) async {
    auth = FakeAuthController(
      const Authenticated(accessToken: 'token', email: 'user@example.com'),
    );
    await pumpApp(tester, isAndroid: false);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('历史'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('插件'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PluginSetupPage), findsOneWidget);
    expect(find.byType(HistoryPage), findsNothing);
  });
}
