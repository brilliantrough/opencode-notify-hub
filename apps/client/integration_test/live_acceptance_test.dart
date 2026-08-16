import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:client/app.dart';
import 'package:client/auth/auth_controller.dart';
import 'package:client/auth/auth_state.dart';
import 'package:client/auth/credentials_store.dart';
import 'package:client/bootstrap.dart';
import 'package:client/config/app_config.dart';
import 'package:client/config/server_config.dart';
import 'package:client/history/notification_history.dart';
import 'package:client/ingest_keys/ingest_keys_controller.dart';
import 'package:client/notifications/notification_service.dart';
import 'package:client/realtime/instance_presence.dart';
import 'package:client/realtime/realtime_controller.dart' show notificationHistoryProvider;
import 'package:client/ui/login_page.dart';
import 'package:client/ui/pending_interaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ---------------------------------------------------------------------------
// Compile-time environment (set by scripts/beta/closed-loop.sh).
// ---------------------------------------------------------------------------

const _liveGatewayUrl = String.fromEnvironment('LIVE_GATEWAY_URL');
const _mailboxPath = String.fromEnvironment('MAILBOX_PATH');
const _gatewayLog = String.fromEnvironment('GATEWAY_LOG');
const _opencodePort = String.fromEnvironment('OPENCODE_PORT');
const _providerBaseUrl = String.fromEnvironment('PROVIDER_BASE_URL');
const _opencodeBin = String.fromEnvironment('OPENCODE_BIN');
const _pluginDist = String.fromEnvironment('PLUGIN_DIST');
const _opencodeLog = String.fromEnvironment('OPENCODE_LOG');
const _notifyDaemon = String.fromEnvironment('NOTIFY_DAEMON');
const _tsxBin = String.fromEnvironment('TSX_BIN');

// Fixture sentinels shared with scripts/beta/fake-provider.mjs.
const _marker = 'LIVE_Q_CLOSED_LOOP';
const _questionSentinel =
    'CLOSED_LOOP_QUESTION Which transport should the live acceptance closed loop use?';
const _answerSentinel = 'CLOSED_LOOP_ANSWER WebSocket';

/// Records shown alerts instead of touching the platform notification stack.
/// The real WS delivery + UI navigation are what the live loop proves; the
/// OS popup itself stays stubbed.
class RecordingNotificationService implements NotificationService {
  final List<NotifyRequest> shown = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> show(NotifyRequest request) async {
    shown.add(request);
  }

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}
}

/// Pumps until [condition] is true or [timeout] elapses. Real async I/O
/// (HTTP, files, processes) keeps running between pumps.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
  await tester.pump();
}

