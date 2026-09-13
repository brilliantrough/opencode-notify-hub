import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../config/server_config.dart';

/// Local copies only; Gateway key-list responses never contain the secret.
class LocalKeySecrets {
  LocalKeySecrets({required this.scope, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final String scope;
  final FlutterSecureStorage _storage;
  String _key(String id) => 'notify_plugin_key_v1:${jsonEncode([scope, id])}';

  Future<String?> read(String id) => _storage.read(key: _key(id));
  Future<void> save(String id, String secret) =>
      _storage.write(key: _key(id), value: secret);
  Future<void> remove(String id) => _storage.delete(key: _key(id));
}

final localKeySecretsProvider = Provider<LocalKeySecrets>((ref) {
  final auth = ref.watch(authControllerProvider);
  final gateway = ref.watch(appConfigProvider).gatewayHttpBase;
  if (auth is! Authenticated) throw StateError('请先登录');
  return LocalKeySecrets(
    scope: jsonEncode([gateway, auth.email.toLowerCase()]),
  );
});

final localKeySecretProvider = FutureProvider.autoDispose
    .family<String?, String>(
      (ref, id) => ref.watch(localKeySecretsProvider).read(id),
    );
