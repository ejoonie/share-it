import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/core_providers.dart';
import 'providers/expense_provider.dart';
import 'providers/session_provider.dart';
import 'screens/bootstrap_debug_screen.dart';
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

/// Kicks off the session sequence and routes to the appropriate screen.
class _SessionGate extends ConsumerStatefulWidget {
  const _SessionGate();

  @override
  ConsumerState<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<_SessionGate> {
  @override
  void initState() {
    super.initState();
    // Kick off session init after the first frame so providers are ready.
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

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotificationPermission();
    }
  }

  Future<void> _syncNotificationPermission() async {
    final status = await Permission.notification.status;
    final granted = status.isGranted;
    try {
      await ref.read(sessionRepositoryProvider).updateNotificationsEnabled(granted);
    } catch (_) {
      // 네트워크 오류 등 무시 — 다음 resume 시 재시도됨
    }
  }

  Future<void> _initDeepLinks() async {
    // 앱이 종료된 상태에서 딥링크로 열린 경우
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null && mounted) {
      _handleDeepLink(initialUri);
    }

    // 앱이 백그라운드에 있다가 딥링크로 포그라운드로 온 경우
    _appLinks.uriLinkStream.listen((uri) {
      if (mounted) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // https://sharablepiggy.com/topics/{token}
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'topics') {
      final token = segments[1];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SubscribeScreen(topicToken: token),
        ),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _loadTab(index);
  }

  void _loadTab(int index) {
    // Expense (index 0) auto-loads via ExpenseNotifier constructor when
    // entryRepositoryProvider becomes available after session load.
    // Tapping the tab triggers an explicit refresh.
    if (index == 0) {
      ref.read(expenseNotifierProvider.notifier).load();
    } else if (index == 2) {
      // Settings data is managed by settingsNotifierProvider (autoDispose).
      // Incrementing settingsRefreshProvider signals the screen to reload,
      // which is also used when returning from TopicDetailScreen after an edit.
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
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: 'bootstrap_debug_fab',
              tooltip: 'Bootstrap Debug',
              backgroundColor: const Color(0xFF313244),
              foregroundColor: const Color(0xFF89B4FA),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BootstrapDebugScreen(),
                  ),
                );
              },
              child: const Icon(Icons.bug_report_outlined),
            )
          : null,
    );
  }
}
