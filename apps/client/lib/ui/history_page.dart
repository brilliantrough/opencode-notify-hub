import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../realtime/realtime_controller.dart';

/// Device-local notification history, newest first.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(notificationHistoryProvider).entries;
    return Scaffold(
      appBar: AppBar(title: const Text('历史')),
      body: entries.isEmpty
          ? const Center(child: Text('暂无通知历史'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  key: ValueKey('history-${entry.eventId}'),
                  title: Text(entry.title),
                  subtitle: Text(entry.body),
                  trailing: Text(_timeText(entry.receivedAt)),
                );
              },
            ),
    );
  }

  static String _timeText(DateTime receivedAt) {
    final local = receivedAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
