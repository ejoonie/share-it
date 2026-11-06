import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'bootstrap_debug_screen.dart';
import 'design_system_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../design_system/tokens.dart';
import '../utils/open_support_link.dart';
import '../providers/core_providers.dart';
import '../providers/session_provider.dart';
import 'change_password_screen.dart';
import 'topic_detail_screen.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// Keep version and notification interaction state local to this screen.
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  bool _notificationBusy = false;

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
    if (_notificationBusy) return;
    setState(() => _notificationBusy = true);
    try {
      await ref
          .read(sessionNotifierProvider.notifier)
          .setNotificationEnabled(value);

      // toast
      _showSnackBar(value ? 'Notification Enabled' : 'Notification Disabled');
    } catch (e) {
      _showSnackBar('Failed to update notification setting.');
    } finally {
      if (mounted) setState(() => _notificationBusy = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Widget _accountCard() {
    final user = ref.watch(sessionNotifierProvider).data?.user;
    return _SettingsRow(
      icon: Icons.person_outline,
      title: 'My account',
      subtitle: user?.email ?? '',
      background: PiggyColors.accentSoft,
      trailing: const Icon(
        Icons.arrow_forward_rounded,
        size: 20,
        color: PiggyColors.accent,
      ),
      onTap: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsRefreshProvider, (_, __) {
      notifier.loadMyPiggies();
      ref.read(sessionNotifierProvider.notifier).refreshNotificationEnabled();
    });

    final state = ref.watch(settingsNotifierProvider);
    final notificationsEnabled =
        ref.watch(sessionNotifierProvider).data?.user?.notificationsEnabled ??
            true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Design system',
              icon: const Icon(Icons.palette_outlined, size: 22),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DesignSystemScreen()),
              ),
            ),
          if (kDebugMode)
            IconButton(
              tooltip: 'Bootstrap Debug',
              icon: const Icon(Icons.bug_report_outlined, size: 22),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BootstrapDebugScreen()),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: PiggySize.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const Text(
                  'A little more you.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.7,
                    color: PiggyColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your account, your piggies, your preferences.',
                  style: PiggyType.caption,
                ),
                const SizedBox(height: 24),
                _accountCard(),
                const _SectionHeader(title: 'Preferences'),
                const _SettingsRow(
                  icon: Icons.attach_money_rounded,
                  title: 'Default currency',
                  subtitle: 'US Dollar',
                  trailing: _Badge(label: 'USD'),
                ),
                const SizedBox(height: 10),
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Updates when expenses are added.',
                  trailing: Switch.adaptive(
                    value: notificationsEnabled,
                    onChanged: _notificationBusy ? null : _onNotificationToggle,
                  ),
                ),
                _SectionHeader(
                  title: 'My piggies',
                  count: state.myPiggies.valueOrNull?.length,
                ),
                ..._buildMyPiggies(state),
                const _SectionHeader(title: 'Help and policies'),
                ListTile(
                  title: const Text('Terms of Service'),
                  onTap: () => openSupportLink(
                    context,
                    'https://sharablepiggy.com/terms',
                  ),
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  onTap: () => openSupportLink(
                    context,
                    'https://sharablepiggy.com/privacy',
                  ),
                ),
                ListTile(
                  title: const Text('Contact support'),
                  subtitle: const Text('support@sharablepiggy.com'),
                  onTap: () => openSupportLink(
                    context,
                    'mailto:support@sharablepiggy.com',
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Icon(
                    Icons.savings_outlined,
                    size: 26,
                    color: PiggyColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Sharable Piggy', style: PiggyType.label),
                ),
                const SizedBox(height: 4),
                Text(
                  _version.isEmpty ? 'Version …' : 'Version $_version',
                  textAlign: TextAlign.center,
                  style: PiggyType.metadata,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMyPiggies(SettingsState state) => state.myPiggies.when(
        loading: () => [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
        error: (_, __) => [
          _SettingsRow(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load piggies',
            subtitle: 'Tap to try again.',
            onTap: () => notifier.loadMyPiggies(),
            trailing: const Icon(Icons.refresh, color: PiggyColors.secondary),
          ),
        ],
        data: (piggies) => piggies.isEmpty
            ? [
                const _SettingsRow(
                  icon: Icons.savings_outlined,
                  title: 'Room for a piggy',
                  subtitle: 'Your own piggies will appear here.',
                ),
              ]
            : piggies
                .map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SettingsRow(
                      icon: Icons.savings_outlined,
                      title: topic.title,
                      subtitle: 'Owner (you)',
                      badge: topic.isDefault ? 'Default' : null,
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: PiggyColors.secondary,
                      ),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(topicId: topic.id),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionHeader({required this.title, this.count});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12, left: 2),
        child: Row(
          children: [
            Flexible(child: Text(title, style: PiggyType.sectionTitle)),
            if (count != null) ...[
              const SizedBox(width: 8),
              _Badge(label: '$count'),
            ],
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: PiggyColors.accentSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: PiggyType.label.copyWith(color: PiggyColors.accent),
        ),
      );
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color background;
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
    this.background = PiggyColors.card,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PiggyColors.surface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 22, color: PiggyColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: PiggyType.itemTitle),
                      const SizedBox(height: 4),
                      Text(subtitle, style: PiggyType.caption),
                      if (badge != null) ...[
                        const SizedBox(height: 8),
                        _Badge(label: badge!),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
            ),
          ),
        ),
      );
}
