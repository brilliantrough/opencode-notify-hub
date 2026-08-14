import 'package:notify_api/notify_api.dart' as api;

class PendingTool {
  const PendingTool({required this.messageId, required this.callId});

  final String messageId;
  final String callId;
}

class PendingOption {
  const PendingOption({required this.label, required this.description});

  final String label;
  final String description;
}

class PendingQuestionItem {
  const PendingQuestionItem({
    required this.header,
    required this.question,
    required this.options,
    required this.multiple,
    required this.custom,
  });

  final String header;
  final String question;
  final List<PendingOption> options;
  final bool multiple;
  final bool custom;
}

sealed class PendingInteraction {
  const PendingInteraction({
    required this.instanceId,
    required this.machine,
    required this.project,
    required this.directory,
    required this.sessionId,
    required this.sessionTitle,
    required this.requestId,
    required this.occurredAt,
    required this.tool,
  });

  factory PendingInteraction.fromGenerated(
    api.PendingSnapshotInteractionsInner interaction,
  ) {
    final value = interaction.oneOf.value;
    if (value is api.PendingInteractionOneOf) {
      return PendingQuestion(
        instanceId: value.instanceId,
        machine: value.machine,
        project: value.project,
        directory: value.directory,
        sessionId: value.sessionId,
        sessionTitle: value.sessionTitle,
        requestId: value.requestId,
        occurredAt: value.occurredAt.toUtc(),
        tool: _tool(value.tool),
        questions: [
          for (final question in value.questions)
            PendingQuestionItem(
              header: question.header,
              question: question.question,
              options: [
                for (final option in question.options)
                  PendingOption(
                    label: option.label,
                    description: option.description,
                  ),
              ],
              multiple: question.multiple,
              custom: question.custom,
            ),
        ],
      );
    }
    if (value is api.PendingInteractionOneOf1) {
      final metadata = value.metadata.value;
      return PendingPermission(
        instanceId: value.instanceId,
        machine: value.machine,
        project: value.project,
        directory: value.directory,
        sessionId: value.sessionId,
        sessionTitle: value.sessionTitle,
        requestId: value.requestId,
        occurredAt: value.occurredAt.toUtc(),
        tool: _tool(value.tool),
        permission: value.permission,
        patterns: value.patterns.toList(growable: false),
        always: value.always.toList(growable: false),
        metadata: metadata is Map
            ? Map<String, dynamic>.from(metadata)
            : const {},
      );
    }
    throw FormatException(
      'Unsupported pending interaction ${value.runtimeType}',
    );
  }

  final String instanceId;
  final String machine;
  final String project;
  final String directory;
  final String sessionId;
  final String sessionTitle;
  final String requestId;
  final DateTime occurredAt;
  final PendingTool? tool;

  static PendingTool? _tool(api.PendingInteractionOneOfTool? tool) =>
      tool == null
      ? null
      : PendingTool(messageId: tool.messageId, callId: tool.callId);
}

class PendingQuestion extends PendingInteraction {
  const PendingQuestion({
    required super.instanceId,
    required super.machine,
    required super.project,
    required super.directory,
    required super.sessionId,
    required super.sessionTitle,
    required super.requestId,
    required super.occurredAt,
    required super.tool,
    required this.questions,
  });

  final List<PendingQuestionItem> questions;
}

class PendingPermission extends PendingInteraction {
  const PendingPermission({
    required super.instanceId,
    required super.machine,
    required super.project,
    required super.directory,
    required super.sessionId,
    required super.sessionTitle,
    required super.requestId,
    required super.occurredAt,
    required super.tool,
    required this.permission,
    required this.patterns,
    required this.always,
    required this.metadata,
  });

  final String permission;
  final List<String> patterns;
  final List<String> always;
  final Map<String, dynamic> metadata;
}
