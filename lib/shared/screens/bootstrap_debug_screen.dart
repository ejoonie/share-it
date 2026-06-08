import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bootstrap/providers/bootstrap_provider.dart';

class BootstrapDebugScreen extends ConsumerWidget {
  const BootstrapDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bootstrapNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bootstrap Debug')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Status', value: state.status.name),
            if (state.error != null)
              _InfoRow(label: 'Error', value: state.error!),
            if (state.data != null) ...[
              _InfoRow(
                label: 'Bootstrap Created',
                value: state.data!.bootstrapCreated.toString(),
              ),
              _InfoRow(
                label: 'Topic',
                value: state.data!.topic?.id.toString() ?? 'null',
              ),
              _InfoRow(
                label: 'Entries',
                value: state.data!.entries.length.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
