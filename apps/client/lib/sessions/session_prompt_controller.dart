import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart' show SendPromptBody, SessionsApi;

import '../auth/auth_controller.dart';
import '../pending/pending_controller.dart';

final sessionsApiProvider = Provider<SessionsApi>(
  (ref) => ref.watch(apiClientProvider).notifyApi.getSessionsApi(),
);

typedef SessionPromptSender =
    Future<bool> Function({
      required String instanceId,
      required String sessionId,
      required String commandId,
      required String text,
    });

final sessionPromptSenderProvider = Provider<SessionPromptSender>((ref) {
  final api = ref.watch(sessionsApiProvider);
  return ({
    required instanceId,
    required sessionId,
    required commandId,
    required text,
  }) async {
    final response = await api.sendSessionPrompt(
      instanceId: instanceId,
      sessionId: sessionId,
      sendPromptBody: SendPromptBody((builder) {
        builder
          ..commandId = commandId
          ..text = text;
      }),
    );
    return response.data != null;
  };
});

enum SessionPromptState { idle, sending, sent, rejected, unknown }

final sessionPromptStatesProvider =
    NotifierProvider<SessionPromptStates, Map<String, SessionPromptState>>(
      SessionPromptStates.new,
    );

class SessionPromptStates extends Notifier<Map<String, SessionPromptState>> {
  @override
  Map<String, SessionPromptState> build() => const {};

  Future<void> send({
    required String instanceId,
    required String sessionId,
    required String text,
  }) async {
    final commandId = ref.read(commandIdGeneratorProvider)();
    _mark(sessionId, SessionPromptState.sending);
    try {
      final accepted = await ref.read(sessionPromptSenderProvider)(
        instanceId: instanceId,
        sessionId: sessionId,
        commandId: commandId,
        text: text,
      );
      if (!accepted) {
        _mark(sessionId, SessionPromptState.unknown);
      } else {
        _mark(sessionId, SessionPromptState.sent);
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      _mark(
        sessionId,
        statusCode != null && statusCode >= 400 && statusCode < 500
            ? SessionPromptState.rejected
            : SessionPromptState.unknown,
      );
    } catch (_) {
      _mark(sessionId, SessionPromptState.unknown);
    }
  }

  void reset(String sessionId) {
    final next = Map<String, SessionPromptState>.from(state)..remove(sessionId);
    state = next;
  }

  void _mark(String sessionId, SessionPromptState value) {
    state = {...state, sessionId: value};
  }
}
