import 'dart:async';

import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/pending/pending_controller.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MutableAuthController extends AuthController {
  MutableAuthController(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void replace(AuthState next) => state = next;
}

PendingQuestion interaction(String id, DateTime occurredAt) => PendingQuestion(
  instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
  machine: 'dev-box',
  project: 'api',
  directory: '/work/api',
  sessionId: 'ses-$id',
  sessionTitle: 'Session $id',
  requestId: id,
  occurredAt: occurredAt,
  tool: null,
  questions: const [
    PendingQuestionItem(
      header: 'Database',
      question: 'Which database?',
      options: [],
      multiple: false,
      custom: true,
    ),
  ],
);

void main() {
  const authenticated = Authenticated(
    accessToken: 'access-1',
    email: 'user@example.com',
  );

  test('stays empty and does not load while unauthenticated', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(const Unauthenticated()),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return const [];
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(pendingInteractionsProvider.future), isEmpty);
    expect(calls, 0);
  });

  test('loads on authentication and orders longest waiting first', () async {
    var calls = 0;
    final newer = interaction('newer', DateTime.utc(2026, 8, 14, 10));
    final older = interaction('older', DateTime.utc(2026, 8, 14, 9));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(authenticated),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return [newer, older];
        }),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(pendingInteractionsProvider.future);

    expect(result.map((item) => item.requestId), ['older', 'newer']);
    expect(calls, 1);
  });

  test(
    'authentication recovery triggers the first authoritative load',
    () async {
      var calls = 0;
      final auth = MutableAuthController(const Unauthenticated());
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            return [interaction('request', DateTime.utc(2026, 8, 14, 9))];
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      auth.replace(authenticated);
      final result = await container.read(pendingInteractionsProvider.future);

      expect(result.single.requestId, 'request');
      expect(calls, 1);
    },
  );

  test('a controllable instance reconnect refreshes the snapshot', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(authenticated),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return const [];
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(pendingInteractionsProvider.future);

    container.read(instancePresencesProvider.notifier).replaceAll([
      OpenCodeInstancePresence(
        instanceId: '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
        machine: 'dev-box',
        project: 'api',
        directory: '/work/api',
        openCodeVersion: '1.18.18',
        protocolVersion: 1,
        state: InstancePresenceState.controllable,
        lastSeenAt: DateTime.utc(2026, 8, 14, 10),
      ),
    ]);
    await container.read(pendingInteractionsProvider.future);

    expect(calls, 2);
  });

  test('manual refresh replaces the snapshot', () async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => MutableAuthController(authenticated),
        ),
        pendingInteractionLoaderProvider.overrideWithValue(() async {
          calls++;
          return [interaction('request-$calls', DateTime.utc(2026, 8, 14, 9))];
        }),
      ],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(
        pendingInteractionsProvider.future,
      )).single.requestId,
      'request-1',
    );

    await container.read(pendingInteractionsProvider.notifier).refresh();

    expect(
      container.read(pendingInteractionsProvider).requireValue.single.requestId,
      'request-2',
    );
  });

  test(
    'a refresh from the previous session cannot repopulate after logout',
    () async {
      final auth = MutableAuthController(authenticated);
      final delayed = Completer<List<PendingInteraction>>();
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          pendingInteractionLoaderProvider.overrideWithValue(() async {
            calls++;
            if (calls == 1) return const [];
            return delayed.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pendingInteractionsProvider.future);

      final refresh = container
          .read(pendingInteractionsProvider.notifier)
          .refresh();
      auth.replace(const Unauthenticated());
      delayed.complete([
        interaction('old-account', DateTime.utc(2026, 8, 14, 9)),
      ]);
      await refresh;
      final current = await container.read(pendingInteractionsProvider.future);

      expect(current, isEmpty);
    },
  );
}
