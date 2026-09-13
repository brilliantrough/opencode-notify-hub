import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify_api/notify_api.dart' show SessionCatalog;

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../config/server_config.dart';
import '../devices/devices_controller.dart' show sharedPreferencesProvider;
import '../realtime/active_sessions.dart';
import '../realtime/instance_presence.dart';
import '../realtime/realtime_controller.dart';

class RemoteSession {
  const RemoteSession({
    required this.session,
    required this.instanceId,
    this.status = 'unknown',
    this.pinned = false,
    this.openedAt,
    this.verified = false,
  });

  final ActiveSession session;
  final String instanceId;
  final String status;
  final bool pinned;
  final DateTime? openedAt;
  final bool verified;

  String get key =>
      jsonEncode([session.machine, session.directory, session.sessionId]);
  bool belongsTo(OpenCodeInstancePresence instance) =>
      instance.machine == session.machine &&
      instance.directory == session.directory;

  RemoteSession copyWith({
    bool? pinned,
    DateTime? openedAt,
    bool? verified,
    String? status,
  }) => RemoteSession(
    session: session,
    instanceId: instanceId,
    status: status ?? this.status,
    pinned: pinned ?? this.pinned,
    openedAt: openedAt ?? this.openedAt,
    verified: verified ?? this.verified,
  );

  Map<String, Object?> toJson() => {
    'sessionId': session.sessionId,
    'machine': session.machine,
    'project': session.project,
    'directory': session.directory,
    'title': session.title,
    'updatedAt': session.lastHeartbeatAt.toIso8601String(),
    'instanceId': instanceId,
    'pinned': pinned,
    'openedAt': openedAt?.toIso8601String(),
  };

  factory RemoteSession.fromJson(Map<String, dynamic> json) => RemoteSession(
    session: ActiveSession(
      sessionId: json['sessionId'] as String,
      machine: json['machine'] as String,
      project: json['project'] as String,
      directory: json['directory'] as String,
      title: json['title'] as String,
      lastHeartbeatAt: DateTime.parse(json['updatedAt'] as String),
      running: false,
    ),
    instanceId: json['instanceId'] as String,
    pinned: json['pinned'] == true,
    openedAt: DateTime.tryParse(json['openedAt'] as String? ?? ''),
  );
}

class SessionCatalogState {
  const SessionCatalogState({
    this.sessions = const {},
    this.errors = const {},
    this.loading = false,
    this.hasMore = false,
    this.search = '',
    this.limit = 50,
  });
  final Map<String, RemoteSession> sessions;
  final Map<String, String> errors;
  final bool loading;
  final bool hasMore;
  final String search;
  final int limit;

  SessionCatalogState copyWith({
    Map<String, RemoteSession>? sessions,
    Map<String, String>? errors,
    bool? loading,
    bool? hasMore,
    String? search,
    int? limit,
  }) => SessionCatalogState(
    sessions: sessions ?? this.sessions,
    errors: errors ?? this.errors,
    loading: loading ?? this.loading,
    hasMore: hasMore ?? this.hasMore,
    search: search ?? this.search,
    limit: limit ?? this.limit,
  );

  List<RemoteSession> get visible {
    final query = search.toLowerCase();
    final result = sessions.values
        .where(
          (s) =>
              '${s.session.title} ${s.session.machine} ${s.session.project} ${s.session.directory}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    result.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return (b.openedAt ?? b.session.lastHeartbeatAt).compareTo(
        a.openedAt ?? a.session.lastHeartbeatAt,
      );
    });
    return result;
  }
}

final sessionCatalogProvider =
    NotifierProvider<SessionCatalogController, SessionCatalogState>(
      SessionCatalogController.new,
    );

/// Snapshots are authoritative; local bookmarks survive process/instance restarts.
class SessionCatalogController extends Notifier<SessionCatalogState> {
  int _epoch = 0;
  int _queryVersion = 0;
  Timer? _debounce;
  Future<void>? _refreshing;
  Future<void> _writes = Future.value();
  String? _storageKey;
  bool _loaded = false;

