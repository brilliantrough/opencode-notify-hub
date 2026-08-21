import '../auth/auth_controller.dart';

/// Concise, localized user-facing message for an [AuthFailure].
String authFailureMessage(AuthFailure failure) => switch (failure) {
  AuthInvalidCredentials() => '邮箱或密码错误',
  AuthEmailTaken() => '该邮箱已被注册',
  AuthEmailNotAllowed() => '该邮箱不在允许注册名单内，请联系管理员',
  AuthUnverified() => '邮箱尚未验证',
  AuthInvalidCode() => '验证码无效或已过期',
  AuthNetwork() => '网络连接失败，请稍后重试',
  AuthUnknownFailure() => '操作失败，请稍后重试',
};

/// Permissive email shape check used to enable/disable form submits.
bool isValidEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
