import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart' show PendingApi;

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../realtime/instance_presence.dart';
import 'pending_interaction.dart';

final pendingApiProvider = Provider<PendingApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getPendingApi(),
);

typedef PendingInteractionLoader = Future<List<PendingInteraction>> Function();

final pendingInteractionLoaderProvider = Provider<PendingInteractionLoader>((
  ref,
) {
  final api = ref.watch(pendingApiProvider);
  return () async {
    final response = await api.getPendingInteractions();
    final snapshot = response.data;
    if (snapshot == null) {
      throw StateError('Empty pending-interactions response');
    }
    return snapshot.interactions.map(PendingInteraction.fromGenerated).toList();
  };
});

final pendingInteractionsProvider =
    AsyncNotifierProvider<
      PendingInteractionsController,
      List<PendingInteraction>
    >(PendingInteractionsController.new);

class PendingInteractionsController
    extends AsyncNotifier<List<PendingInteraction>> {
  bool _building = false;
  bool _refreshQueued = false;
  Future<void>? _activeRefresh;
  int _epoch = 0;

  @override
  Future<List<PendingInteraction>> build() async {
    _epoch++;
    _building = true;
    _refreshQueued = false;
    final auth = ref.watch(authControllerProvider);
    ref.listen(instancePresencesProvider, (previous, next) {
      if (_actionableSignature(previous) != _actionableSignature(next)) {
        if (_building) {
          _refreshQueued = true;
        } else {
          unawaited(refresh());
        }
      }
    });
    if (auth is! Authenticated) {
      _building = false;
      return const [];
    }
    try {
      return await _fetch();
    } finally {
      _building = false;
      if (_refreshQueued) {
        scheduleMicrotask(() => unawaited(refresh()));
      }
    }
  }

  Future<void> refresh() {
    if (_building) {
      _refreshQueued = true;
      return Future.value();
    }
    final active = _activeRefresh;
    if (active != null) {
      _refreshQueued = true;
      return active;
    }
    final operation = _runRefreshLoop();
    _activeRefresh = operation;
    return operation.whenComplete(() {
      _activeRefresh = null;
      if (_refreshQueued && !_building) {
        unawaited(refresh());
      }
    });
  }

  Future<void> _runRefreshLoop() async {
    final epoch = _epoch;
    if (ref.read(authControllerProvider) is! Authenticated) {
      state = const AsyncData([]);
      return;
    }
    do {
      _refreshQueued = false;
      state = const AsyncLoading<List<PendingInteraction>>();
      final next = await AsyncValue.guard(_fetch);
      if (epoch != _epoch ||
          ref.read(authControllerProvider) is! Authenticated) {
        return;
      }
      state = next;
    } while (_refreshQueued &&
        ref.read(authControllerProvider) is Authenticated);
  }

  Future<List<PendingInteraction>> _fetch() async {
    final interactions = [
      ...await ref.read(pendingInteractionLoaderProvider)(),
    ];
    interactions.sort((left, right) {
      final byTime = left.occurredAt.compareTo(right.occurredAt);
      if (byTime != 0) return byTime;
      final byInstance = left.instanceId.compareTo(right.instanceId);
      if (byInstance != 0) return byInstance;
      return left.requestId.compareTo(right.requestId);
    });
    return interactions;
  }

  static String _actionableSignature(
    Map<String, OpenCodeInstancePresence>? instances,
  ) {
    if (instances == null) return '';
    final values =
        instances.values
            .where(
              (instance) =>
                  instance.state == InstancePresenceState.controllable,
            )
            .map(
              (instance) =>
                  '${instance.instanceId}:${instance.lastSeenAt.toIso8601String()}',
            )
            .toList()
          ..sort();
    return values.join('|');
  }
}
