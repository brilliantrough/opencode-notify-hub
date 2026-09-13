import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import 'local_key_secrets.dart';

final ingestKeysApiProvider = Provider<IngestKeysApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getIngestKeysApi(),
);

final ingestKeysControllerProvider =
    AsyncNotifierProvider<IngestKeysController, List<IngestKey>>(
      IngestKeysController.new,
    );

/// A registered ingest key as shown in the client.
///
/// Secrets are kept separately in the device credential store, not in list state.
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
    ref.watch(localKeySecretsProvider);
    return _listKeys();
  }

  /// Creates a new ingest key named [name].
  ///
  /// Returns the gateway's [CreateIngestKeyResponse], which carries the
  /// secret (`secret`). Persist a local copy before returning it to the UI.
  Future<CreateIngestKeyResponse> create(String name) async {
    _requireAuthenticated();
    final secrets = ref.read(localKeySecretsProvider);
    final response = await _api.createIngestKey(
      createIngestKeyBody: CreateIngestKeyBody((b) => b.name = name),
    );
    final created = response.data;
    if (created == null) {
      throw StateError('Empty createIngestKey response');
    }
    try {
      await secrets.save(created.id, created.secret);
    } catch (_) {
      // Creation succeeded. The dialog retains the response and offers save retry.
    }
    if (!_isCurrent(secrets)) {
      throw StateError('账号已切换，请在原账号查看已创建的密钥');
    }
    ref.invalidate(localKeySecretProvider(created.id));
    final current = state.value ?? const <IngestKey>[];
    state = AsyncData([
      ...current.where((key) => key.id != created.id),
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
    final secrets = ref.read(localKeySecretsProvider);
    final keys = await _listKeys();
    if (_isCurrent(secrets)) state = AsyncData(keys);
    return keys;
  }

  /// Revokes (deletes) an ingest key and removes its row from state.
  Future<void> revoke(String id) async {
    _requireAuthenticated();
    final secrets = ref.read(localKeySecretsProvider);
    await _api.revokeIngestKey(id: id);
    try {
      await secrets.remove(id);
    } catch (_) {
      /* Revocation already succeeded. */
    }
    if (!_isCurrent(secrets)) {
      return;
    }
    ref.invalidate(localKeySecretProvider(id));
    final current = state.value ?? const <IngestKey>[];
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

  bool _isCurrent(LocalKeySecrets secrets) =>
      ref.mounted &&
      ref.read(authControllerProvider) is Authenticated &&
      ref.read(localKeySecretsProvider).scope == secrets.scope;

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
