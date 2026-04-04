import 'package:flutter/material.dart';

import '../../../auth/presentation/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currency = 'USD';
  bool _notifications = false;
  bool _darkMode = false;
  String _startDay = '월요일';

  final List<String> _currencies = ['USD', 'EUR', 'KRW', 'JPY', 'GBP'];
  final List<String> _startDays = ['월요일', '일요일'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _SectionHeader(title: '일반'),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('기본 통화'),
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
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('주 시작일'),
            trailing: DropdownButton<String>(
              value: _startDay,
              underline: const SizedBox.shrink(),
              items: _startDays
                  .map(
                    (d) => DropdownMenuItem(value: d, child: Text(d)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _startDay = v);
              },
            ),
          ),
          _SectionHeader(title: '알림'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('알림'),
            subtitle: const Text('지출 알림을 받습니다'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          _SectionHeader(title: '테마'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('다크 모드'),
            subtitle: const Text('어두운 테마 사용'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          _SectionHeader(title: '계정'),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('로그인'),
            subtitle: const Text('공유 기능을 위한 로그인'),
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
          _SectionHeader(title: '데이터'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: Colors.red),
            title: const Text(
              '모든 데이터 삭제',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmClearData(context),
          ),
          _SectionHeader(title: '정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('버전'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 삭제'),
        content: const Text('모든 데이터를 삭제할까요? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
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
