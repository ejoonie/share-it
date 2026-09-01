import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_it/services/device_token_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // iOS 14+: UIWindow가 준비된 첫 프레임에서 ATT 권한 요청
      // runApp() 전에 호출하면 window가 없어 다이얼로그가 표시되지 않는다
      try {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        debugPrint('[ATT] current status: $status');
        if (status == TrackingStatus.notDetermined) {
          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // 다이얼로그가 production 에서 안뜰때가 있음
          final result =
              await AppTrackingTransparency.requestTrackingAuthorization();
          debugPrint('[ATT] requested, result: $result');
        }
      } catch (e) {
        debugPrint('[ATT] error: $e');
      }
      // ATT 요청 후 세션 초기화
      if (mounted) ref.read(sessionNotifierProvider.notifier).init();
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
    return Scaffold(
      body: Center(
        child: Image.asset('assets/playstore.png', width: 256, height: 256),
      ),
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
                const Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: Color(0xFF3dbfa8),
                ),
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
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                      // 로그인 성공 후 데이터 리프레시
                      if (context.mounted) {
                        ref.read(sessionNotifierProvider.notifier).reload();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mint,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(sessionNotifierProvider.notifier)
                          .continueAsGuest();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(fontSize: 16),
                    ),
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
  late final DeviceTokenService _deviceTokenService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _deviceTokenService = ref.read(deviceTokenServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();

      // permission 은 앱 실행시 바로 요청하지 않는다.
      // if (Platform.isIOS) {
      //   _deviceTokenService?.requestPermissionAndSync();
      // }
      _deviceTokenService.initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deviceTokenService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.resumed) {
    //   _syncNotificationPermission();
    // }
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
    } else if (index == 1) {
      _promptForNotificationPermission(); // share tab 처음 진입할때
    } else if (index == 2) {
      // Settings data is managed by settingsNotifierProvider (autoDispose).
      // Incrementing settingsRefreshProvider signals the screen to reload,
      // which is also used when returning from TopicDetailScreen after an edit.
      ref.read(settingsRefreshProvider.notifier).update((n) => n + 1);
    }
  }

  Future<void> _promptForNotificationPermission() async {
    final storage = ref.read(notificationOptInStorageProvider);
    if (!mounted || storage.hasResponded) {
      return;
    }

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Never miss an update'),
        content: const Text(
          'Get notified when someone adds an expense to a shared space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );

    // 사용자가 응답을 했는지 로컬에 기록
    storage.markAsResponded();

    // 결과를 서버에 기록
    await ref
        .read(sessionRepositoryProvider)
        .updateNotificationsEnabled(allow ?? false);

    // 승인했을 경우 다이얼로그 호출
    // 토큰은 결과에 관계없이 언제나 전송
    if (allow == true) {
      await _deviceTokenService.requestPermissionAndSync(); // handles iOS
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