  @override
  SessionCatalogState build() {
    final epoch = ++_epoch;
    _loaded = false;
    _refreshing = null;
    _storageKey = null;
    final auth = ref.watch(authControllerProvider);
    final gateway = ref.watch(appConfigProvider).gatewayHttpBase;
    ref.onDispose(() {
      _epoch++;
      _debounce?.cancel();
    });
    if (auth is! Authenticated) return const SessionCatalogState();
    _storageKey =
        'session_catalog_v1:${jsonEncode([gateway, auth.email.toLowerCase()])}';
    ref.listen(instancePresencesProvider, (_, next) {
      // Mark old bindings stale immediately; a new instance must answer first.
      state = state.copyWith(
        sessions: state.sessions.map(
          (key, value) => MapEntry(
            key,
            next[value.instanceId]?.state == InstancePresenceState.controllable
                ? value
                : value.copyWith(verified: false, status: 'unknown'),
          ),
        ),
      );
      _schedule();
    });
    ref.listen(activeSessionsProvider, (_, _) => _schedule());
    ref.listen(appForegroundProvider, (_, foreground) {
      if (foreground) _schedule();
    });
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ref.read(appForegroundProvider)) unawaited(refresh());
    });
    ref.onDispose(timer.cancel);
    unawaited(Future(() => _load(epoch)));
    return const SessionCatalogState(loading: true);
  }

  Future<void> _load(int epoch) async {
    if (epoch != _epoch || !ref.mounted) return;
    try {
      final prefs = await ref.read(sharedPreferencesProvider);
      if (epoch != _epoch || !ref.mounted) return;
      final raw = prefs.getString(_storageKey!);
      final sessions = <String, RemoteSession>{};
      if (raw != null) {
        for (final entry in jsonDecode(raw) as List) {
          final session = RemoteSession.fromJson(
            Map<String, dynamic>.from(entry as Map),
          );
          sessions[session.key] = session;
        }
      }
      state = state.copyWith(sessions: sessions);
    } catch (_) {
      /* A damaged cache must not prevent live discovery. */
    }
    if (epoch != _epoch || !ref.mounted) return;
    _loaded = true;
    await refresh();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(refresh()),
    );
  }

  void search(String query) {
    _queryVersion++;
    state = state.copyWith(search: query.trim(), limit: 50);
    _schedule();
  }

  Future<void> loadMore() async {
    state = state.copyWith(limit: (state.limit + 50).clamp(50, 200));
    _queryVersion++;
    await refresh();
  }

  Future<void> refresh() async {
    if (!_loaded || !ref.mounted || _storageKey == null) return;
    if (_refreshing != null) {
      await _refreshing;
      if (ref.mounted) _schedule();
      return;
    }
    final epoch = _epoch;
    final operation = _refresh(epoch);
    _refreshing = operation;
    try {
      await operation;
    } finally {
      if (epoch == _epoch) _refreshing = null;
    }
  }

  Future<void> _refresh(int epoch) async {
    final version = _queryVersion;
    final query = state.search;
    final limit = state.limit;
    final instances = ref
        .read(instancePresencesProvider)
        .values
        .where((i) => i.state == InstancePresenceState.controllable)
        .toList();
    final api = ref.read(apiClientProvider).notifyApi.getSessionsApi();
    state = state.copyWith(loading: true);
    final errors = <String, String>{};
    var hasMore = false;
    // Four in-flight queries keep a large instance list from flooding the Plugin.
    for (var offset = 0; offset < instances.length; offset += 4) {
      await Future.wait(
        instances.skip(offset).take(4).map((instance) async {
          final bookmarks =
              state.sessions.values
                  .where(
                    (s) =>
                        s.belongsTo(instance) &&
                        (s.pinned || s.openedAt != null),
                  )
                  .toList()
                ..sort(
                  (a, b) => (b.openedAt ?? b.session.lastHeartbeatAt).compareTo(
                    a.openedAt ?? a.session.lastHeartbeatAt,
                  ),
                );
          final ids = [
            ...bookmarks.where((s) => s.pinned),
            ...bookmarks.where((s) => !s.pinned),
          ].take(50).map((s) => s.session.sessionId).join(',');
          try {
            final matchesSource =
                '${instance.machine} ${instance.project} ${instance.directory}'
                    .toLowerCase()
                    .contains(query.toLowerCase());
            final response = await api.getSessionCatalog(
              instanceId: instance.instanceId,
              limit: limit,
              search: matchesSource ? '' : query,
              sessionIds: ids,
            );
            if (!ref.mounted || epoch != _epoch || version != _queryVersion) {
              return;
            }
            if (ref
                    .read(instancePresencesProvider)[instance.instanceId]
                    ?.state !=
                InstancePresenceState.controllable) {
              return;
            }
            final snapshot = response.data;
            if (snapshot == null) throw StateError('Empty session catalog');
            hasMore |= snapshot.hasMore;
            _apply(instance, snapshot);
          } catch (error) {
            if (!ref.mounted || epoch != _epoch || version != _queryVersion) {
              return;
            }
            errors[instance.instanceId] = _errorMessage(error);
            state = state.copyWith(
              sessions: state.sessions.map(
                (key, value) => MapEntry(
                  key,
                  value.belongsTo(instance)
                      ? value.copyWith(verified: false, status: 'unknown')
                      : value,
                ),
              ),
            );
          }
        }),
      );
      if (!ref.mounted || epoch != _epoch || version != _queryVersion) break;
    }
    if (!ref.mounted || epoch != _epoch) return;
    state = state.copyWith(
      loading: false,
      errors: version == _queryVersion ? errors : null,
      hasMore: version == _queryVersion ? hasMore : null,
    );
    if (version != _queryVersion) {
      _schedule();
      return;
    }
    await _save();
  }

  void _apply(OpenCodeInstancePresence instance, SessionCatalog snapshot) {
    final previous = state.sessions;
    final next = Map<String, RemoteSession>.of(previous)
      ..removeWhere((_, s) => s.belongsTo(instance) && !s.pinned);
    // Missing bookmarks remain visible but cannot be opened as verified sessions.
    for (final entry in next.entries.toList()) {
      if (entry.value.belongsTo(instance)) {
        next[entry.key] = entry.value.copyWith(
          verified: false,
          status: 'missing',
        );
      }
    }
    for (final item in snapshot.sessions) {
      final session = RemoteSession(
        instanceId: instance.instanceId,
        verified: true,
        status: item.status.name,
        session: ActiveSession(
          sessionId: item.sessionId,
          machine: instance.machine,
          project: instance.project,
          directory: item.directory,
          title: item.title,
          lastHeartbeatAt: item.updatedAt,
          running: item.status.name == 'busy' || item.status.name == 'retry',
        ),
      );
      final old = previous[session.key];
      next[session.key] = session.copyWith(
        pinned: old?.pinned,
        openedAt: old?.openedAt,
      );
    }
    final bounded = next.values.toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return (b.openedAt ?? b.session.lastHeartbeatAt).compareTo(
          a.openedAt ?? a.session.lastHeartbeatAt,
        );
      });
    state = state.copyWith(
      sessions: {for (final s in bounded.take(1000)) s.key: s},
    );
  }

  Future<String?> togglePin(RemoteSession item) async {
    if (!item.pinned &&
        state.sessions.values.where((s) => s.pinned).length >= 50) {
      return '最多固定 50 个会话';
    }
    state = state.copyWith(
      sessions: {
        ...state.sessions,
        item.key: item.copyWith(pinned: !item.pinned),
      },
    );
    return await _save() ? null : '无法保存固定会话，请重试';
  }

  Future<void> markOpened(String instanceId, String sessionId) async {
    state = state.copyWith(
      sessions: state.sessions.map(
        (key, item) => MapEntry(
          key,
          item.instanceId == instanceId && item.session.sessionId == sessionId
              ? item.copyWith(openedAt: DateTime.now())
              : item,
        ),
      ),
    );
    await _save();
  }

  RemoteSession? preferred(OpenCodeInstancePresence instance) {
    final choices =
        state.sessions.values
            .where((s) => s.instanceId == instance.instanceId && s.verified)
            .toList()
          ..sort((a, b) {
            if ((a.openedAt != null) != (b.openedAt != null)) {
              return a.openedAt != null ? -1 : 1;
            }
            return (b.openedAt ?? b.session.lastHeartbeatAt).compareTo(
              a.openedAt ?? a.session.lastHeartbeatAt,
            );
          });
    return choices.isEmpty ? null : choices.first;
  }

  Future<bool> _save() async {
    final key = _storageKey;
    if (key == null) return false;
    final raw = jsonEncode(
      state.sessions.values.map((s) => s.toJson()).toList(),
    );
    var saved = false;
    final prefs = ref.read(sharedPreferencesProvider);
    _writes = _writes.then((_) async {
      try {
        saved = await (await prefs).setString(key, raw);
      } catch (_) {
        /* Report bookmark write failure to the caller. */
      }
    });
    await _writes;
    return saved;
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      return switch (error.response?.statusCode) {
        404 => '实例不可用，或 Gateway 尚未支持会话列表',
        501 => '请更新此实例的 Notify Plugin',
        504 => '会话查询超时，请确认 Plugin 已更新且在线',
        _ => '会话同步失败，显示上次记录',
      };
    }
    return '会话同步失败，显示上次记录';
  }
}
