import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_history.dart';
import 'history_schema.dart';
import 'resilient_notification_history.dart';
import 'sqlite_notification_history.dart';

const historyPageSizes = [20, 30, 50, 100];

final notificationHistoryProvider = Provider<NotificationHistory>((ref) {
  final history = ResilientNotificationHistory(
    primary: SqliteNotificationHistory.openDefault(),
    fallback: InMemoryNotificationHistory(
      capacity: notificationHistoryCapacity,
    ),
  );
  ref.onDispose(history.close);
  return history;
});

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, HistoryViewState>(
      HistoryController.new,
    );

class HistoryViewState {
  const HistoryViewState({
    required this.entries,
    required this.totalCount,
    required this.pageIndex,
    required this.pageSize,
    this.newEntryCount = 0,
  });

  final List<HistoryEntry> entries;
  final int totalCount;
  final int pageIndex;
  final int pageSize;
  final int newEntryCount;

  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
  bool get canGoBack => pageIndex > 0;
  bool get canGoForward => pageIndex + 1 < totalPages;

  HistoryViewState copyWith({int? totalCount, int? newEntryCount}) =>
      HistoryViewState(
        entries: entries,
        totalCount: totalCount ?? this.totalCount,
        pageIndex: pageIndex,
        pageSize: pageSize,
        newEntryCount: newEntryCount ?? this.newEntryCount,
      );
}

class HistoryController extends AsyncNotifier<HistoryViewState> {
  StreamSubscription<void>? _changes;
  int _loadToken = 0;

  NotificationHistory get _history => ref.read(notificationHistoryProvider);

  @override
  Future<HistoryViewState> build() async {
    final history = ref.watch(notificationHistoryProvider);
    _changes = history.changes.listen((_) => _onHistoryChanged());
    ref.onDispose(() => _changes?.cancel());
    return _load(pageIndex: 0, pageSize: 50);
  }

  Future<void> refresh() {
    final current = state.value;
    if (current == null) return Future.value();
    return _replace(
      pageIndex: current.pageIndex,
      pageSize: current.pageSize,
      showLoading: false,
    );
  }

  Future<void> setPageSize(int pageSize) {
    if (!historyPageSizes.contains(pageSize)) {
      throw ArgumentError.value(pageSize, 'pageSize', 'unsupported page size');
    }
    return _replace(pageIndex: 0, pageSize: pageSize, showLoading: true);
  }

  Future<void> goToPage(int pageIndex) {
    final current = state.value;
    if (current == null || pageIndex < 0 || pageIndex >= current.totalPages) {
      return Future.value();
    }
    return _replace(
      pageIndex: pageIndex,
      pageSize: current.pageSize,
      showLoading: true,
    );
  }

  Future<void> showNewest() {
    final pageSize = state.value?.pageSize ?? 50;
    return _replace(pageIndex: 0, pageSize: pageSize, showLoading: true);
  }

  void _onHistoryChanged() {
    final current = state.value;
    if (current == null) return;
    if (current.pageIndex == 0) {
      unawaited(refresh());
      return;
    }
    state = AsyncData(
      current.copyWith(newEntryCount: current.newEntryCount + 1),
    );
  }

  Future<void> _replace({
    required int pageIndex,
    required int pageSize,
    required bool showLoading,
  }) async {
    final token = ++_loadToken;
    if (showLoading) state = const AsyncLoading();
    try {
      final next = await _load(pageIndex: pageIndex, pageSize: pageSize);
      if (token == _loadToken) state = AsyncData(next);
    } catch (error, stackTrace) {
      if (token == _loadToken) state = AsyncError(error, stackTrace);
    }
  }

  Future<HistoryViewState> _load({
    required int pageIndex,
    required int pageSize,
  }) async {
    var batch = await _history.loadPage(
      offset: pageIndex * pageSize,
      limit: pageSize,
    );
    final totalPages = batch.totalCount == 0
        ? 1
        : (batch.totalCount / pageSize).ceil();
    final actualPage = pageIndex.clamp(0, totalPages - 1);
    if (actualPage != pageIndex) {
      batch = await _history.loadPage(
        offset: actualPage * pageSize,
        limit: pageSize,
      );
    }
    return HistoryViewState(
      entries: batch.entries,
      totalCount: batch.totalCount,
      pageIndex: actualPage,
      pageSize: pageSize,
    );
  }
}
