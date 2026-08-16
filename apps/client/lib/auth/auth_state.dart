/// Authentication state machine for the client session.
///
/// ```text
/// AuthUnknown ──bootstrap──> Unauthenticated ──register──> AwaitingVerification
///      │       └──transient──> AuthRestoreFailed                   │
///      │                          │ retry                           │
///      └────────Authenticated <───┴──────── verifyEmail ───────────┘
///                  (login / verify success)       (after register login)
/// ```
///
/// `Authenticated` is the only state in which gateway calls beyond `/auth/`
/// may succeed.
sealed class AuthState {
  const AuthState();
}

/// Initial state: the stored session (if any) has not been restored yet.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Stored credentials exist, but the client could not restore them because a
/// local store or transient gateway operation failed. The credentials are
/// retained so the user can retry without signing in again.
class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed();
}

/// No valid session. The user must log in (or register and verify).
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// The account exists but its email is not verified yet. Reached after a
/// successful registration or a login rejected with `EMAIL_UNVERIFIED`.
class AwaitingVerification extends AuthState {
  const AwaitingVerification(this.email);

  final String email;
}

/// A valid session is held: the access token is in memory and the refresh
/// token is persisted in the credentials store.
///
/// The gateway ID of the current device is deliberately NOT part of this
/// state: device registration runs asynchronously after login (see
/// `DevicesController.registerCurrentDevice`) and is tracked under
/// `deviceIdPrefsKey` in shared preferences, so any device ID captured at
/// login time would be stale or empty.
class Authenticated extends AuthState {
  const Authenticated({required this.accessToken, required this.email});

  /// Short-lived bearer token, in memory only.
  final String accessToken;

  /// Account email, as persisted alongside the refresh token.
  final String email;
}
