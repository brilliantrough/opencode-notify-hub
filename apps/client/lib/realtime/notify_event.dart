import 'package:notify_api/notify_api.dart' as gen;
import 'package:path/path.dart' as path;

/// The four wire event types of the NotifyEvent envelope.
enum NotifyEventType {
  heartbeat('heartbeat'),
  actionRequired('action_required'),
  actionResolved('action_resolved'),
  terminal('terminal');

  const NotifyEventType(this.wireName);

  /// The exact string used on the wire and in notification titles.
  final String wireName;
}

/// The kind of a user action carried by `action_required`/`action_resolved`.
enum ActionKind {
  question('question'),
  permission('permission'),
  providerAction('provider_action');

  const ActionKind(this.wireName);

  final String wireName;
}

/// Terminal run outcomes.
enum TerminalOutcome {
  completed('completed'),
  failed('failed'),
  stopped('stopped');

  const TerminalOutcome(this.wireName);

  final String wireName;
}

/// One selectable answer of a [QuestionPrompt].
class QuestionOption {
  const QuestionOption({required this.label, this.description});

  final String label;
  final String? description;
}

/// One question the agent asks the user, with its selectable options.
class QuestionPrompt {
  const QuestionPrompt({
    required this.text,
    this.options = const [],
    this.multiple = false,
  });

  final String text;
  final List<QuestionOption> options;
  final bool multiple;
}

/// Normalized view model of a realtime [gen.NotifyEvent] envelope, flat
/// enough for notification text and history UIs to consume without touching
/// the generated discriminated-union types.
///
/// Fields that only exist on some variants stay null (or empty) elsewhere:
/// [requestId]/[actionKind] on the action events, [questions] on question
/// payloads, permission/provider details on their respective action payloads,
/// [outcome]/[summary] on terminal events, and [elapsedSeconds] on
/// heartbeat/terminal events.
class NotifyEvent {
  const NotifyEvent({
    required this.eventId,
    required this.occurredAt,
    required this.machine,
    required this.project,
    required this.directory,
    required this.sessionId,
    required this.sessionTitle,
    required this.type,
    this.requestId,
    this.actionKind,
    this.questions = const [],
    this.permissionType,
    this.permissionSummary,
    this.providerActionMessage,
    this.outcome,
    this.elapsedSeconds,
    this.summary,
  });

  final String eventId;
  final DateTime occurredAt;
  final String machine;
  final String project;
  final String directory;
  final String sessionId;
  final String sessionTitle;
  final NotifyEventType type;
  final String? requestId;
  final ActionKind? actionKind;
  final List<QuestionPrompt> questions;
  final String? permissionType;
  final String? permissionSummary;
  final String? providerActionMessage;
  final TerminalOutcome? outcome;
  final int? elapsedSeconds;
  final String? summary;

  /// Parses one event envelope from its JSON map — e.g. the decoded value
  /// of an FCM `data['event']` string or a WebSocket `event` frame payload.
  ///
  /// Throws [FormatException] when the envelope is malformed: missing or
  /// mistyped fields, unknown event types, or a discriminator/payload
  /// mismatch.
  factory NotifyEvent.parse(Map<String, Object?> json) {
    final gen.NotifyEvent decoded;
    try {
      decoded = gen.standardSerializers.deserializeWith(
        gen.NotifyEvent.serializer,
        json,
      )!;
    } catch (error) {
      throw FormatException('Malformed NotifyEvent envelope', json);
    }

    final variant = decoded.oneOf.value;
    return switch (variant) {
      gen.NotifyEventOneOf v => _fromHeartbeat(v),
      gen.NotifyEventOneOf1 v => _fromActionRequired(v),
      gen.NotifyEventOneOf2 v => _fromActionResolved(v),
      gen.NotifyEventOneOf3 v => _fromTerminal(v),
      _ => throw FormatException('Unknown NotifyEvent variant', json),
    };
  }

  static NotifyEvent _fromHeartbeat(gen.NotifyEventOneOf v) => _base(
    v.eventId,
    v.occurredAt,
    v.source_,
    v.session,
    NotifyEventType.heartbeat,
    elapsedSeconds: v.payload.elapsedSeconds,
  );

