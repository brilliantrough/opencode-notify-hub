import 'package:client/pending/pending_permission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart'
    show PermissionCommandResultStatusEnum;

void main() {
  test('maps permission decision outcomes from the generated statuses', () {
    expect(
      permissionDecisionOutcomeFromStatus(
        PermissionCommandResultStatusEnum.confirmed,
      ),
      PermissionDecisionOutcome.confirmed,
    );
    expect(
      permissionDecisionOutcomeFromStatus(
        PermissionCommandResultStatusEnum.stale,
      ),
      PermissionDecisionOutcome.stale,
    );
    expect(
      permissionDecisionOutcomeFromStatus(
        PermissionCommandResultStatusEnum.upstreamError,
      ),
      PermissionDecisionOutcome.upstreamError,
    );
    expect(
      permissionDecisionOutcomeFromStatus(
        PermissionCommandResultStatusEnum.resultUnknown,
      ),
      PermissionDecisionOutcome.resultUnknown,
    );
  });

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
