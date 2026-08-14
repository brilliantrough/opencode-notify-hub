import 'package:client/history/notification_history.dart';
import 'package:client/notifications/notification_router.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/realtime/active_sessions.dart';
import 'package:client/realtime/event_deduper.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationService implements NotificationService {
  final List<NotifyRequest> shown = [];
  var initCalls = 0;
  var granted = true;

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  Future<void> show(NotifyRequest request) async {
    shown.add(request);
  }

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<void> openPermissionSettings() async {}
}

NotifyEvent _heartbeat({String eventId = 'evt-hb', String sessionId = 'sess-1'}) =>
    NotifyEvent(
      eventId: eventId,
      occurredAt: DateTime.utc(2026, 1, 1, 12),
      machine: 'macbook',
      project: 'linewrite',
      directory: '/repo',
      sessionId: sessionId,
      sessionTitle: 'Fix login',
      type: NotifyEventType.heartbeat,
      elapsedSeconds: 42,
    );

NotifyEvent _actionRequired({
  String eventId = 'evt-act',
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

NotifyEvent _terminal({String eventId = 'evt-term', String sessionId = 'sess-1'}) =>
    NotifyEvent(
      eventId: eventId,
      occurredAt: DateTime.utc(2026, 1, 1, 12, 5),
      machine: 'macbook',
      project: 'linewrite',
      directory: '/repo',
      sessionId: sessionId,
      sessionTitle: 'Fix login',
      type: NotifyEventType.terminal,
      outcome: TerminalOutcome.completed,
      elapsedSeconds: 300,
      summary: 'All done',
    );

NotifyEvent _actionResolved({
  String eventId = 'evt-res',
  String sessionId = 'sess-1',
  String requestId = 'req-1',
}) => NotifyEvent(
  eventId: eventId,
  occurredAt: DateTime.utc(2026, 1, 1, 12, 2),
  machine: 'macbook',
  project: 'linewrite',
  directory: '/repo',
  sessionId: sessionId,
  sessionTitle: 'Fix login',
  type: NotifyEventType.actionResolved,
  requestId: requestId,
  actionKind: ActionKind.permission,
);

late ProviderContainer container;
late FakeNotificationService service;
late InMemoryNotificationHistory history;
late NotificationRouter router;

var paused = false;
var soundEnabled = true;

ActiveSessions get sessions => container.read(activeSessionsProvider.notifier);
Map<String, ActiveSession> get sessionsState =>
    container.read(activeSessionsProvider);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    container = ProviderContainer();
    addTearDown(container.dispose);
    service = FakeNotificationService();
    history = InMemoryNotificationHistory();
    paused = false;
    soundEnabled = true;
    router = NotificationRouter(
      service: service,
      activeSessions: sessions,
      deduper: EventDeduper(),
      history: history,
      readSettings: () =>
          NotificationSettings(paused: paused, soundEnabled: soundEnabled),
    );
  });

  group('NotificationRouter heartbeat', () {
    test('upserts the active session without history, popup, or sound', () async {
      await router.handle(_heartbeat());

      final session = sessionsState['sess-1']!;
      expect(session.running, isTrue);
      expect(session.lastHeartbeatAt, DateTime.utc(2026, 1, 1, 12));
      expect(history.entries, isEmpty);
      expect(service.shown, isEmpty);
    });
  });

  group('NotificationRouter actionRequired', () {
    test('adds pending state, records history, and alerts', () async {
      await router.handle(_actionRequired());

      expect(sessionsState['sess-1']!.pendingRequestIds, {'req-1'});
      expect(history.entries, hasLength(1));
      expect(history.entries.single.eventId, 'evt-act');
      expect(service.shown, hasLength(1));
      final request = service.shown.single;
      expect(request.eventId, 'evt-act');
      expect(request.title, 'linewrite · macbook · 需要授权');
      expect(request.body, '请求权限：filesystem');
      expect(request.playSound, isTrue);
    });
  });

  group('NotificationRouter terminal', () {
    test('marks the session terminal, records history, and alerts', () async {
      await router.handle(_actionRequired());
      await router.handle(_terminal());

      final session = sessionsState['sess-1']!;
      expect(session.running, isFalse);
      expect(session.pendingRequestIds, isEmpty);
      expect(history.entries.map((e) => e.eventId), ['evt-term', 'evt-act']);
      expect(service.shown, hasLength(2));
      final request = service.shown.last;
      expect(request.eventId, 'evt-term');
      expect(request.title, 'linewrite · macbook · 任务已完成');
      expect(request.body, '用时 300 秒\nAll done');
      expect(request.playSound, isTrue);
    });
  });

  group('NotificationRouter actionResolved', () {
    test('clears the pending request silently', () async {
      await router.handle(_actionRequired());
      await router.handle(_actionResolved());

      expect(sessionsState['sess-1']!.pendingRequestIds, isEmpty);
      expect(sessionsState['sess-1']!.running, isTrue);
      // Only the action_required event left a trace.
      expect(history.entries.map((e) => e.eventId), ['evt-act']);
      expect(service.shown, hasLength(1));
      expect(service.shown.single.eventId, 'evt-act');
    });
  });

  group('NotificationRouter dedupe', () {
    test('a duplicate event ID is fully ignored', () async {
      await router.handle(_actionRequired());
      await router.handle(_actionRequired());

      expect(sessionsState['sess-1']!.pendingRequestIds, {'req-1'});
      expect(history.entries, hasLength(1));
      expect(service.shown, hasLength(1));
    });

    test('a duplicate heartbeat does not touch session state again', () async {
      await router.handle(_heartbeat());
      final before = sessionsState['sess-1']!;
      await router.handle(_heartbeat());

      expect(identical(sessionsState['sess-1'], before), isTrue);
    });
  });

  group('NotificationRouter cross-restart dedupe', () {
    test('an event already in persisted history is fully ignored after a '
        'simulated restart (fresh in-memory deduper)', () async {
      // Before the "restart": the event was recorded to persisted history.
      final before = await PrefsNotificationHistory.load();
      await before.add(
        HistoryEntry(
          eventId: 'evt-act',
          title: 'macbook · linewrite · action_required',
          body: 'Permission: filesystem',
          receivedAt: DateTime.utc(2026, 1, 1, 12, 1),
        ),
      );

      // After the "restart": fresh EventDeduper, history reloaded from disk.
      final reloaded = await PrefsNotificationHistory.load();
      final restartedRouter = NotificationRouter(
        service: service,
        activeSessions: sessions,
        deduper: EventDeduper(),
        history: reloaded,
        readSettings: () => const NotificationSettings(),
      );

      await restartedRouter.handle(_actionRequired());

      // No second popup, no second history entry, no session bookkeeping.
      expect(service.shown, isEmpty);
      expect(reloaded.entries, hasLength(1));
      expect(sessionsState['sess-1'], isNull);
    });

    test('a new event after a restart still alerts normally', () async {
      final before = await PrefsNotificationHistory.load();
      await before.add(
        HistoryEntry(
          eventId: 'evt-old',
          title: 'old',
          body: 'old',
          receivedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      final reloaded = await PrefsNotificationHistory.load();
      final restartedRouter = NotificationRouter(
        service: service,
        activeSessions: sessions,
        deduper: EventDeduper(),
        history: reloaded,
        readSettings: () => const NotificationSettings(),
      );

      await restartedRouter.handle(_actionRequired());

      expect(service.shown, hasLength(1));
      expect(reloaded.entries.map((e) => e.eventId), ['evt-act', 'evt-old']);
    });
  });

  group('NotificationRouter settings', () {
    test('paused notifications still record history but never alert', () async {
      paused = true;

      await router.handle(_actionRequired());
      await router.handle(_terminal());

      expect(history.entries.map((e) => e.eventId), ['evt-term', 'evt-act']);
      expect(service.shown, isEmpty);
      // Session bookkeeping is unaffected by the pause.
      expect(sessionsState['sess-1']!.running, isFalse);
    });

    test('sound-disabled alerts still show with playSound false', () async {
      soundEnabled = false;

      await router.handle(_actionRequired());

      expect(service.shown, hasLength(1));
      expect(service.shown.single.playSound, isFalse);
    });
  });
}
