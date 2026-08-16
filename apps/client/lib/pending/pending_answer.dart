import 'pending_interaction.dart';

/// Gateway acceptance or a legacy terminal outcome for a submitted answer.
///
/// [accepted] removes the request optimistically; [confirmed] remains a
/// supported legacy outcome. Otherwise,
/// [stale] and [upstreamError] mean the authoritative snapshot should be
/// re-read, while [resultUnknown] keeps the request visible and pending.
enum QuestionAnswerOutcome { accepted, confirmed, stale, upstreamError, resultUnknown }

/// The Gateway's answer acknowledgement mapped into the client domain.
class QuestionAnswerResult {
  const QuestionAnswerResult({required this.commandId, required this.outcome});

  final String commandId;
  final QuestionAnswerOutcome outcome;
}

/// Visible per-request submission lifecycle while answering a question.
enum QuestionSubmissionState {
  /// Nothing has been submitted for the request yet.
  idle,

  /// The answer command is in flight; gateway acceptance is not yet known.
  submitting,

  /// The Gateway accepted the command for best-effort delivery.
  sent,

  /// OpenCode confirmed the answers; the request leaves the workbench.
  confirmed,

  /// The request is stale and no longer pending.
  stale,

  /// OpenCode's question-reply API rejected the command.
  upstreamError,

  /// The terminal outcome could not be determined; the request stays visible.
  resultUnknown,

  /// Another client confirmed the request first; it was handled elsewhere and
  /// authority has been re-read.
  handledElsewhere,

  /// The gateway rejected the command (client/4xx error).
  rejected,
}

/// Composes the ordered `string[][]` answer set for [questions] in exact
/// upstream order, or returns `null` when any question is unanswered.
///
/// [singleChoice] holds the selected option label per question (used only for
/// single-select questions), [multiChoice] holds the selected option labels
/// per question, and [custom] holds the custom text per question (offered for
/// every question).
///
/// A single-select answer is one option label or one custom value
/// (exclusive); a multi-select answer lists every selected option in upstream
/// option order followed by custom text when present.
List<List<String>>? composeQuestionAnswers({
  required List<PendingQuestionItem> questions,
  required List<String?> singleChoice,
  required List<Set<String>> multiChoice,
  required List<String> custom,
}) {
  assert(
    questions.length == singleChoice.length &&
        questions.length == multiChoice.length &&
        questions.length == custom.length,
  );
  final answers = <List<String>>[];
  for (var index = 0; index < questions.length; index++) {
    final question = questions[index];
    final customText = custom[index].trim();
    if (question.multiple) {
      final selected = [
        for (final option in question.options)
          if (multiChoice[index].contains(option.label)) option.label,
      ];
      if (selected.isEmpty && customText.isEmpty) {
        return null;
      }
      answers.add([...selected, if (customText.isNotEmpty) customText]);
    } else {
      if (customText.isNotEmpty) {
        answers.add([customText]);
      } else if (singleChoice[index] != null) {
        answers.add([singleChoice[index]!]);
      } else {
        return null;
      }
    }
  }
  return answers;
}
