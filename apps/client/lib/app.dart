import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_state.dart';
import 'devices/device_identity.dart';
import 'settings/settings_controller.dart';
import 'ui/devices_page.dart';
import 'ui/history_page.dart';
import 'ui/home_page.dart';
import 'ui/ingest_keys_page.dart';
import 'ui/login_page.dart';
import 'ui/plugin_setup_page.dart';
import 'ui/settings_page.dart';
import 'ui/verify_email_page.dart';

/// Whether the app runs on Android (bottom navigation) or a desktop
/// platform (navigation rail). Overridden in tests.
final isAndroidProvider = Provider<bool>((ref) {
  try {
    return currentPlatform() == ClientPlatform.android;
  } on UnsupportedError {
    return false;
  }
});

/// Builds the app theme while preserving native typography off Windows.
ThemeData notifyThemeFor(TargetPlatform platform) {
  return ThemeData(
    platform: platform,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    fontFamily: platform == TargetPlatform.windows
        ? 'Microsoft YaHei UI'
        : null,
    fontFamilyFallback: platform == TargetPlatform.windows
        ? const ['Microsoft YaHei', 'Segoe UI', 'Arial']
        : null,
  );
}

/// Root application widget.
class NotifyApp extends ConsumerWidget {
  const NotifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAndroid = ref.watch(isAndroidProvider);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    return MaterialApp(
      title: 'OpenCode Notify',
      theme: notifyThemeFor(defaultTargetPlatform),
      builder: (context, child) {
        if (child == null || isAndroid) {
          return child ?? const SizedBox.shrink();
        }
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(
              LogicalKeyboardKey.equal,
              control: true,
            ): () =>
                unawaited(settingsController.increaseTextScale()),
            const SingleActivator(
              LogicalKeyboardKey.equal,
              control: true,
              shift: true,
            ): () =>
                unawaited(settingsController.increaseTextScale()),
            const SingleActivator(
              LogicalKeyboardKey.numpadAdd,
              control: true,
            ): () =>
                unawaited(settingsController.increaseTextScale()),
            const SingleActivator(
              LogicalKeyboardKey.minus,
              control: true,
            ): () =>
                unawaited(settingsController.decreaseTextScale()),
            const SingleActivator(
              LogicalKeyboardKey.numpadSubtract,
              control: true,
            ): () =>
                unawaited(settingsController.decreaseTextScale()),
            const SingleActivator(
              LogicalKeyboardKey.digit0,
              control: true,
            ): () =>
                unawaited(settingsController.resetTextScale()),
            const SingleActivator(
              LogicalKeyboardKey.numpad0,
              control: true,
            ): () =>
                unawaited(settingsController.resetTextScale()),
          },
          child: Focus(
            autofocus: true,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(settings.textScale)),
              child: child,
            ),
          ),
        );
      },
      home: const AuthGate(),
    );
  }
}

/// Routes the app by [AuthState]: unknown restores the session (loading),
/// unauthenticated shows the login flow, awaiting-verification shows the
/// code entry, and authenticated shows the operational shell.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    if (ref.read(authControllerProvider) is AuthUnknown) {
      // Restore a persisted session in the background.
      Future.microtask(
        () => ref.read(authControllerProvider.notifier).bootstrap(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (ref.watch(authControllerProvider)) {
      AuthUnknown() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      Unauthenticated() => const LoginPage(),
      AwaitingVerification(:final email) => VerifyEmailPage(email: email),
      Authenticated() => const AppShell(),
    };
  }
}

/// The authenticated shell: a navigation rail on desktop platforms, bottom
/// navigation on Android.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _pages = [
    HomePage(),
    HistoryPage(),
    DevicesPage(),
    IngestKeysPage(),
    PluginSetupPage(),
    SettingsPage(),
  ];

  static const _destinations = [
    (Icons.home_outlined, '首页'),
    (Icons.history, '历史'),
    (Icons.devices_outlined, '设备'),
    (Icons.key_outlined, '密钥'),
    (Icons.extension_outlined, '插件'),
    (Icons.settings_outlined, '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final isAndroid = ref.watch(isAndroidProvider);
    if (isAndroid) {
      return Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: [
            for (final (icon, label) in _destinations)
              NavigationDestination(icon: Icon(icon), label: label),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final (icon, label) in _destinations)
                NavigationRailDestination(icon: Icon(icon), label: Text(label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_index]),
        ],
      ),
    );
  }
}
