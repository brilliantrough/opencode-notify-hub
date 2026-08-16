import 'package:client/pending/pending_answer.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_api/notify_api.dart'
    show PendingSnapshot, standardSerializers;

const orderedQuestions = [
  PendingQuestionItem(
    header: 'Database',
    question: 'Which database?',
    options: [
      PendingOption(label: 'PostgreSQL', description: 'Production parity'),
      PendingOption(label: 'SQLite', description: 'Fast local runs'),
    ],
    multiple: false,
    custom: true,
  ),
  PendingQuestionItem(
    header: 'Migration',
    question: 'What else should the migration do?',
    options: [
      PendingOption(label: 'Migrate data', description: 'Copy rows'),
      PendingOption(label: 'Add indexes', description: 'Speed queries'),
      PendingOption(label: 'Update docs', description: 'Refresh guides'),
    ],
    multiple: true,
    custom: true,
  ),
];

void main() {
  group('composeQuestionAnswers', () {
    test('builds an ordered answer set for every question', () {
      final answers = composeQuestionAnswers(
        questions: orderedQuestions,
        singleChoice: const ['PostgreSQL', null],
        multiChoice: const [
          <String>{},
          <String>{'Add indexes', 'Migrate data'},
        ],
        custom: const ['', 'Use read replicas'],
      );

      expect(answers, [
        ['PostgreSQL'],
        ['Migrate data', 'Add indexes', 'Use read replicas'],
      ]);
    });

    test('keeps multi-select options in upstream option order', () {
      final answers = composeQuestionAnswers(
        questions: orderedQuestions,
        singleChoice: const ['SQLite', null],
        multiChoice: const [
          <String>{},
          <String>{'Update docs', 'Migrate data'},
        ],
        custom: const ['', ''],
      );

      expect(answers, [
        ['SQLite'],
        ['Migrate data', 'Update docs'],
      ]);
    });

    test('a single custom answer is exclusive with option selection', () {
      final withCustom = composeQuestionAnswers(
        questions: orderedQuestions,
        singleChoice: const ['PostgreSQL', null],
        multiChoice: const [
          <String>{},
          <String>{'Migrate data'},
        ],
        custom: const ['MongoDB', ''],
      );

      expect(withCustom!.first, ['MongoDB']);
      expect(withCustom, [
        ['MongoDB'],
        ['Migrate data'],
      ]);
    });

    test('multi custom text accompanies the selected options', () {
      final answers = composeQuestionAnswers(
        questions: orderedQuestions,
        singleChoice: const ['PostgreSQL', null],
        multiChoice: const [
          <String>{},
          <String>{'Migrate data', 'Add indexes'},
        ],
        custom: const ['', 'Also refresh the seed script'],
      );

      expect(answers, [
        ['PostgreSQL'],
        ['Migrate data', 'Add indexes', 'Also refresh the seed script'],
      ]);
    });

    test('multi custom text alone is a valid answer', () {
      final answers = composeQuestionAnswers(
        questions: orderedQuestions,
        singleChoice: const ['PostgreSQL', null],
        multiChoice: const [<String>{}, <String>{}],
        custom: const ['', 'Just use the default migration'],
      );

      expect(answers, [
        ['PostgreSQL'],
        ['Just use the default migration'],
      ]);
    });

    test('returns null when any question is unanswered', () {
      expect(
        composeQuestionAnswers(
          questions: orderedQuestions,
          singleChoice: const ['PostgreSQL', null],
          multiChoice: const [<String>{}, <String>{}],
          custom: const ['', ''],
        ),
        isNull,
      );
      expect(
        composeQuestionAnswers(
          questions: orderedQuestions,
          singleChoice: const [null, null],
          multiChoice: const [
            <String>{},
            <String>{'Migrate data'},
          ],
          custom: const ['', ''],
        ),
        isNull,
      );
    });

    test('treats whitespace-only custom text as unanswered', () {
      expect(
        composeQuestionAnswers(
          questions: orderedQuestions,
          singleChoice: const [null, null],
          multiChoice: const [
            <String>{},
            <String>{'Migrate data'},
          ],
          custom: const ['   ', ''],
        ),
        isNull,
      );
    });
  });

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
