import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

NotifyEvent _heartbeat({
  String eventId = 'evt-1',
  String sessionId = 'sess-1',
  DateTime? occurredAt,
  String machine = 'macbook',
  String project = 'linewrite',
  String sessionTitle = 'Fix login',
}) => NotifyEvent(
  eventId: eventId,
  occurredAt: occurredAt ?? DateTime.utc(2026, 1, 1, 12),
  machine: machine,
  project: project,
  directory: '/repo',
  sessionId: sessionId,
  sessionTitle: sessionTitle,
  type: NotifyEventType.heartbeat,
  elapsedSeconds: 42,
);

NotifyEvent _actionRequired({
  String eventId = 'evt-2',
  String sessionId = 'sess-1',
  String requestId = 'req-1',
}) => NotifyEvent(
  eventId: eventId,
  occurredAt: DateTime.utc(2026, 1, 1, 12, 1),
  machine: 'macbook',
  project: 'linewrite',
  directory: '/repo',
  sessionId: sessionId,
  sessionTitle: 'Fix login',
  type: NotifyEventType.actionRequired,
  requestId: requestId,
  actionKind: ActionKind.permission,
  permissionType: 'filesystem',
);

late ProviderContainer container;
late ActiveSessions sessions;

Map<String, ActiveSession> get state => container.read(activeSessionsProvider);

void main() {
  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    sessions = container.read(activeSessionsProvider.notifier);
  });

  group('ActiveSessions.upsertHeartbeat', () {
    test('creates a running session from the first heartbeat', () {
      sessions.upsertHeartbeat(_heartbeat());

      final session = state['sess-1']!;
      expect(session.machine, 'macbook');
      expect(session.project, 'linewrite');
      expect(session.title, 'Fix login');
      expect(session.lastHeartbeatAt, DateTime.utc(2026, 1, 1, 12));
      expect(session.running, isTrue);
      expect(session.pendingRequestIds, isEmpty);
    });

    test('updates heartbeat time and identity of an existing session', () {
      sessions.upsertHeartbeat(_heartbeat());
      sessions.addPending(_actionRequired());
      sessions.upsertHeartbeat(
        _heartbeat(
          eventId: 'evt-3',
          occurredAt: DateTime.utc(2026, 1, 1, 12, 5),
          sessionTitle: 'Renamed session',
        ),
      );

      expect(state, hasLength(1));
      final session = state['sess-1']!;
      expect(session.lastHeartbeatAt, DateTime.utc(2026, 1, 1, 12, 5));
      expect(session.title, 'Renamed session');
      expect(session.running, isTrue);
      expect(session.pendingRequestIds, {'req-1'});
    });

    test('tracks sessions independently by session ID', () {
      sessions.upsertHeartbeat(_heartbeat());
      sessions.upsertHeartbeat(_heartbeat(eventId: 'evt-4', sessionId: 'sess-2'));

      expect(state.keys, containsAll(['sess-1', 'sess-2']));
    });
  });

  group('ActiveSessions.addPending', () {
    test('creates the session when it does not exist yet', () {
      sessions.addPending(_actionRequired());

      final session = state['sess-1']!;
      expect(session.running, isTrue);
      expect(session.pendingRequestIds, {'req-1'});
    });

    test('accumulates distinct pending request IDs', () {
      sessions.addPending(_actionRequired());
      sessions.addPending(_actionRequired(eventId: 'evt-3', requestId: 'req-2'));

      expect(state['sess-1']!.pendingRequestIds, {'req-1', 'req-2'});
    });
  });

  group('ActiveSessions.clearPending', () {
    test('removes only the resolved request ID', () {
      sessions.addPending(_actionRequired());
      sessions.addPending(_actionRequired(eventId: 'evt-3', requestId: 'req-2'));

      sessions.clearPending('sess-1', 'req-1');

      expect(state['sess-1']!.pendingRequestIds, {'req-2'});
      expect(state['sess-1']!.running, isTrue);
    });

    test('is a no-op for an unknown session', () {
      sessions.clearPending('nope', 'req-1');

      expect(state, isEmpty);
    });
  });

  group('ActiveSessions.markTerminal', () {
    test('marks the session not running and clears pending requests', () {
      sessions.addPending(_actionRequired());
      sessions.markTerminal('sess-1');

      final session = state['sess-1']!;
      expect(session.running, isFalse);
      expect(session.pendingRequestIds, isEmpty);
    });

    test('is a no-op for an unknown session', () {
      sessions.markTerminal('nope');

      expect(state, isEmpty);
    });
  });
}
