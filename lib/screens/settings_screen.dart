import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/topic_model.dart';
import '../providers/core_providers.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'share_screen.dart';
import 'topic_detail_screen.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// ConsumerStatefulWidget은 로컬 UI 상태(_currency, _notifications, _version)와
// settingsRefreshProvider 리스닝을 위해 유지
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _currency = 'USD';
  bool _notifications = false;
  String _version = '';

  final List<String> _currencies = ['USD'];

  get notifier => ref.read(settingsNotifierProvider.notifier);

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  Future<void> _confirmUnsubscribe(TopicModel sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: Text('Unsubscribe from "${sub.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await notifier.unsubscribe(sub.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to unsubscribe. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsRefreshProvider, (_, __) {
      notifier.loadMyPiggies();
      notifier.loadSubscriptions();
    });

    final state = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'General'),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Default Currency'),
            trailing: DropdownButton<String>(
              value: _currency,
              underline: const SizedBox.shrink(),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _currency = v);
              },
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Receive expense reminders'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          const _SectionHeader(title: 'Share'),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Expenses'),
            subtitle: const Text('Share your expenses with others.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const ShareScreen()),
              );
            },
          ),
          const _SectionHeader(title: 'My Piggies'),
          ..._buildMyPiggies(state),
          const _SectionHeader(title: 'My Subscriptions'),
          ..._buildSubscriptions(state),
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Sign In'),
            subtitle: const Text('Sign in to keep your data safe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outlined),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text(_version.isEmpty ? '...' : _version),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMyPiggies(SettingsState state) {
    return state.myPiggies.when(
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (_, __) => [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Failed to load piggies.',
              style: TextStyle(color: Colors.red)),
        ),
      ],
      data: (piggies) => piggies.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'No piggies yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ]
          : piggies
              .map(
                (topic) => ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: Text(topic.title),
                  subtitle: topic.isDefault ? const Text('Default') : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TopicDetailScreen(topicId: topic.id),
                      ),
                    );
                  },
                ),
              )
              .toList(),
    );
  }

  List<Widget> _buildSubscriptions(SettingsState state) {
    return state.subscriptions.when(
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
      error: (_, __) => [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Failed to load subscriptions.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
      data: (subs) => subs.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'No subscriptions yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ]
          : subs
              .map(
                (sub) => ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(sub.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    tooltip: 'Unsubscribe',
                    onPressed: () => _confirmUnsubscribe(sub),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
