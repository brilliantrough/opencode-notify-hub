import 'package:notify_api/notify_api.dart' as api;

/// Terminal outcome OpenCode reports for a submitted permission decision.
///
/// Only [confirmed] lets the client drop the request from the workbench;
/// [stale] and [upstreamError] mean the authoritative snapshot should be
/// re-read, while [resultUnknown] keeps the request visible and pending.
enum PermissionDecisionOutcome {
  confirmed,
  stale,
  upstreamError,
  resultUnknown,
}

/// A decision a user can submit for a pending permission. [always] is never
/// submitted on a direct tap: the page first surfaces the exact patterns
/// OpenCode will save and only confirms the intent from a dialog.
enum PermissionDecision { once, reject, always }

/// The gateway's correlated decision reply, mapped from the generated contract.
class PermissionDecisionResult {
  const PermissionDecisionResult({
    required this.commandId,
    required this.outcome,
  });

  final String commandId;
  final PermissionDecisionOutcome outcome;
}

/// Visible per-request submission lifecycle while deciding a permission.
enum PermissionDecisionState {
  /// Nothing has been submitted for the request yet.
  idle,

  /// The decision command is in flight; gateway acceptance is not yet known.
  submitting,

  /// OpenCode confirmed the decision; the request leaves the workbench.
  confirmed,

  /// The request is stale and no longer pending.
  stale,

  /// OpenCode's permission-reply API rejected the command.
  upstreamError,

  /// The terminal outcome could not be determined; the request stays visible.
  resultUnknown,

  /// The gateway rejected the command (client/4xx error).
  rejected,
}

/// Maps a generated gateway status onto the domain outcome.
PermissionDecisionOutcome permissionDecisionOutcomeFromStatus(
  api.PermissionCommandResultStatusEnum status,
) {
  if (status == api.PermissionCommandResultStatusEnum.confirmed) {
    return PermissionDecisionOutcome.confirmed;
  }
  if (status == api.PermissionCommandResultStatusEnum.stale) {
    return PermissionDecisionOutcome.stale;
  }
  if (status == api.PermissionCommandResultStatusEnum.upstreamError) {
    return PermissionDecisionOutcome.upstreamError;
  }
  return PermissionDecisionOutcome.resultUnknown;
}
