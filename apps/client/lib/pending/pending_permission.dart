/// Gateway acceptance or a legacy terminal outcome for a permission decision.
///
/// [accepted] removes the request optimistically; [confirmed] remains a
/// supported legacy outcome. Otherwise,
/// [stale] and [upstreamError] mean the authoritative snapshot should be
/// re-read, while [resultUnknown] keeps the request visible and pending.
enum PermissionDecisionOutcome {
  accepted,
  confirmed,
  stale,
  upstreamError,
  resultUnknown,
}

/// A decision a user can submit for a pending permission. [always] is never
/// submitted on a direct tap: the page first surfaces the exact patterns
/// OpenCode will save and only confirms the intent from a dialog.
enum PermissionDecision { once, reject, always }

/// The Gateway's decision acknowledgement mapped into the client domain.
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

  /// The Gateway accepted the command for best-effort delivery.
  sent,

  /// OpenCode confirmed the decision; the request leaves the workbench.
  confirmed,

  /// The request is stale and no longer pending.
  stale,

  /// OpenCode's permission-reply API rejected the command.
  upstreamError,

  /// The terminal outcome could not be determined; the request stays visible.
  resultUnknown,

  /// Another client confirmed the request first; it was handled elsewhere and
  /// authority has been re-read.
  handledElsewhere,

  /// The gateway rejected the command (client/4xx error).
  rejected,
}
