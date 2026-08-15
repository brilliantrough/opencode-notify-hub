import 'package:client/notifications/notification_intent.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

NotifyEvent _action({
  String eventId = 'evt-1',
  String? requestId = 'req-1',
  ActionKind kind = ActionKind.permission,
}) => NotifyEvent(
  eventId: eventId,
  occurredAt: DateTime.utc(2026, 1, 1, 12),
  machine: 'macbook',
  project: 'linewrite',
  directory: '/repo',
  sessionId: 'sess-1',
  sessionTitle: 'Fix login',
  type: NotifyEventType.actionRequired,
  requestId: requestId,
  actionKind: kind,
  permissionType: kind == ActionKind.permission ? 'filesystem' : null,
  providerActionMessage: kind == ActionKind.providerAction
      ? 'open browser'
      : null,
);

PendingQuestion question(String requestId) => PendingQuestion(
  instanceId: 'inst-1',
  machine: 'macbook',
  project: 'linewrite',
  directory: '/repo',
  sessionId: 'sess-1',
  sessionTitle: 'Fix login',
  requestId: requestId,
  occurredAt: DateTime.utc(2026, 1, 1, 12, 1),
  tool: null,
  questions: const [
    PendingQuestionItem(
      header: 'Database',
      question: 'Which database?',
      options: [],
      multiple: false,
      custom: true,
    ),
  ],
);

PendingPermission permission(String requestId) => PendingPermission(
  instanceId: 'inst-1',
  machine: 'macbook',
  project: 'linewrite',
  directory: '/repo',
  sessionId: 'sess-1',
  sessionTitle: 'Fix login',
  requestId: requestId,
  occurredAt: DateTime.utc(2026, 1, 1, 12, 1),
  tool: null,
  permission: 'bash',
  patterns: const ['docker build .'],
  always: const ['docker build *'],
  metadata: const {},
);

void main() {
  group('NotificationTarget.tryFromEvent', () {
    test('builds a question target from a question event', () {
      final target = NotificationTarget.tryFromEvent(
        _action(kind: ActionKind.question),
      );

      expect(target, isNotNull);
      expect(target!.kind, NotificationIntentKind.question);
      expect(target.machine, 'macbook');
      expect(target.project, 'linewrite');
      expect(target.directory, '/repo');
      expect(target.requestId, 'req-1');
    });

    test('builds a permission target from a permission event', () {
      final target = NotificationTarget.tryFromEvent(
        _action(kind: ActionKind.permission),
      );

      expect(target!.kind, NotificationIntentKind.permission);
    });

    test('returns null for a provider action event', () {
      expect(
        NotificationTarget.tryFromEvent(
          _action(kind: ActionKind.providerAction),
        ),
        isNull,
      );
    });

    test('returns null when the request id is missing', () {
      expect(
        NotificationTarget.tryFromEvent(
          _action(requestId: null, kind: ActionKind.question),
        ),
        isNull,
      );
    });

    test('returns null for non-action events', () {
      final heartbeat = NotifyEvent(
        eventId: 'evt-hb',
        occurredAt: DateTime.utc(2026, 1, 1, 12),
        machine: 'macbook',
        project: 'linewrite',
        directory: '/repo',
        sessionId: 'sess-1',
        sessionTitle: 'Fix login',
        type: NotifyEventType.heartbeat,
      );

      expect(NotificationTarget.tryFromEvent(heartbeat), isNull);
    });
  });

  group('NotificationTarget.matches', () {
    NotificationTarget target(NotificationIntentKind kind) =>
        NotificationTarget(
          machine: 'macbook',
          project: 'linewrite',
          directory: '/repo',
          requestId: 'req-1',
          kind: kind,
        );

    test('matches the owning question interaction', () {
      expect(
        target(NotificationIntentKind.question).matches(question('req-1')),
        isTrue,
      );
    });

    test('matches the owning permission interaction', () {
      expect(
        target(NotificationIntentKind.permission).matches(permission('req-1')),
        isTrue,
      );
    });

    test('rejects a request id mismatch', () {
      expect(
        target(NotificationIntentKind.question).matches(question('other')),
        isFalse,
      );
    });

    test('rejects a kind mismatch even with a shared tuple and request id', () {
      expect(
        target(NotificationIntentKind.question).matches(permission('req-1')),
        isFalse,
      );
      expect(
        target(NotificationIntentKind.permission).matches(question('req-1')),
        isFalse,
      );
    });
  });

  group('NotificationIntentStore', () {
    test('is empty by default and save/clear round-trips the single slot', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(notificationIntentProvider.notifier);
      final target = NotificationTarget(
        machine: 'macbook',
        project: 'linewrite',
        directory: '/repo',
        requestId: 'req-1',
        kind: NotificationIntentKind.question,
      );

      expect(container.read(notificationIntentProvider), isNull);
      expect(store.peek(), isNull);

      store.save(target);
      expect(store.peek(), same(target));
      expect(container.read(notificationIntentProvider), same(target));

      store.save(
        NotificationTarget(
          machine: 'laptop',
          project: 'blog',
          directory: '/blog',
          requestId: 'req-2',
          kind: NotificationIntentKind.permission,
        ),
      );
      expect(container.read(notificationIntentProvider)!.requestId, 'req-2');

      store.clear();
      expect(store.peek(), isNull);
      expect(container.read(notificationIntentProvider), isNull);
    });
  });
}
