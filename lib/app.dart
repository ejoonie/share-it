import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/core_providers.dart';
import 'providers/expense_provider.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/subscribe_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';

class ShareItApp extends StatelessWidget {
  const ShareItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharable Piggy',
      theme: AppTheme.lightTheme,
      home: const _SessionGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SessionGate extends ConsumerStatefulWidget {
  const _SessionGate();

  @override
  ConsumerState<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<_SessionGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionNotifierProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionNotifierProvider);

    return switch (state.status) {
      SessionStatus.loading => const _LoadingScreen(),
      SessionStatus.ready => const MainScreen(),
      SessionStatus.unauthorized => const _UnauthorizedScreen(),
    };
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _UnauthorizedScreen extends ConsumerWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mint = const Color(0xFF3dbfa8);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Color(0xFF3dbfa8)),
                const SizedBox(height: 20),
                const Text(
                  'Session expired',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please sign in again or continue as a guest.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      // 로그인 성공 후 데이터 리프레시
                      if (context.mounted) {
                        ref.read(sessionNotifierProvider.notifier).reload();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(sessionNotifierProvider.notifier).continueAsGuest();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue as Guest', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  Future<void> _initDeepLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null && mounted) {
      _handleDeepLink(initialUri);
    }
    _appLinks.uriLinkStream.listen((uri) {
      if (mounted) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'topics') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SubscribeScreen(topicToken: segments[1]),
        ),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      ref.read(expenseNotifierProvider.notifier).load();
    } else if (index == 2) {
      ref.read(settingsRefreshProvider.notifier).update((n) => n + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
