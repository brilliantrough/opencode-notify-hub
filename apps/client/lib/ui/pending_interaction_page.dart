import 'dart:convert';

import 'package:flutter/material.dart';

import '../pending/pending_interaction.dart';

class PendingInteractionPage extends StatelessWidget {
  const PendingInteractionPage({super.key, required this.interaction});

  final PendingInteraction interaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(interaction is PendingQuestion ? '待处理问题' : '待处理权限'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
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
          if (interaction case final PendingQuestion question)
            for (var index = 0; index < question.questions.length; index++)
              _QuestionSection(
                index: index,
                question: question.questions[index],
              ),
          if (interaction case final PendingPermission permission)
            _PermissionDetails(permission: permission),
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

class _QuestionSection extends StatelessWidget {
  const _QuestionSection({required this.index, required this.question});

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(question.multiple ? '可多选' : '单选')),
              if (question.custom) const Chip(label: Text('可自定义回答')),
            ],
          ),
        ),
        for (
          var optionIndex = 0;
          optionIndex < question.options.length;
          optionIndex++
        )
          ListTile(
            key: ValueKey('question-$index-option-$optionIndex'),
            title: Text(question.options[optionIndex].label),
            subtitle: Text(question.options[optionIndex].description),
          ),
      ],
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
