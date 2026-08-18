import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/pending/pending_controller.dart';
import 'package:client/sessions/session_prompt_controller.dart';

void main() {
  ProviderContainer container({required SessionPromptSender sender}) {
    final value = ProviderContainer(
      overrides: [
        sessionPromptSenderProvider.overrideWithValue(sender),
        commandIdGeneratorProvider.overrideWithValue(() => 'command-1'),
      ],
    );
    addTearDown(value.dispose);
    return value;
  }

  test('sends one prompt and reports the Gateway acceptance', () async {
    final calls = <Map<String, String>>[];
    final ref = container(
      sender:
          ({
            required instanceId,
            required sessionId,
            required commandId,
            required text,
          }) async {
            calls.add({
              'instanceId': instanceId,
              'sessionId': sessionId,
              'commandId': commandId,
              'text': text,
            });
            return true;
          },
    );

    await ref
        .read(sessionPromptStatesProvider.notifier)
        .send(
          instanceId: 'instance-1',
          sessionId: 'ses-1',
          text: 'Continue the work',
        );

    expect(
      ref.read(sessionPromptStatesProvider)['ses-1'],
      SessionPromptState.sent,
    );
    expect(calls, [
      {
        'instanceId': 'instance-1',
        'sessionId': 'ses-1',
        'commandId': 'command-1',
        'text': 'Continue the work',
      },
    ]);
  });

  test(
    'keeps a 4xx target rejection distinct from an unknown transport result',
    () async {
      final rejected = container(
        sender:
            ({
              required instanceId,
              required sessionId,
              required commandId,
              required text,
            }) async {
              throw DioException(
                requestOptions: RequestOptions(path: '/prompt'),
                response: Response(
                  requestOptions: RequestOptions(path: '/prompt'),
                  statusCode: 404,
                ),
              );
            },
      );
      await rejected
          .read(sessionPromptStatesProvider.notifier)
          .send(instanceId: 'instance-1', sessionId: 'ses-1', text: 'Continue');
      expect(
        rejected.read(sessionPromptStatesProvider)['ses-1'],
        SessionPromptState.rejected,
      );

      final unknown = container(
        sender:
            ({
              required instanceId,
              required sessionId,
              required commandId,
              required text,
            }) async {
              throw StateError('connection lost');
            },
      );
      await unknown
          .read(sessionPromptStatesProvider.notifier)
          .send(instanceId: 'instance-1', sessionId: 'ses-1', text: 'Continue');
      expect(
        unknown.read(sessionPromptStatesProvider)['ses-1'],
        SessionPromptState.unknown,
      );
    },
  );
}
