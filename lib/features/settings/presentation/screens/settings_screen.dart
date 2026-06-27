import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../auth/presentation/screens/login_screen.dart';
import '../../../share/presentation/screens/share_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currency = 'USD';
  bool _notifications = false;
  bool _darkMode = false;
  String _startDay = 'Monday';
  String _version = '';

  final List<String> _currencies = ['USD'];
  final List<String> _startDays = ['Monday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
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
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _currency = v);
              },
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          // ListTile(
          //   leading: const Icon(Icons.calendar_today),
          //   title: const Text('Week starts on'),
          //   trailing: DropdownButton<String>(
          //     value: _startDay,
          //     underline: const SizedBox.shrink(),
          //     items: _startDays
          //         .map(
          //           (d) => DropdownMenuItem(value: d, child: Text(d)),
          //         )
          //         .toList(),
          //     onChanged: (v) {
          //       if (v != null) setState(() => _startDay = v);
          //     },
          //   ),
          // ),
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Receive expense reminders'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          // _SectionHeader(title: 'Theme'),
          // SwitchListTile(
          //   secondary: const Icon(Icons.dark_mode_outlined),
          //   title: const Text('Dark Mode'),
          //   subtitle: const Text('Use dark theme'),
          //   value: _darkMode,
          //   onChanged: (v) => setState(() => _darkMode = v),
          // ),
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
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Sign In'),
            subtitle: const Text('Sign in for sharing features'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
          // _SectionHeader(title: 'Data'),
          // ListTile(
          //   leading: const Icon(Icons.delete_forever_outlined,
          //       color: Colors.red),
          //   title: const Text(
          //     'Delete all data',
          //     style: TextStyle(color: Colors.red),
          //   ),
          //   onTap: () => _confirmClearData(context),
          // ),
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

  Future<void> _clearAllData() async {
    // Data is stored on the server; no local data to delete.
  }

  void _confirmClearData(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Data'),
        content: const Text('Delete all data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been deleted.')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
