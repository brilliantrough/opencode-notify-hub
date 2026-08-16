import 'package:client/pending/pending_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('always allow is a supported decision mapped to the wire value', () {
    expect(PermissionDecision.values, [
      PermissionDecision.once,
      PermissionDecision.reject,
      PermissionDecision.always,
    ]);
    expect(PermissionDecision.values.map((decision) => decision.name), [
      'once',
      'reject',
      'always',
    ]);
  });
}
