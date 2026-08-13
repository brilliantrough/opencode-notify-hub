import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted session credentials.
///
/// Only the long-lived refresh token and the account email are stored;
/// short-lived access tokens are kept in memory by the caller and are never
/// written to persistent storage.
class Credentials {
  const Credentials({required this.refreshToken, required this.accountEmail});

  final String refreshToken;
  final String accountEmail;
}

/// Store for session credentials.
abstract class CredentialsStore {
  Future<void> save({required String refreshToken, required String accountEmail});

  Future<Credentials?> read();

  Future<void> clear();
}

/// Volatile in-memory store, for tests and non-persistent use.
class InMemoryCredentialsStore implements CredentialsStore {
  Credentials? _credentials;

  @override
  Future<void> save({
    required String refreshToken,
    required String accountEmail,
  }) async {
    _credentials = Credentials(
      refreshToken: refreshToken,
      accountEmail: accountEmail,
    );
  }

  @override
  Future<Credentials?> read() async => _credentials;

  @override
  Future<void> clear() async {
    _credentials = null;
  }
}

/// Credentials store backed by the platform keychain/keystore via
/// `flutter_secure_storage`.
class SecureCredentialsStore implements CredentialsStore {
  SecureCredentialsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _refreshTokenKey = 'refresh_token_v1';
  static const String _accountEmailKey = 'account_email_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save({
    required String refreshToken,
    required String accountEmail,
  }) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _accountEmailKey, value: accountEmail);
  }

  @override
  Future<Credentials?> read() async {
    final values = await _storage.readAll();
    final refreshToken = values[_refreshTokenKey];
    final accountEmail = values[_accountEmailKey];
    if (refreshToken == null || accountEmail == null) {
      return null;
    }
    return Credentials(refreshToken: refreshToken, accountEmail: accountEmail);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accountEmailKey);
  }
}
