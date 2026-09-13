import 'dart:async';

import 'package:client/api/api_client.dart';
import 'package:client/api/auth_interceptor.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/config/server_config.dart';
import 'package:client/config/app_config.dart';
import 'package:client/devices/devices_controller.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/sessions/session_catalog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthController {
  _Auth(this.email);
  final String email;
  @override
  AuthState build() => Authenticated(accessToken: 'token', email: email);
}

OpenCodeInstancePresence _instance(String id) => OpenCodeInstancePresence(
  instanceId: id,
  machine: 'host',
  project: 'notify',
  directory: '/work/notify',
  openCodeVersion: '1.18.15',
  protocolVersion: 2,
  state: InstancePresenceState.controllable,
  lastSeenAt: DateTime.now(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cold start finds idle sessions, preserves bookmarks across restarts and isolates accounts',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var failing = false;
      final queries = <Map<String, dynamic>>[];
      ProviderContainer create(String email) {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              queries.add(options.queryParameters);
              if (failing) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'hasMore': false,
                    'sessions': [
                      {
                        'sessionId': 'ses_idle',
                        'directory': '/work/notify',
                        'title': 'Old idle session',
                        'updatedAt': '2026-09-01T00:00:00Z',
                        'status': 'idle',
                      },
                    ],
                  },
                ),
              );
            },
          ),
        );
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(() => _Auth(email)),
            appConfigProvider.overrideWithValue(
              const AppConfig(gatewayHttpBase: 'https://notify.example.com'),
            ),
            sharedPreferencesProvider.overrideWithValue(Future.value(prefs)),
            apiClientProvider.overrideWithValue(
              ApiClient(
                dio: dio,
                notifyApi: NotifyApi(dio: dio, interceptors: const []),
                accessTokenHolder: InMemoryAccessTokenHolder(),
              ),
            ),
          ],
        );
        container.read(instancePresencesProvider.notifier).replaceAll([
          _instance('one'),
        ]);
        container.read(sessionCatalogProvider);
        addTearDown(dio.close);
        return container;
      }

      var container = create('alice@example.com');
      await _waitFor(() => !container.read(sessionCatalogProvider).loading);
      var controller = container.read(sessionCatalogProvider.notifier);
      var item = container.read(sessionCatalogProvider).sessions.values.single;
      expect(item.status, 'idle');
      expect(item.verified, isTrue);
      expect(await controller.togglePin(item), isNull);
      await controller.markOpened('one', 'ses_idle');

      failing = true;
      await controller.refresh();
      item = container.read(sessionCatalogProvider).sessions.values.single;
      expect(item.pinned, isTrue);
      expect(item.verified, isFalse);
      expect(item.status, 'unknown');
      container.dispose();

      container = create('alice@example.com');
      await _waitFor(() => !container.read(sessionCatalogProvider).loading);
      expect(
        container.read(sessionCatalogProvider).sessions.values.single.pinned,
        isTrue,
      );
      failing = false;
      container.read(instancePresencesProvider.notifier).replaceAll([
        _instance('two'),
      ]);
      controller = container.read(sessionCatalogProvider.notifier);
      await controller.refresh();
      item = container.read(sessionCatalogProvider).sessions.values.single;
      expect(item.instanceId, 'two');
      expect(item.verified, isTrue);
      expect(item.openedAt, isNotNull);
      expect(queries.last['sessionIds'], 'ses_idle');
      container.dispose();

      failing = true;
      container = create('bob@example.com');
      await _waitFor(() => !container.read(sessionCatalogProvider).loading);
      expect(container.read(sessionCatalogProvider).sessions, isEmpty);
      container.dispose();
    },
  );
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('catalog did not settle');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
