import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/notification_history.dart';
import '../realtime/realtime_controller.dart';

/// Device-local notification history, newest first.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  static const double _wideLayoutBreakpoint = 720;

  static Key entryKey(String eventId) => ValueKey('history-$eventId');
  static Key detailsKey(String eventId) => ValueKey('history-details-$eventId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(notificationHistoryProvider).entries;
    return Scaffold(
      appBar: AppBar(title: const Text('历史')),
      body: entries.isEmpty
          ? const Center(child: Text('暂无通知历史'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= _wideLayoutBreakpoint;
                return Column(
                  children: [
                    if (wide) const _HistoryTableHeader(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) => _HistoryEntryTile(
                          entry: entries[index],
                          wide: wide,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
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
