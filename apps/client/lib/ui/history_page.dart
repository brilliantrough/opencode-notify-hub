import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/history_controller.dart';
import '../history/notification_history.dart';

/// Device-local notification history, newest first.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  static const double _wideLayoutBreakpoint = 720;

  static Key entryKey(String eventId) => ValueKey('history-$eventId');
  static Key detailsKey(String eventId) => ValueKey('history-details-$eventId');

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(historyControllerProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史'),
        actions: [
          IconButton(
            key: const ValueKey('history-refresh'),
            tooltip: '刷新历史',
            icon: const Icon(Icons.refresh),
            onPressed: () => unawaited(
              ref.read(historyControllerProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _HistoryLoadError(
          onRetry: () =>
              unawaited(ref.read(historyControllerProvider.notifier).refresh()),
        ),
        data: (state) => _HistoryBody(state: state),
      ),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.state});

  final HistoryViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= HistoryPage._wideLayoutBreakpoint;
      return Column(
        children: [
          if (state.newEntryCount > 0)
            Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: InkWell(
                key: const ValueKey('history-new-entries'),
                onTap: () => unawaited(
                  ref.read(historyControllerProvider.notifier).showNewest(),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      '${state.newEntryCount} 条新通知，点击查看',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          if (wide && state.entries.isNotEmpty) const _HistoryTableHeader(),
          Expanded(
            child: state.entries.isEmpty
                ? const Center(child: Text('暂无通知历史'))
                : ListView.builder(
                    itemCount: state.entries.length,
                    itemBuilder: (context, index) => _HistoryEntryTile(
                      entry: state.entries[index],
                      wide: wide,
                    ),
                  ),
          ),
          _HistoryPagination(state: state),
        ],
      );
    },
  );
}

class _HistoryPagination extends ConsumerWidget {
  const _HistoryPagination({required this.state});

  final HistoryViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final controller = ref.read(historyControllerProvider.notifier);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Text('每页'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              key: const ValueKey('history-page-size'),
              value: state.pageSize,
              isDense: true,
              items: [
                for (final size in historyPageSizes)
                  DropdownMenuItem(value: size, child: Text('$size')),
              ],
              onChanged: (value) {
                if (value != null) unawaited(controller.setPageSize(value));
              },
            ),
            const Spacer(),
            Flexible(
              child: Text(
                '第 ${state.pageIndex + 1} / ${state.totalPages} 页 · 共 ${state.totalCount} 条',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              key: const ValueKey('history-previous-page'),
              tooltip: '上一页',
              icon: const Icon(Icons.chevron_left),
              onPressed: state.canGoBack
                  ? () => unawaited(controller.goToPage(state.pageIndex - 1))
                  : null,
            ),
            IconButton(
              key: const ValueKey('history-next-page'),
              tooltip: '下一页',
              icon: const Icon(Icons.chevron_right),
              onPressed: state.canGoForward
                  ? () => unawaited(controller.goToPage(state.pageIndex + 1))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryLoadError extends StatelessWidget {
  const _HistoryLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('重新加载历史'),
    ),
  );
}

class _HistoryTableHeader extends StatelessWidget {
  const _HistoryTableHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 56, 8),
        child: _HistoryWideColumns(
          time: Text('时间', style: style),
          machine: Text('机器', style: style),
          directory: Text('目录', style: style),
          session: Text('会话', style: style),
          status: Text('状态', style: style),
        ),
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry, required this.wide});

  final HistoryEntry entry;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpansionTile(
      key: HistoryPage.entryKey(entry.eventId),
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: EdgeInsets.zero,
      shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      collapsedShape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      title: wide ? _wideTitle(context) : _compactTitle(context),
      children: [_HistoryDetails(entry: entry)],
    );
  }

  Widget _wideTitle(BuildContext context) {
    final primary = Theme.of(context).textTheme.bodyMedium;
    final secondary = primary?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return _HistoryWideColumns(
      time: Text(_shortDateTime(entry.receivedAt), style: secondary),
      machine: Text(
        entry.machine ?? '未知机器',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: primary,
      ),
      directory: Text(
        entry.directoryName ?? entry.project ?? '未知目录',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: primary?.copyWith(fontWeight: FontWeight.w600),
      ),
      session: Text(
        entry.sessionTitle ?? entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: primary,
      ),
      status: Text(
        entry.status ?? '通知',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: secondary,
      ),
    );
  }

  Widget _compactTitle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _sourceLabel(entry),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              entry.status ?? '通知',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                entry.sessionTitle ?? entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _shortDateTime(entry.receivedAt),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryWideColumns extends StatelessWidget {
  const _HistoryWideColumns({
    required this.time,
    required this.machine,
    required this.directory,
    required this.session,
    required this.status,
  });

  final Widget time;
  final Widget machine;
  final Widget directory;
  final Widget session;
  final Widget status;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 104, child: time),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: machine),
      const SizedBox(width: 16),
      Expanded(flex: 2, child: directory),
      const SizedBox(width: 16),
      Expanded(flex: 4, child: session),
      const SizedBox(width: 16),
      Expanded(flex: 2, child: status),
    ],
  );
}

String _sourceLabel(HistoryEntry entry) {
  final directory = entry.directoryName ?? entry.project ?? '未知目录';
  final machine = entry.machine;
  return machine == null ? directory : '$machine · $directory';
}

class _HistoryDetails extends StatelessWidget {
  const _HistoryDetails({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final details = <(String, String)>[
      if (entry.body.isNotEmpty) ('内容', entry.body),
      if (entry.sessionTitle != null) ('会话', entry.sessionTitle!),
      if (entry.directory != null) ('工作目录', entry.directory!),
      if (entry.project != null) ('项目', entry.project!),
      if (entry.machine != null) ('机器', entry.machine!),
      if (entry.occurredAt != null) ('事件时间', _fullDateTime(entry.occurredAt!)),
      ('接收时间', _fullDateTime(entry.receivedAt)),
      if (entry.eventType != null) ('事件类型', entry.eventType!),
      if (entry.sessionId != null) ('Session ID', entry.sessionId!),
      if (entry.requestId != null) ('Request ID', entry.requestId!),
      ('Event ID', entry.eventId),
    ];
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = Theme.of(context).textTheme.bodySmall;
    return ColoredBox(
      key: HistoryPage.detailsKey(entry.eventId),
      color: colors.surfaceContainerHighest.withValues(alpha: 0.22),
      child: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 56, 10),
          child: Table(
            columnWidths: const {0: FixedColumnWidth(82), 1: FlexColumnWidth()},
            border: TableBorder(
              horizontalInside: BorderSide(color: colors.outlineVariant),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              for (final (label, value) in details)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(label, style: labelStyle),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(value, style: valueStyle),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _shortDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

String _fullDateTime(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}
