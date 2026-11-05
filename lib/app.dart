import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_it/services/device_token_service.dart';

import 'design_system/components/dialogs.dart';
import 'navigation/deep_link_parser.dart';
import 'providers/core_providers.dart';
import 'providers/expense_provider.dart';
import 'providers/followed_piggies_provider.dart';
import 'providers/session_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/subscribe_screen.dart';
import 'services/deep_link_service.dart';
import 'theme/app_theme.dart';
import 'widgets/main_navigation_shell.dart';
import 'widgets/app_loading_indicator.dart';

// Keep links received on the public welcome screen until authentication succeeds.
final _pendingLinkProvider = StateProvider<Uri?>((ref) => null);

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
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> _captureLinks() async {
    try {
      final service = DeepLinkService();
      _linkSubscription = service.uriStream.listen(
        (uri) {
          if (mounted) ref.read(_pendingLinkProvider.notifier).state = uri;
        },
        onError: (Object error) {
          debugPrint('[deeplink] $error');
        },
      );
      final initial = await service.getInitialUri();
      if (mounted &&
          initial != null &&
          ref.read(_pendingLinkProvider) == null) {
        ref.read(_pendingLinkProvider.notifier).state = initial;
      }
    } catch (error) {
      debugPrint('[deeplink] $error');
    }
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(_captureLinks());
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
      SessionStatus.failure => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not connect. Please try again.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.read(sessionNotifierProvider.notifier).init(),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      SessionStatus.ready => const MainScreen(),
      SessionStatus.unauthorized => const WelcomeScreen(),
    };
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppLoadingIndicator(),
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
  String? _openInviteToken;
  final _deepLinkParser = const DeepLinkParser();
  late final DeviceTokenService _deviceTokenService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _deviceTokenService = ref.read(deviceTokenServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // permission 은 앱 실행시 바로 요청하지 않는다.
      // if (Platform.isIOS) {
      //   _deviceTokenService?.requestPermissionAndSync();
      // }
      _deviceTokenService.initialize();
      _openPendingLink();
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

  void _openPendingLink() {
    if (!mounted) return;
    final uri = ref.read(_pendingLinkProvider);
    if (uri == null) return;
    ref.read(_pendingLinkProvider.notifier).state = null;
    unawaited(_handleDeepLink(uri));
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (!mounted) return;

    switch (_deepLinkParser.parse(uri)) {
      case TopicSubscriptionDestination(:final topicToken):
        if (_openInviteToken == topicToken) return;
        _openInviteToken = topicToken;
        try {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SubscribeScreen(topicToken: topicToken),
            ),
          );
        } finally {
          _openInviteToken = null;
        }
      case EntryDestination(:final topicId, :final entryId):
        setState(() => _currentIndex = 0);
        ref.read(selectedTopicIdProvider.notifier).state = topicId;
        await ref.read(expenseNotifierProvider.notifier).openEntry(
              topicId: topicId,
              entryId: entryId,
            );
      case EntryDateDestination(:final topicId, :final occurredAt):
        setState(() => _currentIndex = 0);
        ref.read(selectedTopicIdProvider.notifier).state = topicId;
        await ref.read(expenseNotifierProvider.notifier).openDate(
              topicId: topicId,
              occurredAt: occurredAt,
            );
      case null:
        debugPrint('[deeplink] Ignored unsupported link: $uri');
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
      ref.invalidate(followedPiggiesProvider);
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

    final allow = await showPiggyConfirmation(
      context: context,
      title: 'Never miss an update',
      message: 'Get notified when someone adds an expense to a shared space.',
      confirmLabel: 'Turn on',
      cancelLabel: 'Not now',
      icon: Icons.notifications_none_rounded,
      barrierDismissible: false,
    );
    if (!mounted) return;

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
    ref.listen(_pendingLinkProvider, (_, uri) {
      if (uri != null) {
        _openPendingLink();
      }
    });
    return Scaffold(
      body: MainNavigationShell(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
