import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bootstrap/providers/bootstrap_provider.dart';
import '../../core/models/entry_model.dart';
import '../../core/models/topic_model.dart';

class BootstrapDebugScreen extends ConsumerWidget {
  const BootstrapDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bootstrapNotifierProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF313244),
        foregroundColor: const Color(0xFFCDD6F4),
        title: const Text(
          '🛠 Bootstrap Debug',
          style: TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(state.status).withAlpha(40),
              border: Border.all(color: _statusColor(state.status)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              state.status.name.toUpperCase(),
              style: TextStyle(
                color: _statusColor(state.status),
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: data == null
          ? Center(
              child: Text(
                state.status == BootstrapStatus.failure
                    ? '❌ ${state.error ?? 'Unknown error'}'
                    : '⏳ Bootstrap not yet completed…',
                style: const TextStyle(
                  color: Color(0xFFF38BA8),
                  fontFamily: 'monospace',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(label: 'Bootstrap Created', icon: Icons.bolt),
                _ValueTile(
                  label: 'bootstrap_created',
                  value: data.bootstrapCreated.toString(),
                  valueColor: data.bootstrapCreated
                      ? const Color(0xFFA6E3A1)
                      : const Color(0xFFF38BA8),
                ),
                const SizedBox(height: 20),
                _SectionHeader(label: 'Topic', icon: Icons.folder_outlined),
                if (data.topic == null)
                  const _ValueTile(label: 'topic', value: 'null')
                else
                  ..._topicTiles(data.topic!),
                const SizedBox(height: 20),
                _SectionHeader(
                  label: 'Entries (${data.entries.length})',
                  icon: Icons.list_alt,
                ),
                if (data.entries.isEmpty)
                  const _ValueTile(label: 'entries', value: '[]')
                else
                  ...data.entries.asMap().entries.map(
                        (e) => _EntryCard(index: e.key, entry: e.value),
                      ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  List<Widget> _topicTiles(TopicModel t) => [
        _ValueTile(label: 'id', value: t.id.toString()),
        _ValueTile(label: 'token', value: t.token),
        _ValueTile(label: 'user_id', value: t.userId.toString()),
        _ValueTile(label: 'title', value: t.title),
        _ValueTile(
          label: 'is_default',
          value: t.isDefault.toString(),
          valueColor: t.isDefault
              ? const Color(0xFFA6E3A1)
              : const Color(0xFFCDD6F4),
        ),
        _ValueTile(label: 'created_at', value: t.createdAt),
        _ValueTile(label: 'updated_at', value: t.updatedAt),
      ];

  Color _statusColor(BootstrapStatus s) => switch (s) {
        BootstrapStatus.initial => const Color(0xFF89B4FA),
        BootstrapStatus.loading => const Color(0xFFF9E2AF),
        BootstrapStatus.success => const Color(0xFFA6E3A1),
        BootstrapStatus.failure => const Color(0xFFF38BA8),
      };
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF89B4FA)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF89B4FA),
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Color(0xFF45475A))),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;

  const _ValueTile({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6C7086),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: TextStyle(
                color: valueColor ?? const Color(0xFFCDD6F4),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final int index;
  final EntryModel entry;

  const _EntryCard({required this.index, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF313244),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF45475A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'entries[$index]',
            style: const TextStyle(
              color: Color(0xFFCBA6F7),
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _ValueTile(label: 'id', value: entry.id.toString()),
          _ValueTile(label: 'topic_id', value: entry.topicId.toString()),
          _ValueTile(label: 'created_by_id', value: entry.createdById.toString()),
          if (entry.updatedById != null)
            _ValueTile(label: 'updated_by_id', value: entry.updatedById.toString()),
          _ValueTile(
            label: 'kind',
            value: entry.kind ?? 'null',
            valueColor: entry.kind == 'expense'
                ? const Color(0xFFFAB387)
                : const Color(0xFF89DCEB),
          ),
          if (entry.title != null)
            _ValueTile(label: 'title', value: entry.title!),
          if (entry.content != null)
            _ValueTile(label: 'content', value: entry.content!),
          _ValueTile(label: 'currency', value: entry.currency),
          _ValueTile(label: 'amount', value: entry.amount.toString()),
          if (entry.category != null)
            _ValueTile(label: 'category', value: entry.category!),
          _ValueTile(
            label: 'checked',
            value: entry.checked.toString(),
            valueColor: entry.checked
                ? const Color(0xFFA6E3A1)
                : const Color(0xFFCDD6F4),
          ),
          _ValueTile(label: 'created_at', value: entry.createdAt.toString()),
        ],
      ),
    );
  }
}


