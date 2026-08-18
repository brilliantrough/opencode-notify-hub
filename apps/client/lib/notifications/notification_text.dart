import '../history/notification_history.dart';
import '../realtime/notify_event.dart';

/// Maximum number of questions rendered in a notification body; the rest
/// collapse into a single remaining-count line.
const _maxQuestionsInBody = 3;

/// Concise user-facing title. Internal wire names and ids stay out of UI text.
String buildNotificationTitle(NotifyEvent event) =>
    '${event.machine} · ${event.directoryName} · ${event.sessionTitle} · ${buildNotificationStatus(event)}';

HistoryEntry buildHistoryEntry(
  NotifyEvent event, {
  required DateTime receivedAt,
}) => HistoryEntry(
  eventId: event.eventId,
  title: buildNotificationTitle(event),
  body: buildNotificationBody(event),
  receivedAt: receivedAt,
  occurredAt: event.occurredAt,
  status: buildNotificationStatus(event),
  eventType: event.type.wireName,
  machine: event.machine,
  project: event.project,
  directory: event.directory,
  directoryName: event.directoryName,
  sessionId: event.sessionId,
  sessionTitle: event.sessionTitle,
  requestId: event.requestId,
);

/// Notification body per spec §11.
///
/// - question: up to the first [_maxQuestionsInBody] questions with their
///   option labels, plus a remaining-count line when more exist.
/// - permission/provider action: a direct next step.
/// - terminal: elapsed duration and the optional summary.
/// - heartbeat/action_resolved are never shown as notifications and have no
///   body.
String buildNotificationBody(NotifyEvent event) {
  return switch (event.type) {
    NotifyEventType.actionRequired => _actionRequiredBody(event),
    NotifyEventType.terminal => _terminalBody(event),
    NotifyEventType.heartbeat => '',
    NotifyEventType.actionResolved => '',
  };
}

String _actionRequiredBody(NotifyEvent event) {
  final detail = switch (event.actionKind) {
    ActionKind.question => _questionBody(event.questions),
    ActionKind.permission => [
      '请求权限：${event.permissionType}',
      if (event.permissionSummary != null) event.permissionSummary!,
    ].join('\n'),
    ActionKind.providerAction =>
      event.providerActionMessage ?? '请在 OpenCode 中完成操作',
    null => '请打开 OpenCode 查看详情',
  };
  return detail;
}

String _questionBody(List<QuestionPrompt> questions) {
  final shown = questions.take(_maxQuestionsInBody).toList();
  final lines = <String>[
    for (final question in shown) ...[
      question.text,
      if (question.options.isNotEmpty)
        '选项：${question.options.map((o) => o.label).join('、')}',
    ],
  ];
  final remaining = questions.length - shown.length;
  if (remaining > 0) {
    lines.add('还有 $remaining 个问题');
  }
  return lines.join('\n');
}

String _terminalBody(NotifyEvent event) {
  final base = '用时 ${event.elapsedSeconds} 秒';
  final summary = event.summary;
  return summary == null ? base : '$base\n$summary';
}

String buildNotificationStatus(NotifyEvent event) => switch (event.type) {
  NotifyEventType.heartbeat => '任务进行中',
  NotifyEventType.actionResolved => '操作已处理',
  NotifyEventType.actionRequired => switch (event.actionKind) {
    ActionKind.question => '需要回答',
    ActionKind.permission => '需要授权',
    ActionKind.providerAction => '需要操作',
    null => '需要处理',
  },
  NotifyEventType.terminal => switch (event.outcome) {
    TerminalOutcome.completed => '任务已完成',
    TerminalOutcome.failed => '任务失败',
    TerminalOutcome.stopped => '任务已停止',
    null => '任务已结束',
  },
};
