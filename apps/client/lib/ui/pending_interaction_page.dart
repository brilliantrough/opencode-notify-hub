import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pending/pending_answer.dart';
import '../pending/pending_controller.dart';
import '../pending/pending_interaction.dart';
import '../pending/pending_permission.dart';

class PendingInteractionPage extends ConsumerStatefulWidget {
  const PendingInteractionPage({
    super.key,
    required this.interaction,
    this.readOnly = false,
    this.lastSeenAt,
  });

  final PendingInteraction interaction;

  /// Read-only view of a request whose owning instance is offline: questions
  /// render as plain text (no inputs) and all submission actions are hidden.
  /// No submission state is written on open.
  final bool readOnly;

  /// The owning instance's last-online time, shown on the offline banner.
  final DateTime? lastSeenAt;

  @override
  ConsumerState<PendingInteractionPage> createState() =>
      _PendingInteractionPageState();
}

class _PendingInteractionPageState
    extends ConsumerState<PendingInteractionPage> {
  final List<String?> _singleChoice = [];
  final List<Set<String>> _multiChoice = [];
  final List<TextEditingController> _customControllers = [];

  PendingQuestion? get _question {
    final interaction = widget.interaction;
    return interaction is PendingQuestion ? interaction : null;
  }

  PendingPermission? get _permission {
    final interaction = widget.interaction;
    return interaction is PendingPermission ? interaction : null;
  }

  @override
  void initState() {
    super.initState();
    final question = _question;
    if (question != null && !widget.readOnly) {
      final count = question.questions.length;
      for (var index = 0; index < count; index++) {
        _singleChoice.add(null);
        _multiChoice.add(<String>{});
        _customControllers.add(TextEditingController());
      }
    }
    // Reopening the page starts a fresh submission attempt. Deferred so the
    // provider write never happens while the widget tree is building.
    // Read-only pages never touch submission state.
    if (widget.readOnly) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (question != null) {
        ref
            .read(questionSubmissionStatesProvider.notifier)
            .reset(question.requestId);
      }
      final permission = _permission;
      if (permission != null) {
        ref
            .read(permissionSubmissionStatesProvider.notifier)
            .reset(permission.requestId);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _customControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<List<String>>? _answers(PendingQuestion question) =>
      composeQuestionAnswers(
        questions: question.questions,
        singleChoice: _singleChoice,
        multiChoice: _multiChoice,
        custom: [for (final controller in _customControllers) controller.text],
      );

  void _onSingleChanged(int index, String? value) {
    setState(() {
      _singleChoice[index] = value;
      if (value != null) {
        _customControllers[index].clear();
      }
    });
  }

  void _onMultiChanged(int index, String label, bool checked) {
    setState(() {
      final selected = _multiChoice[index];
      if (checked) {
        selected.add(label);
      } else {
        selected.remove(label);
      }
    });
  }

  void _onCustomChanged(int index) {
    setState(() {
      // Single-select custom text is exclusive with option selection.
      if (!_question!.questions[index].multiple &&
          _customControllers[index].text.trim().isNotEmpty) {
        _singleChoice[index] = null;
      }
    });
  }

  Future<void> _submit(PendingQuestion question) async {
    final answers = _answers(question);
    if (answers == null) return;
    await ref
        .read(pendingInteractionsProvider.notifier)
        .answerQuestion(question: question, answers: answers);
  }

  Future<void> _decide(
    PendingPermission permission,
    PermissionDecision decision,
  ) async {
    await ref
        .read(pendingInteractionsProvider.notifier)
        .decidePermission(permission: permission, decision: decision);
  }

  void _showAlwaysConfirm(PendingPermission permission) {
    // The highest-risk decision must be dismissed explicitly: a barrier tap
    // must never silently cancel the confirmation mid-submission.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlwaysConfirmDialog(permission: permission),
    );
  }

  @override
  Widget build(BuildContext context) {
    final interaction = widget.interaction;
    final question = _question;
    final submission = question == null
        ? QuestionSubmissionState.idle
        : ref.watch(questionSubmissionStatesProvider)[question.requestId] ??
              QuestionSubmissionState.idle;
    final submitting = submission == QuestionSubmissionState.submitting;
    final locked =
        submission == QuestionSubmissionState.submitting ||
        submission == QuestionSubmissionState.confirmed;
    final readOnly = widget.readOnly;
    final answers = question == null || readOnly ? null : _answers(question);
    final permission = _permission;
    final permissionState = permission == null
        ? PermissionDecisionState.idle
        : ref.watch(permissionSubmissionStatesProvider)[permission.requestId] ??
              PermissionDecisionState.idle;
    final permissionSubmitting =
        permissionState == PermissionDecisionState.submitting;
    return Scaffold(
      appBar: AppBar(title: Text(question != null ? '待处理问题' : '待处理权限')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (readOnly && widget.lastSeenAt != null)
            _OfflineBanner(lastSeenAt: widget.lastSeenAt!),
          _DetailSection(
            title: '来源',
            children: [
              _DetailRow(label: '实例', value: interaction.machine),
              _DetailRow(label: '项目', value: interaction.project),
              _DetailRow(label: '目录', value: interaction.directory),
              _DetailRow(
                label: '会话',
                value: interaction.sessionTitle.isEmpty
                    ? interaction.sessionId
                    : '${interaction.sessionTitle}\n${interaction.sessionId}',
              ),
            ],
          ),
          if (question != null && readOnly)
            for (var index = 0; index < question.questions.length; index++)
              _ReadOnlyQuestion(
                index: index,
                question: question.questions[index],
              ),
          if (question != null && !readOnly) ...[
            for (var index = 0; index < question.questions.length; index++)
              _QuestionForm(
                index: index,
                question: question.questions[index],
                locked: locked,
                singleChoice: _singleChoice[index],
                multiChoice: _multiChoice[index],
                customController: _customControllers[index],
                onSingleChanged: (value) => _onSingleChanged(index, value),
                onMultiChanged: (label, checked) =>
                    _onMultiChanged(index, label, checked),
                onCustomChanged: () => _onCustomChanged(index),
              ),
            if (submitting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(
                  key: ValueKey('answer-submitting'),
                ),
              ),
            _SubmissionBanner(state: submission),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                key: const ValueKey('submit-answer'),
                onPressed: (answers != null && !locked)
                    ? () => _submit(question)
                    : null,
                icon: const Icon(Icons.send_outlined),
                label: const Text('提交回答'),
              ),
            ),
          ],
          if (permission != null) ...[
            _PermissionDetails(permission: permission),
            if (!readOnly) ...[
              _PermissionActions(
                state: permissionState,
                showAlwaysAllow: permission.always.isNotEmpty,
                onAllowOnce: () => _decide(permission, PermissionDecision.once),
                onAlwaysAllow: () => _showAlwaysConfirm(permission),
                onReject: () => _decide(permission, PermissionDecision.reject),
              ),
              if (permissionSubmitting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LinearProgressIndicator(
                    key: ValueKey('permission-submitting'),
                  ),
                ),
              _PermissionDecisionBanner(state: permissionState),
            ],
          ],
          if (interaction.tool case final tool?)
            _DetailSection(
              title: '工具来源',
              children: [
                _DetailRow(label: '消息', value: tool.messageId),
                _DetailRow(label: '调用', value: tool.callId),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuestionForm extends StatelessWidget {
  const _QuestionForm({
    required this.index,
    required this.question,
    required this.locked,
    required this.singleChoice,
    required this.multiChoice,
    required this.customController,
    required this.onSingleChanged,
    required this.onMultiChanged,
    required this.onCustomChanged,
  });

  final int index;
  final PendingQuestionItem question;
  final bool locked;
  final String? singleChoice;
  final Set<String> multiChoice;
  final TextEditingController customController;
  final ValueChanged<String?> onSingleChanged;
  final void Function(String label, bool checked) onMultiChanged;
  final VoidCallback onCustomChanged;

  @override
  Widget build(BuildContext context) {
    final hasCustom = customController.text.trim().isNotEmpty;
    return _DetailSection(
      title: question.header,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            question.question,
            key: ValueKey('question-$index'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (question.multiple)
          for (
            var optionIndex = 0;
            optionIndex < question.options.length;
            optionIndex++
          )
            CheckboxListTile(
              key: ValueKey('question-$index-option-$optionIndex'),
              value: multiChoice.contains(question.options[optionIndex].label),
              onChanged: locked
                  ? null
                  : (checked) => onMultiChanged(
                      question.options[optionIndex].label,
                      checked ?? false,
                    ),
              title: Text(question.options[optionIndex].label),
              subtitle: Text(question.options[optionIndex].description),
              controlAffinity: ListTileControlAffinity.leading,
            )
        else
          RadioGroup<String>(
            groupValue: hasCustom ? null : singleChoice,
            onChanged: (value) {
              if (!locked) onSingleChanged(value);
            },
            child: Column(
              children: [
                for (
                  var optionIndex = 0;
                  optionIndex < question.options.length;
                  optionIndex++
                )
                  RadioListTile<String>(
                    key: ValueKey('question-$index-option-$optionIndex'),
                    value: question.options[optionIndex].label,
                    title: Text(question.options[optionIndex].label),
                    subtitle: Text(question.options[optionIndex].description),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: TextField(
            key: ValueKey('question-$index-custom'),
            controller: customController,
            enabled: !locked,
            onChanged: (_) => onCustomChanged(),
            decoration: InputDecoration(
              labelText: '自定义回答',
              helperText: question.multiple ? '附加在所选选项之后' : '选择选项或输入自定义回答',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyQuestion extends StatelessWidget {
  const _ReadOnlyQuestion({required this.index, required this.question});

  final int index;
  final PendingQuestionItem question;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: question.header,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            question.question,
            key: ValueKey('question-$index'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        for (
          var optionIndex = 0;
          optionIndex < question.options.length;
          optionIndex++
        )
          _DetailRow(
            key: ValueKey('readonly-question-$index-option-$optionIndex'),
            label: question.options[optionIndex].label,
            value: question.options[optionIndex].description,
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.lastSeenAt});

  final DateTime lastSeenAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        key: const ValueKey('offline-banner'),
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('实例离线 · 状态未知 · 最后在线 ${_offlineElapsed(lastSeenAt)}'),
          ),
        ],
      ),
    );
  }
}

String _offlineElapsed(DateTime lastSeenAt) {
  final elapsed = DateTime.now().difference(lastSeenAt);
  if (elapsed.inSeconds < 60) return '刚刚在线';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}分钟前在线';
  return '${elapsed.inHours}小时前在线';
}

class _SubmissionBanner extends StatelessWidget {
  const _SubmissionBanner({required this.state});

  final QuestionSubmissionState state;

  @override
  Widget build(BuildContext context) {
    if (state == QuestionSubmissionState.idle) {
      return const SizedBox.shrink();
    }
    final (text, icon) = switch (state) {
      QuestionSubmissionState.idle => (null, null),
      QuestionSubmissionState.submitting => ('正在提交回答…', Icons.hourglass_top),
      QuestionSubmissionState.confirmed => (
        'OpenCode 已确认回答，请求已解除。',
        Icons.check_circle_outline,
      ),
      QuestionSubmissionState.stale => (
        '该问题已失效，可能已在其他设备处理。',
        Icons.history_toggle_off,
      ),
      QuestionSubmissionState.upstreamError => (
        '上游 OpenCode 返回错误，回答未被应用。',
        Icons.error_outline,
      ),
      QuestionSubmissionState.resultUnknown => (
        '结果未知，问题仍在等待回答。',
        Icons.help_outline,
      ),
      QuestionSubmissionState.handledElsewhere => (
        '该请求已在其他设备处理。',
        Icons.devices_other,
      ),
      QuestionSubmissionState.rejected => (
        '网关拒绝了该回答，请求可能已失效。',
        Icons.block_outlined,
      ),
    };
    return ListTile(
      key: const ValueKey('submission-result'),
      dense: true,
      leading: Icon(icon),
      title: Text(text!, textAlign: TextAlign.center),
    );
  }
}

class _PermissionActions extends StatelessWidget {
  const _PermissionActions({
    required this.state,
    required this.showAlwaysAllow,
    required this.onAllowOnce,
    required this.onAlwaysAllow,
    required this.onReject,
  });

  final PermissionDecisionState state;
  final bool showAlwaysAllow;
  final VoidCallback onAllowOnce;
  final VoidCallback onAlwaysAllow;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final locked =
        state == PermissionDecisionState.submitting ||
        state == PermissionDecisionState.confirmed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('permission-allow-once'),
                  onPressed: locked ? null : onAllowOnce,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('允许一次'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('permission-reject'),
                  onPressed: locked ? null : onReject,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('拒绝'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showAlwaysAllow)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              key: const ValueKey('permission-allow-always'),
              onPressed: locked ? null : onAlwaysAllow,
              icon: const Icon(Icons.save_outlined),
              label: const Text('始终允许'),
            ),
          ),
      ],
    );
  }
}

/// Confirmation for the always-allow decision. OpenCode saves the exact
/// patterns shown here and a matching command in a future session may be
/// authorized without asking. Nothing is submitted until [确认保存] is tapped;
/// [取消] leaves OpenCode untouched.
class _AlwaysConfirmDialog extends ConsumerStatefulWidget {
  const _AlwaysConfirmDialog({required this.permission});

  final PendingPermission permission;

  @override
  ConsumerState<_AlwaysConfirmDialog> createState() =>
      _AlwaysConfirmDialogState();
}

class _AlwaysConfirmDialogState extends ConsumerState<_AlwaysConfirmDialog> {
  bool _inFlight = false;

  Future<void> _confirm() async {
    if (_inFlight) return;
    setState(() => _inFlight = true);
    final navigator = Navigator.of(context);
    await ref
        .read(pendingInteractionsProvider.notifier)
        .decidePermission(
          permission: widget.permission,
          decision: PermissionDecision.always,
        );
    if (mounted) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = widget.permission;
    final state =
        ref.watch(permissionSubmissionStatesProvider)[permission.requestId] ??
        PermissionDecisionState.idle;
    final locked =
        _inFlight ||
        state == PermissionDecisionState.submitting ||
        state == PermissionDecisionState.confirmed;
    return AlertDialog(
      key: const ValueKey('permission-always-confirm'),
      title: const Text('始终允许'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('OpenCode 将保存以下规则，未来匹配的会话可能自动获得授权：'),
            ),
            for (var index = 0; index < permission.always.length; index++)
              ListTile(
                dense: true,
                leading: const Icon(Icons.save_outlined),
                title: SelectableText(
                  permission.always[index],
                  key: ValueKey('permission-always-confirm-pattern-$index'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('permission-always-cancel'),
          onPressed: _inFlight ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const ValueKey('permission-always-save'),
          onPressed: locked ? null : _confirm,
          child: const Text('确认保存'),
        ),
      ],
    );
  }
}

class _PermissionDecisionBanner extends StatelessWidget {
  const _PermissionDecisionBanner({required this.state});

  final PermissionDecisionState state;

  @override
  Widget build(BuildContext context) {
    if (state == PermissionDecisionState.idle) {
      return const SizedBox.shrink();
    }
    final (text, icon) = switch (state) {
      PermissionDecisionState.idle => (null, null),
      PermissionDecisionState.submitting => ('正在提交权限决定…', Icons.hourglass_top),
      PermissionDecisionState.confirmed => (
        'OpenCode 已确认决定，请求已解除。',
        Icons.check_circle_outline,
      ),
      PermissionDecisionState.stale => (
        '该权限请求已失效，可能已在其他设备处理。',
        Icons.history_toggle_off,
      ),
      PermissionDecisionState.upstreamError => (
        '上游 OpenCode 返回错误，决定未被应用。',
        Icons.error_outline,
      ),
      PermissionDecisionState.resultUnknown => (
        '结果未知，权限请求仍在等待。',
        Icons.help_outline,
      ),
      PermissionDecisionState.handledElsewhere => (
        '该请求已在其他设备处理。',
        Icons.devices_other,
      ),
      PermissionDecisionState.rejected => (
        '网关拒绝了该决定，请求可能已失效。',
        Icons.block_outlined,
      ),
    };
    return ListTile(
      key: const ValueKey('permission-decision-result'),
      dense: true,
      leading: Icon(icon),
      title: Text(text!, textAlign: TextAlign.center),
    );
  }
}

class _PermissionDetails extends StatelessWidget {
  const _PermissionDetails({required this.permission});

  final PendingPermission permission;

  @override
  Widget build(BuildContext context) {
    final metadata = const JsonEncoder.withIndent(
      '  ',
    ).convert(permission.metadata);
    return Column(
      children: [
        _DetailSection(
          title: '权限',
          children: [_DetailRow(label: '类型', value: permission.permission)],
        ),
        _DetailSection(
          title: '匹配范围',
          children: [
            for (var index = 0; index < permission.patterns.length; index++)
              _DetailRow(
                key: ValueKey('permission-pattern-$index'),
                label: 'Pattern',
                value: permission.patterns[index],
              ),
          ],
        ),
        _DetailSection(
          title: '永久允许范围',
          children: [
            for (var index = 0; index < permission.always.length; index++)
              _DetailRow(
                key: ValueKey('permission-always-$index'),
                label: 'Always',
                value: permission.always[index],
              ),
          ],
        ),
        _DetailSection(
          title: '元数据',
          children: [_DetailRow(label: 'Metadata', value: metadata)],
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      ...children,
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label),
    subtitle: SelectableText(value),
  );
}
