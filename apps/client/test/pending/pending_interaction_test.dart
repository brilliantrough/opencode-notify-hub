import 'package:client/pending/pending_interaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart' show PendingSnapshot, standardSerializers;

void main() {
  test(
    'maps generated question and permission variants without dropping context',
    () {
      final generated = standardSerializers.deserializeWith(
        PendingSnapshot.serializer,
        {
          'generatedAt': '2026-08-14T09:00:05.000Z',
          'interactions': [
            {
              'kind': 'question',
              'instanceId': '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
              'machine': 'devbox',
              'project': 'api',
              'directory': '/work/api',
              'sessionId': 'ses-1',
              'sessionTitle': 'Implement API',
              'requestId': 'question-1',
              'occurredAt': '2026-08-14T09:00:00.000Z',
              'tool': {'messageId': 'msg-1', 'callId': 'call-1'},
              'questions': [
                {
                  'header': 'Database',
                  'question': 'Which database?',
                  'options': [
                    {'label': 'Postgres', 'description': 'Production parity'},
                  ],
                  'multiple': false,
                  'custom': true,
                },
              ],
            },
            {
              'kind': 'permission',
              'instanceId': '6f0d91b0-93e4-43a9-9449-0bed03e651aa',
              'machine': 'devbox',
              'project': 'api',
              'directory': '/work/api',
              'sessionId': 'ses-2',
              'sessionTitle': 'Build release',
              'requestId': 'permission-1',
              'occurredAt': '2026-08-14T09:00:01.000Z',
              'permission': 'bash',
              'patterns': ['docker build .'],
              'always': ['docker build *'],
              'metadata': {
                'command': 'docker build .',
                'nested': {'path': '/work/api'},
              },
            },
          ],
        },
      )!;

      final interactions = generated.interactions
          .map(PendingInteraction.fromGenerated)
          .toList();
      final question = interactions.first as PendingQuestion;
      final permission = interactions.last as PendingPermission;

      expect(
        question.questions.single.options.single.description,
        'Production parity',
      );
      expect(question.tool!.callId, 'call-1');
      expect(permission.patterns, ['docker build .']);
      expect(permission.always, ['docker build *']);
      expect(permission.metadata['nested'], {'path': '/work/api'});
    },
  );
}
