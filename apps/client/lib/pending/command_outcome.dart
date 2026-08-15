import 'package:notify_api/notify_api.dart' as api;

/// Terminal status of a client-generated command as recorded by the gateway's
/// body-free in-memory outcome correlation.
enum CommandOutcomeStatus {
  accepted,
  confirmed,
  stale,
  upstreamError,
  resultUnknown,
}

/// The interaction kind a command belongs to.
enum CommandOutcomeKind { question, permission }

/// Body-free outcome correlation for one client-generated command id. It
/// carries only correlation and status metadata — never the question answers
/// or the permission decision.
class CommandOutcomeInfo {
  const CommandOutcomeInfo({required this.status, required this.kind});

  final CommandOutcomeStatus status;
  final CommandOutcomeKind kind;
}

/// Maps a generated [api.CommandOutcome] onto the domain type.
CommandOutcomeInfo commandOutcomeFromGenerated(api.CommandOutcome outcome) {
  CommandOutcomeStatus status;
  if (outcome.status == api.CommandOutcomeStatusEnum.accepted) {
    status = CommandOutcomeStatus.accepted;
  } else if (outcome.status == api.CommandOutcomeStatusEnum.confirmed) {
    status = CommandOutcomeStatus.confirmed;
  } else if (outcome.status == api.CommandOutcomeStatusEnum.stale) {
    status = CommandOutcomeStatus.stale;
  } else if (outcome.status == api.CommandOutcomeStatusEnum.upstreamError) {
    status = CommandOutcomeStatus.upstreamError;
  } else {
    status = CommandOutcomeStatus.resultUnknown;
  }
  return CommandOutcomeInfo(
    status: status,
    kind: outcome.kind == api.CommandOutcomeKindEnum.permission
        ? CommandOutcomeKind.permission
        : CommandOutcomeKind.question,
  );
}
