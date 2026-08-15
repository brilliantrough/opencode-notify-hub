import 'dart:async';

import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/notifications/notification_intent.dart';
import 'package:client/notifications/notification_navigation.dart';
import 'package:client/pending/pending_controller.dart';
import 'package:client/pending/pending_interaction.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/realtime/notify_event.dart';
import 'package:client/ui/pending_interaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _authenticated = Authenticated(accessToken: 'token', email: 'a@b.c');

class MutableAuthController extends AuthController {
  MutableAuthController(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void replace(AuthState next) => state = next;
}

PendingQuestion question({String requestId = 'req-1'}) => PendingQuestion(
  instanceId: 'inst-1',
  machine: 'dev-box',
  project: 'shop-api',
  directory: '/work/shop-api',
  sessionId: 'ses-1',
  sessionTitle: 'Fix checkout',
  requestId: requestId,
  occurredAt: DateTime.utc(2026, 8, 14, 9),
  tool: null,
  questions: const [
    PendingQuestionItem(
      header: 'Database',
      question: 'Which database?',
      options: [
        PendingOption(label: 'PostgreSQL', description: 'Production parity'),
      ],
      multiple: false,
      custom: true,
    ),
  ],
);

PendingPermission permission({String requestId = 'req-1'}) => PendingPermission(
  instanceId: 'inst-1',
  machine: 'dev-box',
  project: 'shop-api',
  directory: '/work/shop-api',
  sessionId: 'ses-1',
  sessionTitle: 'Release build',
  requestId: requestId,
  occurredAt: DateTime.utc(2026, 8, 14, 9),
  tool: null,
  permission: 'bash',
  patterns: const ['docker build .'],
  always: const ['docker build *'],
  metadata: const {},
);

OpenCodeInstancePresence instance(
  InstancePresenceState state, {
  DateTime? lastSeenAt,
}) => OpenCodeInstancePresence(
  instanceId: 'inst-1',
  machine: 'dev-box',
  project: 'shop-api',
  directory: '/work/shop-api',
  openCodeVersion: '1.18.18',
  protocolVersion: 1,
  state: state,
  lastSeenAt: lastSeenAt ?? DateTime.utc(2026, 8, 14, 10),
);

NotificationTarget target(
  String requestId, {
  NotificationIntentKind kind = NotificationIntentKind.question,
}) => NotificationTarget(
  machine: 'dev-box',
  project: 'shop-api',
  directory: '/work/shop-api',
  requestId: requestId,
  kind: kind,
);

NotifyEvent questionEvent(String requestId) => NotifyEvent(
  eventId: 'evt-q',
  occurredAt: DateTime.utc(2026, 8, 14, 9, 5),
  machine: 'dev-box',
  project: 'shop-api',
  directory: '/work/shop-api',
  sessionId: 'ses-1',
  sessionTitle: 'Fix checkout',
  type: NotifyEventType.actionRequired,
  requestId: requestId,
  actionKind: ActionKind.question,
  questions: const [
    QuestionPrompt(
      text: 'Which database?',
      options: [QuestionOption(label: 'PostgreSQL')],
    ),
  ],
);

NotifyEvent providerActionEvent() => NotifyEvent(
  eventId: 'evt-pa',
  occurredAt: DateTime.utc(2026, 8, 14, 9, 5),
  machine: 'dev-box',
  project: 'shop-api',
  directory: '/work/shop-api',
  sessionId: 'ses-1',
  sessionTitle: 'Fix checkout',
  type: NotifyEventType.actionRequired,
  requestId: 'req-pa',
  actionKind: ActionKind.providerAction,
  providerActionMessage: 'complete in browser',
);

Future<ProviderContainer> pumpNavigation(
  WidgetTester tester, {
  required MutableAuthController auth,
  required GlobalKey<NavigatorState> navigatorKey,
  required Future<List<PendingInteraction>> Function() loader,
}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(() => auth),
      pendingInteractionLoaderProvider.overrideWithValue(() async {
        final loaded = await loader();
        return (interactions: loaded, queriedInstanceIds: null);
      }),
      appNavigatorKeyProvider.overrideWithValue(navigatorKey),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('工作台')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('saves the intent while unauthenticated and replays it once '
      'authenticated', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(const Unauthenticated());
    var loads = 0;
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async {
        loads++;
        return [question()];
      },
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.controllable),
    ]);

    final navigation = container.read(notificationNavigationProvider);
    await navigation.processTarget(target('req-1'));

    // The intent is stored and nothing resolved yet.
    expect(container.read(notificationIntentProvider), isNotNull);
    expect(loads, 0);
    expect(find.byType(PendingInteractionPage), findsNothing);

    // A session appearing replays the stored intent into the page.
    auth.replace(_authenticated);
    await navigation.processStoredIntent();
    await tester.pumpAndSettle();

    expect(find.byType(PendingInteractionPage), findsOneWidget);
    expect(container.read(notificationIntentProvider), isNull);
  });

  testWidgets('waits for the authoritative refresh before opening', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final gate = Completer<List<PendingInteraction>>();
    var loads = 0;
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async {
        loads++;
        return gate.future;
      },
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.controllable),
    ]);
    final navigation = container.read(notificationNavigationProvider);

    final process = navigation.processTarget(target('req-1'));
    await tester.pump();
    expect(loads, 1);
    expect(find.byType(PendingInteractionPage), findsNothing);

    gate.complete([question()]);
    await process;
    await tester.pumpAndSettle();

    expect(find.byType(PendingInteractionPage), findsOneWidget);
  });

  testWidgets('a controllable owning instance opens the interactive page', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => [question()],
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.controllable),
    ]);

    await container
        .read(notificationNavigationProvider)
        .processTarget(target('req-1'));
    await tester.pumpAndSettle();

    expect(find.byType(PendingInteractionPage), findsOneWidget);
    expect(find.byKey(const ValueKey('submit-answer')), findsOneWidget);
    expect(find.byKey(const ValueKey('offline-banner')), findsNothing);
    expect(container.read(notificationIntentProvider), isNull);
  });

  testWidgets(
    'a request already handled elsewhere shows the snackbar and stays on '
    'the workbench',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final auth = MutableAuthController(_authenticated);
      final container = await pumpNavigation(
        tester,
        auth: auth,
        navigatorKey: navigatorKey,
        loader: () async => const <PendingInteraction>[],
      );

      await container
          .read(notificationNavigationProvider)
          .processTarget(target('req-1'));
      await tester.pumpAndSettle();

      expect(find.text('该请求已被处理或不可用'), findsOneWidget);
      expect(find.byType(PendingInteractionPage), findsNothing);
      expect(container.read(notificationIntentProvider), isNull);
    },
  );

  testWidgets('an offline owning instance opens the read-only page', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final lastSeen = DateTime.utc(2026, 8, 14, 9, 55);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => [question()],
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.offline, lastSeenAt: lastSeen),
    ]);

    await container
        .read(notificationNavigationProvider)
        .processTarget(target('req-1'));
    await tester.pumpAndSettle();

    expect(find.byType(PendingInteractionPage), findsOneWidget);
    expect(find.textContaining('实例离线'), findsOneWidget);
    expect(find.byKey(const ValueKey('submit-answer')), findsNothing);
    expect(container.read(notificationIntentProvider), isNull);
  });

  testWidgets('a sync failure shows 同步失败 and clears the intent', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => throw StateError('sync exploded'),
    );

    await container
        .read(notificationNavigationProvider)
        .processTarget(target('req-1'));
    await tester.pumpAndSettle();

    expect(find.text('同步失败'), findsOneWidget);
    expect(find.byType(PendingInteractionPage), findsNothing);
    expect(container.read(notificationIntentProvider), isNull);
  });

  testWidgets('an unresolvable target fails safe with the snackbar', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => [permission()],
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.controllable),
    ]);

    // The snapshot only holds a permission, but the target is a question.
    await container
        .read(notificationNavigationProvider)
        .processTarget(target('req-1', kind: NotificationIntentKind.question));
    await tester.pumpAndSettle();

    expect(find.text('该请求已被处理或不可用'), findsOneWidget);
    expect(find.byType(PendingInteractionPage), findsNothing);
    expect(container.read(notificationIntentProvider), isNull);
  });

  testWidgets('a conflicting owning instance never opens the page', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => [question()],
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.conflicting),
    ]);

    await container
        .read(notificationNavigationProvider)
        .processTarget(target('req-1'));
    await tester.pumpAndSettle();

    expect(find.text('该请求已被处理或不可用'), findsOneWidget);
    expect(find.byType(PendingInteractionPage), findsNothing);
  });

  testWidgets('a provider-action click never stores or navigates', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => [question()],
    );

    final navigation = container.read(notificationNavigationProvider);
    navigation.onActionRequiredClick(providerActionEvent());
    await tester.pumpAndSettle();

    expect(container.read(notificationIntentProvider), isNull);
    expect(find.byType(PendingInteractionPage), findsNothing);
  });

  testWidgets('onActionRequiredClick deep-links a question event', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => [question()],
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.controllable),
    ]);

    container
        .read(notificationNavigationProvider)
        .onActionRequiredClick(questionEvent('req-1'));
    await tester.pumpAndSettle();

    expect(find.byType(PendingInteractionPage), findsOneWidget);
  });

  testWidgets('a newer click during resolution replaces the stale one', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final gate = Completer<List<PendingInteraction>>();
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () => gate.future,
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.controllable),
    ]);
    final navigation = container.read(notificationNavigationProvider);

    // First click starts resolving; the snapshot has not landed yet.
    final first = navigation.processTarget(target('req-1'));
    await tester.pump();
    // Second click arrives mid-resolution: it overwrites the intent slot.
    navigation.onActionRequiredClick(questionEvent('req-2'));

    // The snapshot contains only the second request.
    gate.complete([question(requestId: 'req-2')]);
    await first;
    await tester.pumpAndSettle();

    // The first target reports handled-elsewhere, then the second resolves.
    expect(find.byType(PendingInteractionPage), findsOneWidget);
    expect(find.text('Which database?'), findsOneWidget);
    expect(container.read(notificationIntentProvider), isNull);
  });

  testWidgets('tuple matching tolerates machine case and path drift', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final auth = MutableAuthController(_authenticated);
    final container = await pumpNavigation(
      tester,
      auth: auth,
      navigatorKey: navigatorKey,
      loader: () async => [question()],
    );
    container.read(instancePresencesProvider.notifier).replaceAll([
      instance(InstancePresenceState.controllable),
    ]);

    // The event tuple differs only by machine case, separator, and trailing
    // slash from the registered directory.
    await container
        .read(notificationNavigationProvider)
        .processTarget(
          const NotificationTarget(
            machine: 'DEV-BOX',
            project: 'shop-api',
            directory: '/work/shop-api/',
            requestId: 'req-1',
            kind: NotificationIntentKind.question,
          ),
        );
    await tester.pumpAndSettle();

    expect(find.byType(PendingInteractionPage), findsOneWidget);
  });
}