  static NotifyEvent _fromActionRequired(gen.NotifyEventOneOf1 v) {
    final payload = v.payload.oneOf.value;
    return switch (payload) {
      gen.NotifyEventOneOf1PayloadOneOf p => _base(
        v.eventId,
        v.occurredAt,
        v.source_,
        v.session,
        NotifyEventType.actionRequired,
        requestId: p.requestId,
        actionKind: ActionKind.question,
        questions: [
          for (final item in p.questions)
            QuestionPrompt(
              text: item.question,
              multiple: item.multiple ?? false,
              options: [
                for (final option in item.options ?? const <gen.NotifyEventOneOf1PayloadOneOfQuestionsInnerOptionsInner>[])
                  QuestionOption(
                    label: option.label,
                    description: option.description,
                  ),
              ],
            ),
        ],
      ),
      gen.NotifyEventOneOf1PayloadOneOf1 p => _base(
        v.eventId,
        v.occurredAt,
        v.source_,
        v.session,
        NotifyEventType.actionRequired,
        requestId: p.requestId,
        actionKind: ActionKind.permission,
        permissionType: p.permission.permission,
        permissionSummary: p.permission.summary,
      ),
      gen.NotifyEventOneOf1PayloadOneOf2 p => _base(
        v.eventId,
        v.occurredAt,
        v.source_,
        v.session,
        NotifyEventType.actionRequired,
        requestId: p.requestId,
        actionKind: ActionKind.providerAction,
        providerActionMessage: p.providerAction.message,
      ),
      _ => throw FormatException(
        'Unknown action_required payload kind',
        payload,
      ),
    };
  }

  static NotifyEvent _fromActionResolved(gen.NotifyEventOneOf2 v) {
    final kind = switch (v.payload.kind) {
      gen.NotifyEventOneOf2PayloadKindEnum.question => ActionKind.question,
      gen.NotifyEventOneOf2PayloadKindEnum.permission => ActionKind.permission,
      _ => throw FormatException(
        'Unknown action_resolved payload kind',
        v.payload.kind,
      ),
    };
    return _base(
      v.eventId,
      v.occurredAt,
      v.source_,
      v.session,
      NotifyEventType.actionResolved,
      requestId: v.payload.requestId,
      actionKind: kind,
    );
  }

  static NotifyEvent _fromTerminal(gen.NotifyEventOneOf3 v) {
    final outcome = switch (v.payload.outcome) {
      gen.NotifyEventOneOf3PayloadOutcomeEnum.completed =>
        TerminalOutcome.completed,
      gen.NotifyEventOneOf3PayloadOutcomeEnum.failed => TerminalOutcome.failed,
      gen.NotifyEventOneOf3PayloadOutcomeEnum.stopped =>
        TerminalOutcome.stopped,
      _ => throw FormatException(
        'Unknown terminal outcome',
        v.payload.outcome,
      ),
    };
    return _base(
      v.eventId,
      v.occurredAt,
      v.source_,
      v.session,
      NotifyEventType.terminal,
      outcome: outcome,
      elapsedSeconds: v.payload.elapsedSeconds,
      summary: v.payload.summary,
    );
  }

  static NotifyEvent _base(
    String eventId,
    DateTime occurredAt,
    gen.NotifyEventOneOfSource source,
    gen.NotifyEventOneOfSession session,
    NotifyEventType type, {
    String? requestId,
    ActionKind? actionKind,
    List<QuestionPrompt> questions = const [],
    String? permissionType,
    String? permissionSummary,
    String? providerActionMessage,
    TerminalOutcome? outcome,
    int? elapsedSeconds,
    String? summary,
  }) => NotifyEvent(
    eventId: eventId,
    occurredAt: occurredAt,
    machine: source.machine,
    project: _readableProject(source.project, source.directory),
    directory: source.directory,
    sessionId: session.id,
    sessionTitle: session.title.trim().isEmpty || session.title == session.id
        ? '未命名会话'
        : session.title,
    type: type,
    requestId: requestId,
    actionKind: actionKind,
    questions: questions,
    permissionType: permissionType,
    permissionSummary: permissionSummary,
    providerActionMessage: providerActionMessage,
    outcome: outcome,
    elapsedSeconds: elapsedSeconds,
    summary: summary,
  );
}

final _internalProjectId = RegExp(
  r'^(?:[0-9a-f]{32,64}|prj_[A-Za-z0-9_-]+)$',
  caseSensitive: false,
);

String _readableProject(String project, String directory) {
  if (!_internalProjectId.hasMatch(project)) {
    return project;
  }
  final context = directory.contains(r'\')
      ? path.Context(style: path.Style.windows)
      : path.posix;
  final label = context.basename(context.normalize(directory));
  return label.isEmpty || label == '.' ? 'unknown' : label;
}
