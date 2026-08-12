import '../realtime/notify_event.dart';

/// Maximum number of questions rendered in a notification body; the rest
/// collapse into a single remaining-count line.
const _maxQuestionsInBody = 3;

/// Notification title per spec §11: leads with the event source and the
/// literal wire event type, so a lockscreen shows WHICH machine/project
/// needs the user and WHAT happened without opening the app.
String buildNotificationTitle(NotifyEvent event) =>
    '${event.machine} · ${event.project} · ${event.type.wireName}';

/// Notification body per spec §11.
///
/// - question: up to the first [_maxQuestionsInBody] questions with their
///   option labels, plus a remaining-count line when more exist.
/// - permission: the permission type.
/// - terminal: outcome, elapsed duration, and the optional summary.
/// - heartbeat/action_resolved (never shown as notifications) and
///   provider_action (whose detail lives in the app) have no body.
String buildNotificationBody(NotifyEvent event) {
  return switch (event.type) {
    NotifyEventType.actionRequired => _actionRequiredBody(event),
    NotifyEventType.terminal => _terminalBody(event),
    NotifyEventType.heartbeat => '',
    NotifyEventType.actionResolved => '',
  };
}

String _actionRequiredBody(NotifyEvent event) {
  return switch (event.actionKind) {
    ActionKind.question => _questionBody(event.questions),
    ActionKind.permission => 'Permission: ${event.permissionType}',
    ActionKind.providerAction => '',
    null => '',
  };
}

String _questionBody(List<QuestionPrompt> questions) {
  final shown = questions.take(_maxQuestionsInBody).toList();
  final lines = <String>[
    for (final question in shown) ...[
      question.text,
      if (question.options.isNotEmpty)
        'Options: ${question.options.map((o) => o.label).join(', ')}',
    ],
  ];
  final remaining = questions.length - shown.length;
  if (remaining > 0) {
    final plural = remaining == 1 ? 'question' : 'questions';
    lines.add('…and $remaining more $plural');
  }
  return lines.join('\n');
}

String _terminalBody(NotifyEvent event) {
  final base = '${event.outcome!.wireName} in ${event.elapsedSeconds}s';
  final summary = event.summary;
  return summary == null ? base : '$base\n$summary';
}
