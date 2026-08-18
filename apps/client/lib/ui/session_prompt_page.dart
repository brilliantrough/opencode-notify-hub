import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../realtime/active_sessions.dart';
import '../realtime/instance_presence.dart';
import '../sessions/session_prompt_controller.dart';

class SessionPromptPage extends ConsumerStatefulWidget {
  const SessionPromptPage({
    super.key,
    required this.session,
    required this.target,
  });

  final ActiveSession session;
  final OpenCodeInstancePresence target;

  @override
  ConsumerState<SessionPromptPage> createState() => _SessionPromptPageState();
}

class _SessionPromptPageState extends ConsumerState<SessionPromptPage> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await ref
        .read(sessionPromptStatesProvider.notifier)
        .send(
          instanceId: widget.target.instanceId,
          sessionId: widget.session.sessionId,
          text: text,
        );
    if (mounted &&
        ref.read(sessionPromptStatesProvider)[widget.session.sessionId] ==
            SessionPromptState.sent) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(sessionPromptStatesProvider)[widget.session.sessionId] ??
        SessionPromptState.idle;
    final sending = state == SessionPromptState.sending;
    final locked = sending;
    return Scaffold(
      appBar: AppBar(title: const Text('发送到 OpenCode')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            widget.session.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.session.machine} · ${widget.session.project}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            widget.session.sessionId,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('session-prompt-input'),
            controller: _textController,
            enabled: !locked,
            autofocus: true,
            minLines: 4,
            maxLines: 12,
            maxLength: 32000,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '输入要发送的内容',
              alignLabelWithHint: true,
            ),
          ),
          if (sending) const LinearProgressIndicator(),
          if (state != SessionPromptState.idle && !sending)
            _PromptStatus(state: state),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('send-session-prompt'),
            onPressed: locked ? null : _send,
            icon: const Icon(Icons.send_outlined),
            label: const Text('发送'),
          ),
        ],
      ),
    );
  }
}

class _PromptStatus extends StatelessWidget {
  const _PromptStatus({required this.state});

  final SessionPromptState state;

  @override
  Widget build(BuildContext context) {
    final (text, icon, color) = switch (state) {
      SessionPromptState.sent => (
        '命令已交给 OpenCode Plugin，等待会话更新。',
        Icons.send_outlined,
        null,
      ),
      SessionPromptState.rejected => (
        '目标实例不可用，内容没有发送。',
        Icons.block_outlined,
        Theme.of(context).colorScheme.error,
      ),
      SessionPromptState.unknown => (
        '发送结果未知，请检查 OpenCode，不会自动重试。',
        Icons.help_outline,
        Theme.of(context).colorScheme.error,
      ),
      _ => ('', Icons.info_outline, null),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: color == null ? null : TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
