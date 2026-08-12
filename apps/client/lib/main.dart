import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';

/// Boots the app: platform services first (windowing, notifications,
/// Firebase on Android), then the provider container seeded with the
/// bootstrap overrides — so [notificationServiceProvider] is bound before
/// any realtime provider can read it — then the widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  final container = ProviderContainer(overrides: bootstrap.overrides);
  bootstrap.attach(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const NotifyApp()),
  );
}
