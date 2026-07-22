import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

import '../models/subscription_model.dart';
import '../models/topic_model.dart'; // TopicModel: _buildMyPiggies에서 사용
import '../providers/core_providers.dart';
import '../providers/notification_permission_provider.dart';
import '../providers/session_provider.dart';
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

// ConsumerStatefulWidget is kept for local UI state (_currency, _version)
// and to listen to settingsRefreshProvider
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _currency = 'USD';
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

  Future<void> _onNotificationToggle(bool value) async {
    if (!value) {
      await ref.read(notificationPermissionProvider.notifier).disable();
      return;
    }

    final status = await Permission.notification.status;

    if (status.isGranted) {
      // Already granted — provider state already true, nothing to do
      return;
    }

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Notification Permission Required'),
          content: const Text('Notifications are blocked. Please enable them in your device settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
      }
      return;
    }

    if (status.isDenied) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text('Get notified when new expenses are added to your shared piggies.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        // Revert toggle — provider state is still false
        ref.invalidate(notificationPermissionProvider);
        return;
      }
    }

    await ref.read(notificationPermissionProvider.notifier).request();
  }

  List<Widget> _buildAccountTiles(BuildContext context, WidgetRef ref) {
    final sessionData = ref.watch(sessionNotifierProvider).data;
    final user = sessionData?.user;
    final isLoggedIn = user != null && !user.isGuest;

    if (isLoggedIn) {
      return [
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: const Text('My Account'),
          subtitle: Text('Signed in as ${user.email}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            );
          },
        ),
      ];
    }

    return [
      ListTile(
        leading: const Icon(Icons.login),
        title: const Text('Sign In'),
        subtitle: const Text('Sign in to keep your data safe'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          // Refresh session after successful login
          if (context.mounted) {
            ref.read(sessionNotifierProvider.notifier).reload();
          }
        },
      ),
    ];
  }

  Future<void> _confirmUnsubscribe(int topicId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: Text('Unsubscribe from "$title"?'),
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

    final success = await notifier.unsubscribe(topicId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unsubscribe. Please try again.')),
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
    final notificationsEnabled =
        ref.watch(notificationPermissionProvider).valueOrNull ?? false;

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
            subtitle: const Text('Get notified when expenses are added'),
            value: notificationsEnabled,
            onChanged: _onNotificationToggle,
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
          ..._buildAccountTiles(context, ref),
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
          child: Center(child: CircularProgressIndicator()),
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
          : subs.map((sub) => _SubscriptionTile(
                sub: sub,
                onToggleNotification: (enabled) async {
                  final success = await notifier.toggleNotification(sub.topic.id, enabled: enabled);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? (enabled ? 'Notifications enabled.' : 'Notifications muted.')
                          : 'Failed to update notification setting.'),
                    ),
                  );
                },
                onUnsubscribe: () => _confirmUnsubscribe(sub.topic.id, sub.topic.title),
              )).toList(),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final SubscriptionModel sub;
  final ValueChanged<bool> onToggleNotification;
  final VoidCallback onUnsubscribe;

  const _SubscriptionTile({
    required this.sub,
    required this.onToggleNotification,
    required this.onUnsubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.people_outline),
      title: Text(sub.topic.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              sub.notificationsEnabled ? Icons.notifications_outlined : Icons.notifications_off_outlined,
              color: sub.notificationsEnabled ? null : Colors.grey,
            ),
            tooltip: sub.notificationsEnabled ? 'Mute notifications' : 'Unmute notifications',
            onPressed: () => onToggleNotification(!sub.notificationsEnabled),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            tooltip: 'Unsubscribe',
            onPressed: onUnsubscribe,
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