Future<void> pumpUntilAsync(
  WidgetTester tester,
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('async condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Plain HTTP helpers (dart:io) against the real gateway and the real opencode.
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _postJson(
  HttpClient client,
  String url,
  Map<String, dynamic> body, {
  String? bearer,
}) async {
  client.connectionTimeout = const Duration(seconds: 5);
  final request = await client
      .postUrl(Uri.parse(url))
      .timeout(const Duration(seconds: 10));
  request.headers.contentType = ContentType.json;
  if (bearer != null) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
  }
  request.write(jsonEncode(body));
  final response = await request.close().timeout(const Duration(seconds: 10));
  final text = await utf8.decoder
      .bind(response)
      .join()
      .timeout(const Duration(seconds: 10));
  if (response.statusCode >= 300) {
    throw HttpException('POST $url -> ${response.statusCode} $text');
  }
  return text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _getJson(
  HttpClient client,
  String url, {
  String? bearer,
}) async {
  client.connectionTimeout = const Duration(seconds: 5);
  final request = await client
      .getUrl(Uri.parse(url))
      .timeout(const Duration(seconds: 10));
  if (bearer != null) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
  }
  final response = await request.close().timeout(const Duration(seconds: 10));
  final text = await utf8.decoder
      .bind(response)
      .join()
      .timeout(const Duration(seconds: 10));
  if (response.statusCode >= 300) {
    throw HttpException('GET $url -> ${response.statusCode} $text');
  }
  return text.isEmpty ? <String, dynamic>{} : jsonDecode(text) as Map<String, dynamic>;
}

/// Waits for the 8-character verification code the gateway's mailbox mailer
/// appended for [email].
Future<String> _readVerificationCode(String path, String email) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    final file = File(path);
    if (file.existsSync()) {
      for (final line in file.readAsLinesSync()) {
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          if (map['to'] == email && map['kind'] == 'verify') {
            final code = map['code'];
            if (code is String && code.length == 8) {
              return code;
            }
          }
        } catch (_) {
          // Skip malformed lines; keep polling.
        }
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('verification code never appeared for $email in $path');
}

/// Registers a fresh account through the real gateway HTTP API, reads the
/// one-time code from the mailbox file, verifies, and logs in. Returns the
/// access token (used for the later direct gateway assertions).
Future<String> _registerAndLogin(
  HttpClient client,
  String gatewayUrl,
  String mailboxPath,
  String email,
  String password,
) async {
  await _postJson(client, '$gatewayUrl/v1/auth/register', {
    'email': email,
    'password': password,
  });
  final code = await _readVerificationCode(mailboxPath, email);
  await _postJson(client, '$gatewayUrl/v1/auth/verify-email', {
    'email': email,
    'code': code,
  });
  final pair = await _postJson(client, '$gatewayUrl/v1/auth/login', {
    'email': email,
    'password': password,
  });
  final token = pair['accessToken'];
  if (token is! String || token.isEmpty) {
    throw StateError('login did not return an access token: $pair');
  }
  return token;
}

// ---------------------------------------------------------------------------
// Real opencode HTTP (V2 SDK wire shape: bare /api/... paths).
// ---------------------------------------------------------------------------

Future<void> _waitOcHealthy(String base) async {
  final client = HttpClient();
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final health = await _getJson(client, '$base/api/health');
      if (health['healthy'] == true) return;
    } on HttpException {
      // not up yet
    } on SocketException {
      // not up yet
    } on TimeoutException {
      // not up yet
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('opencode serve never became healthy at $base');
}

/// Waits until the `livefake` provider is resolvable (the first
/// directory-scoped request against opencode).
Future<void> _waitOcProviderReady(String base) async {
  final client = HttpClient();
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final body = await _getJson(client, '$base/api/provider');
      final data = body['data'];
      if (data is List &&
          data.any((entry) => entry is Map<String, dynamic> && entry['id'] == 'livefake')) {
        return;
      }
    } on HttpException {
      // provider list not ready yet
    } on SocketException {
      // server not reachable yet
    } on TimeoutException {
      // not ready yet
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('livefake provider never became available at $base');
}

Future<String> _createOcSession(String base, String directory) async {
  final client = HttpClient();
  final body = await _postJson(client, '$base/api/session', {
    'agent': 'build',
    'model': {'id': 'live-model', 'providerID': 'livefake'},
    'location': {'directory': directory},
  });
  final data = body['data'];
  final id = data is Map<String, dynamic> ? data['id'] : null;
  if (id is! String || id.isEmpty) {
    throw StateError('opencode session create failed: $body');
  }
  return id;
}

Future<void> _promptMarker(String base, String sessionId) async {
  final client = HttpClient();
  await _postJson(client, '$base/api/session/$sessionId/prompt', {
    'prompt': {'text': _marker},
  });
}

/// `GET /api/question/request?location[directory]=...` — the location-scoped
/// pending-question list (the plugin's read path).
Future<List<dynamic>> _ocQuestionRequests(String base, String directory) async {
  final client = HttpClient();
  final url = '$base/api/question/request?location[directory]='
      '${Uri.encodeQueryComponent(directory)}';
  final body = await _getJson(client, url);
  final data = body['data'];
  return data is List ? data : <dynamic>[];
}

/// `GET /api/session/{sessionID}/message?order=asc` — asserts the question
/// tool completed with exactly the submitted answers.
Future<Map<String, dynamic>> _ocQuestionToolState(
  String base,
  String sessionId,
) async {
  final client = HttpClient();
  final body = await _getJson(client, '$base/api/session/$sessionId/message?order=asc');
  final messages = body['data'];
  if (messages is! List) {
    throw StateError('unexpected messages payload: $body');
  }
  for (final message in messages) {
    if (message is! Map<String, dynamic> || message['type'] != 'assistant') continue;
    final content = message['content'];
    if (content is! List) continue;
    for (final part in content) {
      if (part is! Map<String, dynamic>) continue;
      if (part['type'] == 'tool' && part['name'] == 'question') {
        final state = part['state'];
        if (state is Map<String, dynamic>) return state;
      }
    }
  }
  throw StateError('question tool part not found in session messages');
}

// ---------------------------------------------------------------------------
// The live closed loop
// ---------------------------------------------------------------------------

Future<void> _runLiveLoop(WidgetTester tester) async {
  final gatewayUrl = _liveGatewayUrl;
  final mailboxPath = _mailboxPath;
  final gatewayLogPath = _gatewayLog;
  final providerBaseUrl = _providerBaseUrl;
  final opencodePort = int.tryParse(_opencodePort) ?? 0;
  if (opencodePort == 0) throw StateError('invalid OPENCODE_PORT: $_opencodePort');

  final client = HttpClient();
  addTearDown(client.close);

  // ---- 1. Register a synthetic user through the REAL gateway HTTP API,
  //        reading the 8-char code from the mailbox file.
  final email = 'live-${DateTime.now().millisecondsSinceEpoch}@beta.local';
  final password = 'LiveLoopPassw0rd!';
  debugPrint('[live-loop] registering $email through the real gateway');
  final accessToken = await _registerAndLogin(client, gatewayUrl, mailboxPath, email, password);
  debugPrint('[live-loop] registered + verified + logged in via gateway API');

  // ---- 2. Boot the REAL desktop UI against the live gateway with no stored
  //         credentials, then log in through the REAL login page.
  final notifications = RecordingNotificationService();
  final store = InMemoryCredentialsStore();
  final bootstrap = await AppBootstrap.initialize(
    notificationService: notifications,
    initDesktopWindowing: false,
    extraOverrides: [
      appConfigProvider.overrideWithValue(AppConfig(gatewayHttpBase: gatewayUrl)),
      credentialsStoreProvider.overrideWithValue(store),
      notificationHistoryProvider.overrideWithValue(InMemoryNotificationHistory()),
    ],
  );
  final container = ProviderContainer(overrides: bootstrap.overrides);
  addTearDown(bootstrap.shutdown);
  bootstrap.attach(container);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NotifyApp()),
  );
  await tester.pump();
  await pumpUntil(
    tester,
    () => find.byKey(LoginPage.emailFieldKey).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 15),
  );
  expect(container.read(authControllerProvider), isA<Unauthenticated>());

  // Fill the real login form. The desktop integration binding can drop an
  // early keystroke during focus transitions, so retry until both fields
  // actually hold their values (verified through their controllers).
  var filled = false;
  for (var attempt = 0; attempt < 5 && !filled; attempt++) {
    await tester.showKeyboard(find.byKey(LoginPage.emailFieldKey));
    await tester.pump();
    await tester.enterText(find.byKey(LoginPage.emailFieldKey), email);
    await tester.pump();
    await tester.showKeyboard(find.byKey(LoginPage.passwordFieldKey));
    await tester.pump();
    await tester.enterText(find.byKey(LoginPage.passwordFieldKey), password);
    await tester.pump();
    final probeEmail =
        tester.widget<TextField>(find.byKey(LoginPage.emailFieldKey)).controller?.text;
    final probePassword =
        tester.widget<TextField>(find.byKey(LoginPage.passwordFieldKey)).controller?.text;
    debugPrint('[live-loop] form fill attempt ${attempt + 1}: email="$probeEmail", '
        'password=${probePassword == null ? 'null' : '${probePassword.length} chars'}');
    if (probeEmail == email && probePassword == password) {
      filled = true;
    }
  }
  expect(filled, isTrue, reason: 'the real login form must hold both fields');

  await pumpUntil(
    tester,
    () => tester.widget<FilledButton>(find.byKey(LoginPage.submitKey)).onPressed != null,
    timeout: const Duration(seconds: 10),
  );
  var loggedIn = false;
  for (var attempt = 0; attempt < 3 && !loggedIn; attempt++) {
    if (tester.widget<FilledButton>(find.byKey(LoginPage.submitKey)).onPressed != null) {
      await tester.tap(find.byKey(LoginPage.submitKey));
      await tester.pump();
    }
    final submitDeadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(submitDeadline) && !loggedIn) {
      if (container.read(authControllerProvider) is Authenticated) {
        loggedIn = true;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
  }
  expect(loggedIn, isTrue, reason: 'the real login UI must reach Authenticated');
  debugPrint('[live-loop] logged in through the REAL login page UI');

  // ---- 3. Create an ingest key through the real gateway API (the notify
  //         daemon uses its one-time `keyId.secret` credential).
  final created = await container.read(ingestKeysControllerProvider.notifier).create('live-loop');
  final credential = created.secret; // already `keyId.secret`
  debugPrint('[live-loop] created ingest key ${created.id}');

  // ---- 4. Prepare an isolated opencode project + XDG home and spawn the
  //         REAL `opencode serve` with the fake-provider model config, plus
  //         the notify daemon that reproduces the plugin's external wire
  //         contract (see docs/beta-evidence/README.md for why).
  final projectDir = await Directory.systemTemp.createTemp('notify-live-project-');
  final xdgDir = await Directory.systemTemp.createTemp('notify-live-xdg-');
  final homeDir = await Directory.systemTemp.createTemp('notify-live-home-');
  addTearDown(() => projectDir.delete(recursive: true));
  addTearDown(() => xdgDir.delete(recursive: true));
  addTearDown(() => homeDir.delete(recursive: true));

  final pluginsDir = Directory('${projectDir.path}/.opencode/plugins')..createSync(recursive: true);
  File(_pluginDist).copySync('${pluginsDir.path}/session-notify.js');
  final configDir = Directory('${xdgDir.path}/opencode')..createSync(recursive: true);
  File('${configDir.path}/opencode.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      r'$schema': 'https://opencode.ai/config.json',
      'permission': 'allow',
      'provider': {
        'livefake': {
          'npm': '@ai-sdk/openai-compatible',
          'name': 'Live Fake',
          'options': {'baseURL': providerBaseUrl, 'apiKey': 'live-test'},
          'models': {'live-model': {'name': 'Live Model'}},
        },
      },
    }),
  );

  final ocEnv = Map<String, String>.from(Platform.environment)
    ..removeWhere((key, _) => key.startsWith('NOTIFY_'))
    ..['NOTIFY_GATEWAY_URL'] = gatewayUrl
    ..['NOTIFY_INGEST_KEY'] = credential
    ..['NOTIFY_IDLE_DEBOUNCE_MS'] = '5000'
    ..['NOTIFY_HEARTBEAT_MS'] = '30000'
    ..['NOTIFY_HTTP_TIMEOUT_MS'] = '3000'
    ..['NOTIFY_MAX_RETRIES'] = '1'
    ..['HOME'] = homeDir.path
    ..['XDG_CONFIG_HOME'] = xdgDir.path
    ..['XDG_DATA_HOME'] = '${homeDir.path}/.local/share'
    ..['XDG_CACHE_HOME'] = '${homeDir.path}/.cache'
    ..['OPENCODE_DISABLE_AUTOUPDATE'] = '1'
    ..['NO_PROXY'] = 'localhost,127.0.0.1,::1'
    ..['no_proxy'] = 'localhost,127.0.0.1,::1';

  final ocBase = 'http://127.0.0.1:$opencodePort';
  final ocLogFile = File(_opencodeLog);
  final ocLogSink = ocLogFile.openWrite();
  debugPrint('[live-loop] spawning opencode serve on :$opencodePort');
  final ocProc = await Process.start(
    _opencodeBin,
    [
      'serve',
      '--hostname',
      '127.0.0.1',
      '--port',
      '$opencodePort',
      '--print-logs',
      '--log-level',
      'DEBUG',
    ],
    environment: ocEnv,
    workingDirectory: projectDir.path,
  );
  addTearDown(() async {
    try {
      ocProc.kill();
    } catch (_) {}
    await ocLogSink.flush();
    await ocLogSink.close();
  });
  ocProc.stdout.transform(utf8.decoder).listen(ocLogSink.write);
  ocProc.stderr.transform(utf8.decoder).listen(ocLogSink.write);

  await _waitOcHealthy(ocBase);
  debugPrint('[live-loop] opencode healthy at $ocBase');

  // The first directory-scoped request (provider readiness poll) is what
  // makes opencode load the project plugin module (lazy loading); it also
  // lets the model turn resolve before the marker prompt fires.
  await _waitOcProviderReady(ocBase);
  debugPrint('[live-loop] fake provider ready (directory-scoped request ran)');

  // ---- 4b. Spawn the notify daemon: no 1.18.18 launch mode exposes the
  //          pending-question store to the plugin's serverUrl (see
  //          docs/beta-evidence/README.md), so this daemon reproduces the
  //          plugin's external wire contract — real control channel to the
  //          gateway + real opencode SSE event delivery — using the
  //          production plugin modules.
  final daemonLog = File('$_opencodeLog.daemon');
  final daemonSink = daemonLog.openWrite();
  final daemonEnv = Map<String, String>.from(Platform.environment)
    ..removeWhere((key, _) => key.startsWith('NOTIFY_'))
    ..['NOTIFY_GATEWAY_URL'] = gatewayUrl
    ..['NOTIFY_INGEST_KEY'] = credential
    ..['NOTIFY_IDLE_DEBOUNCE_MS'] = '5000'
    ..['NOTIFY_HEARTBEAT_MS'] = '30000'
    ..['NOTIFY_HTTP_TIMEOUT_MS'] = '3000'
    ..['NOTIFY_MAX_RETRIES'] = '1'
    ..['OPENCODE_BASE_URL'] = ocBase
    ..['NOTIFY_DIRECTORY'] = projectDir.path
    ..['NOTIFY_MACHINE'] = 'live-loop-host'
    ..['NO_PROXY'] = 'localhost,127.0.0.1,::1'
    ..['no_proxy'] = 'localhost,127.0.0.1,::1';
  debugPrint('[live-loop] spawning notify-daemon against $ocBase');
  final daemonProc = await Process.start(
    _tsxBin,
    [_notifyDaemon],
    environment: daemonEnv,
  );
  addTearDown(() async {
    try {
      daemonProc.kill();
    } catch (_) {}
    await daemonSink.flush();
    await daemonSink.close();
  });
  daemonProc.stdout.transform(utf8.decoder).listen(daemonSink.write);
  daemonProc.stderr.transform(utf8.decoder).listen(daemonSink.write);
  // Give the daemon a beat to subscribe to the SSE stream and register the
  // control channel before the question fires.
  await Future<void>.delayed(const Duration(seconds: 2));

  // ---- 5. Trigger the marker question through the real opencode API.
  final sessionId = await _createOcSession(ocBase, projectDir.path);
  debugPrint('[live-loop] session $sessionId created on the real opencode');
  await _promptMarker(ocBase, sessionId);

  // The question must actually be pending on the real opencode before we
  // wait on anything control-channel-gated.
  await pumpUntilAsync(
    tester,
    () async => (await _ocQuestionRequests(ocBase, projectDir.path)).isNotEmpty,
    timeout: const Duration(seconds: 60),
  );
  debugPrint('[live-loop] question pending on the real opencode');

  // ---- 6. Wait for the notify daemon's control channel to register with
  //         the gateway. Registration publishes an instance presence to the
  //         client over the real gateway WebSocket; this must complete
  //         before the notification/answer can flow.
  await pumpUntil(
    tester,
    () => container
        .read(instancePresencesProvider)
        .values
        .any((presence) => presence.state == InstancePresenceState.controllable),
    timeout: const Duration(seconds: 120),
  );
  debugPrint('[live-loop] control channel registered (presence controllable)');

  // ---- 7. Wait for the desktop notification delivered over the real
  //         gateway WebSocket (the RecordingNotificationService is the only
  //         stub; everything upstream is production).
  await pumpUntil(
    tester,
    () {
      for (final request in notifications.shown) {
        if (request.onClick != null) return true;
      }
      return false;
    },
    timeout: const Duration(seconds: 90),
  );
  final notify = notifications.shown.firstWhere((request) => request.onClick != null);
  expect(notify.body, contains(_questionSentinel));
  debugPrint('[live-loop] question notification delivered via the real gateway WS');

  // ---- 8. Click the notification → deep link into the focused question
  //         page (the owning instance is already controllable — the control
  //         channel registration was awaited in step 6).
  notify.onClick!();
  await pumpUntil(
    tester,
    () => find.byType(PendingInteractionPage).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 30),
  );
  expect(find.text('待处理问题'), findsOneWidget);
  expect(find.textContaining('CLOSED_LOOP_QUESTION'), findsOneWidget);
  expect(find.byKey(const ValueKey('submit-answer')), findsOneWidget);
  debugPrint('[live-loop] notification click opened the focused question page');

  // The real opencode must still hold the question pending (also validates
  // the direct-assertion URL before we rely on it for the "cleared" check).
  final pendingUpstream = await _ocQuestionRequests(ocBase, projectDir.path);
  final pendingJson = jsonEncode(pendingUpstream);
  expect(pendingJson, contains('CLOSED_LOOP_QUESTION'), reason: 'question pending upstream');
  debugPrint('[live-loop] question confirmed pending on the real opencode');

  // ---- 9. Answer through the REAL form submit.
  await tester.tap(find.byKey(const ValueKey('question-0-option-0')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('submit-answer')));
  await tester.pump();
  await pumpUntil(
    tester,
    () => find.textContaining('OpenCode 已确认回答').evaluate().isNotEmpty,
    timeout: const Duration(seconds: 60),
  );
  debugPrint('[live-loop] answer confirmed by the real opencode via the gateway');

  // ---- 10. Direct HTTP assertions on the real opencode: the pending question
  //         cleared and the question tool completed with our answers. The
  //         tool state finalizes a few seconds after the gateway-confirmed
  //         answer, so poll until it settles.
  await pumpUntilAsync(
    tester,
    () async => (await _ocQuestionRequests(ocBase, projectDir.path)).isEmpty,
    timeout: const Duration(seconds: 30),
  );
  Map<String, dynamic>? toolState;
  final toolDeadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(toolDeadline)) {
    try {
      final state = await _ocQuestionToolState(ocBase, sessionId);
      if (state['status'] == 'completed') {
        toolState = state;
        break;
      }
    } on StateError {
      // Tool part not settled yet; keep polling.
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  expect(toolState, isNotNull, reason: 'question tool must complete on the real opencode');
  final structured = toolState!['structured'];
  final answers = structured is Map<String, dynamic> ? structured['answers'] : null;
  expect(answers, [
    [_answerSentinel],
  ]);
  debugPrint('[live-loop] question cleared and tool completed with submitted answers');

  // ---- 11. The gateway's authoritative snapshot for the account is empty.
  final pending = await _getJson(
    client,
    '$gatewayUrl/v1/pending-interactions',
    bearer: accessToken,
  );
  expect((pending['interactions'] as List), isEmpty);
  debugPrint('[live-loop] gateway pending-interactions snapshot empty');

  // ---- 12. AC1 in the live loop: the gateway log carries NO question or
  //         answer bodies (production redaction) while the event DID flow.
  final logFile = File(gatewayLogPath);
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  var logText = '';
  while (DateTime.now().isBefore(deadline)) {
    if (logFile.existsSync()) {
      logText = await logFile.readAsString();
      if (logText.contains('/v1/events')) break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  expect(logText, contains('/v1/events'), reason: 'ingest route must have been hit');
  expect(logText, contains('"statusCode":202'), reason: 'ingest must have answered 202');
  expect(logText, isNot(contains(_marker)), reason: 'marker must never reach the gateway log');
  expect(logText, isNot(contains(_questionSentinel)), reason: 'question body must be redacted');
  expect(logText, isNot(contains(_answerSentinel)), reason: 'answer body must be redacted');
  debugPrint('[live-loop] gateway log redaction proven (no question/answer bodies)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'live Linux closed loop: real gateway + real login UI + real opencode + '
    'notification click → focused question → form submit → tool completes',
    (tester) async {
      if (_liveGatewayUrl.isEmpty || _mailboxPath.isEmpty) {
        debugPrint(
          '[live-loop] SKIPPED: LIVE_GATEWAY_URL / MAILBOX_PATH not defined '
          '(run through scripts/beta/closed-loop.sh)',
        );
        return;
      }
      await _runLiveLoop(tester);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
