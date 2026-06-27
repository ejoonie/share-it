import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/models/topic_model.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/repositories/topic_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../share/data/repositories/subscription_repository.dart';
import '../../../share/presentation/screens/share_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _currency = 'USD';
  bool _notifications = false;
  String _version = '';

  final List<String> _currencies = ['USD'];

  List<TopicModel> _subscriptions = [];
  bool _subscriptionsLoading = false;

  List<TopicModel> _myPiggies = [];
  bool _myPiggiesLoading = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
    _loadSubscriptions();
    _loadMyPiggies();
  }

  Future<void> _loadSubscriptions() async {
    final authToken = ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return;

    setState(() => _subscriptionsLoading = true);
    try {
      final repo = SubscriptionRepository(
        apiClient: ref.read(apiClientProvider),
        authToken: authToken,
      );
      final list = await repo.fetchAll();
      if (mounted) setState(() => _subscriptions = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _subscriptionsLoading = false);
    }
  }

  Future<void> _loadMyPiggies() async {
    final authToken = ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return;

    setState(() => _myPiggiesLoading = true);
    try {
      final repo = TopicRepository(
        apiClient: ref.read(apiClientProvider),
        authToken: authToken,
      );
      final list = await repo.fetchOwned();
      if (mounted) setState(() => _myPiggies = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _myPiggiesLoading = false);
    }
  }

  Future<void> _unsubscribe(TopicModel sub) async {
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

    final authToken = ref.read(tokenStorageProvider).getAuthToken();
    if (authToken == null) return;

    try {
      final repo = SubscriptionRepository(
        apiClient: ref.read(apiClientProvider),
        authToken: authToken,
      );
      await repo.unsubscribe(sub.id);
      if (mounted) {
        setState(() => _subscriptions.removeWhere((s) => s.id == sub.id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unsubscribe. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (_myPiggiesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_myPiggies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'No piggies yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._myPiggies.map(
              (topic) => ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: Text(topic.title),
                subtitle: topic.isDefault ? const Text('Default') : null,
              ),
            ),
          const _SectionHeader(title: 'My Subscriptions'),
          if (_subscriptionsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_subscriptions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'No subscriptions yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._subscriptions.map(
              (sub) => ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(sub.title),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  tooltip: 'Unsubscribe',
                  onPressed: () => _unsubscribe(sub),
                ),
              ),
            ),
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
