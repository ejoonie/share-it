import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/followed_piggies_provider.dart';
import '../providers/session_provider.dart';
import '../screens/piggy_invite_screen.dart';
import '../screens/topic_detail_screen.dart';

class ShareBody extends ConsumerWidget {
  const ShareBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = ref.watch(sessionNotifierProvider).data?.topic;
    final follows = ref.watch(followedPiggiesProvider);
    Future<void> openInvite(InviteMode mode) async {
      if (topic == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PiggyInviteScreen(topic: topic, initialMode: mode),
        ),
      );
      ref.invalidate(followedPiggiesProvider);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(followedPiggiesProvider);
        await ref.read(followedPiggiesProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.qr_code_2, size: 36),
              title: Text(topic?.title ?? 'Your Piggy'),
              subtitle: const Text('Share your piggy with a QR code'),
              trailing: const Icon(Icons.chevron_right),
              onTap: topic == null ? null : () => openInvite(InviteMode.yours),
            ),
          ),
          const SizedBox(height: 28),
          Text('Add Piggy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AddButton(
                  icon: Icons.text_fields,
                  label: 'Text',
                  onTap: () => openInvite(InviteMode.text),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AddButton(
                  icon: Icons.qr_code_scanner,
                  label: 'QR',
                  onTap: () => openInvite(InviteMode.scan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Following', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          follows.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Column(
              children: [
                const Text('Could not load your piggies.'),
                TextButton(
                  onPressed: () => ref.invalidate(followedPiggiesProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.savings_outlined, size: 48),
                        SizedBox(height: 12),
                        Text('Your shared piggies will appear here.'),
                        SizedBox(height: 8),
                        Text('Add one using a code or QR.'),
                      ],
                    ),
                  )
                : Column(
                    children: items
                        .map(
                          (item) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.savings_outlined),
                              ),
                              title: Text(item.topic.title),
                              subtitle: const Text('Following'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TopicDetailScreen(
                                      topicId: item.topic.id,
                                    ),
                                  ),
                                );
                                if (context.mounted) {
                                  ref.invalidate(followedPiggiesProvider);
                                }
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      );
}
