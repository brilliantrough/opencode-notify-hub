import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';

/// Scripted [AuthController] for widget tests: records calls, replays
/// configured failures, and drives the [AuthState] machine without touching
/// the gateway, the credentials store, or any provider dependency.
class FakeAuthController extends AuthController {
  FakeAuthController(this._initial);

  final AuthState _initial;

  /// Failure thrown by the next [login] call (reused until replaced).
  AuthFailure? loginFailure;

  /// Failure thrown by the next [register] call.
  AuthFailure? registerFailure;

  /// Failure thrown by the next [verifyEmail] call.
  AuthFailure? verifyFailure;

  /// Failure thrown by the next [forgotPassword] call.
  AuthFailure? forgotFailure;

  /// Failure thrown by the next [resetPassword] call.
  AuthFailure? resetFailure;

  final List<({String email, String password})> logins = [];
  final List<({String email, String password})> registrations = [];
  final List<String> verifyCodes = [];
  final List<String> resentEmails = [];
  final List<String> forgotEmails = [];
  final List<({String email, String code, String password})> resets = [];
  int bootstrapCalls = 0;
  int abandonRestoreCalls = 0;
  int logoutCalls = 0;

  @override
  AuthState build() => _initial;

  void replace(AuthState next) => state = next;

  @override
  Future<void> bootstrap() async {
    bootstrapCalls++;
    state = const AuthUnknown();
  }

  @override
  Future<void> abandonSessionRestore() async {
    abandonRestoreCalls++;
    state = const Unauthenticated();
  }

  @override
  Future<void> login(String email, String password) async {
    logins.add((email: email, password: password));
    final failure = loginFailure;
    if (failure != null) {
      if (failure is AuthUnverified) {
        state = AwaitingVerification(email);
      }
      throw failure;
    }
    state = Authenticated(accessToken: 'token', email: email);
  }

  @override
  Future<void> register(String email, String password) async {
    registrations.add((email: email, password: password));
    final failure = registerFailure;
    if (failure != null) {
      throw failure;
    }
    state = AwaitingVerification(email);
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    verifyCodes.add(code);
    final failure = verifyFailure;
    if (failure != null) {
      throw failure;
    }
    final current = state;
    state = Authenticated(
      accessToken: 'token',
      email: current is AwaitingVerification ? current.email : email,
    );
  }

  @override
  Future<void> resendVerification(String email) async {
    resentEmails.add(email);
  }

  @override
  Future<void> forgotPassword(String email) async {
    forgotEmails.add(email);
    final failure = forgotFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    resets.add((email: email, code: code, password: newPassword));
    final failure = resetFailure;
    if (failure != null) {
      throw failure;
    }
    state = const Unauthenticated();
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = const Unauthenticated();
  }
}
