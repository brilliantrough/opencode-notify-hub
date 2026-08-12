import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';

final ingestKeysApiProvider = Provider<IngestKeysApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getIngestKeysApi(),
);

final ingestKeysControllerProvider =
    AsyncNotifierProvider<IngestKeysController, List<IngestKey>>(
      IngestKeysController.new,
    );

/// A registered ingest key as shown in the client.
///
/// Deliberately has **no secret field**: the one-time secret returned by
/// `POST /v1/ingest-keys` exists only in the [CreateIngestKeyResponse]
/// handed back by [IngestKeysController.create] and is never stored in
/// state (or anywhere else).
class IngestKey {
  const IngestKey({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUsedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  @override
  bool operator ==(Object other) {
    return other is IngestKey &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt;
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, lastUsedAt);

  @override
  String toString() =>
      'IngestKey(id: $id, name: $name, createdAt: $createdAt, '
      'lastUsedAt: $lastUsedAt)';
}

/// Manages the authenticated user's ingest keys.
///
/// The key list only exists for an authenticated session: [build] watches
/// [authControllerProvider] and stays empty while unauthenticated, and
/// every mutating method requires an [Authenticated] state (throwing
/// [StateError] otherwise), so all gateway calls are scoped to the current
/// user.
class IngestKeysController extends AsyncNotifier<List<IngestKey>> {
  IngestKeysApi get _api => ref.read(ingestKeysApiProvider);

  @override
  Future<List<IngestKey>> build() async {
    final auth = ref.watch(authControllerProvider);
    if (auth is! Authenticated) {
      return const [];
    }
    return _listKeys();
  }

  /// Creates a new ingest key named [name].
  ///
  /// Returns the gateway's [CreateIngestKeyResponse], which carries the
  /// one-time secret (`secret`). The secret is held only in this method
  /// result — the row added to state is a secret-free [IngestKey] — so the
  /// caller (the UI) can display it exactly once.
  Future<CreateIngestKeyResponse> create(String name) async {
    _requireAuthenticated();
    final response = await _api.createIngestKey(
      createIngestKeyBody: CreateIngestKeyBody((b) => b.name = name),
    );
    final created = response.data;
    if (created == null) {
      throw StateError('Empty createIngestKey response');
    }
    final current = await future;
    state = AsyncData([
      ...current,
      IngestKey(
        id: created.id,
        name: created.name,
        createdAt: created.createdAt,
      ),
    ]);
    return created;
  }

  /// Re-fetches the key list from the gateway, replacing the state.
  Future<List<IngestKey>> list() async {
    _requireAuthenticated();
    final keys = await _listKeys();
    state = AsyncData(keys);
    return keys;
  }

  /// Revokes (deletes) an ingest key and removes its row from state.
  Future<void> revoke(String id) async {
    _requireAuthenticated();
    await _api.revokeIngestKey(id: id);
    final current = await future;
    state = AsyncData([
      for (final key in current)
        if (key.id != id) key,
    ]);
  }

  Future<List<IngestKey>> _listKeys() async {
    final response = await _api.listIngestKeys();
    final data = response.data;
    if (data == null) {
      return const [];
    }
    return data.map(_toIngestKey).toList();
  }

  void _requireAuthenticated() {
    if (ref.read(authControllerProvider) is! Authenticated) {
      throw StateError(
        'IngestKeysController requires an authenticated session',
      );
    }
  }

  static IngestKey _toIngestKey(IngestKeyListResponseInner inner) {
    return IngestKey(
      id: inner.id,
      name: inner.name,
      createdAt: inner.createdAt,
      lastUsedAt: inner.lastUsedAt,
    );
  }
}
