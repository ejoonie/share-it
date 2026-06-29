import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/providers/bootstrap_provider.dart';
import 'core/providers/core_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/expenses/presentation/providers/expense_provider.dart';
import 'features/share/presentation/screens/subscribe_screen.dart';
import 'shared/screens/bootstrap_debug_screen.dart';
import 'shared/widgets/bottom_nav_bar.dart';

class ShareItApp extends StatelessWidget {
  final String guestToken;

  const ShareItApp({super.key, required this.guestToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharable Piggy',
      theme: AppTheme.lightTheme,
      home: _BootstrapGate(guestToken: guestToken),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Kicks off the bootstrap sequence and routes to the appropriate screen.
class _BootstrapGate extends ConsumerStatefulWidget {
  final String guestToken;

  const _BootstrapGate({required this.guestToken});

  @override
  ConsumerState<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends ConsumerState<_BootstrapGate> {
  @override
  void initState() {
    super.initState();
    // Kick off bootstrap after the first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapNotifierProvider.notifier).init(widget.guestToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bootstrapNotifierProvider);

    return switch (state.status) {
      BootstrapStatus.initial || BootstrapStatus.loading => const _LoadingScreen(),
      BootstrapStatus.success => const MainScreen(),
      BootstrapStatus.failure => _ErrorScreen(
          message: state.error ?? 'Failed to initialize app.',
          onRetry: () => ref
              .read(bootstrapNotifierProvider.notifier)
              .retry(widget.guestToken),
        ),
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

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
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
    // entryRepositoryProvider becomes available after bootstrap.
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
      // floatingActionButton: kDebugMode
      //     ? FloatingActionButton.small(
      //         heroTag: 'bootstrap_debug_fab',
      //         tooltip: 'Bootstrap Debug',
      //         backgroundColor: const Color(0xFF313244),
      //         foregroundColor: const Color(0xFF89B4FA),
      //         onPressed: () {
      //           Navigator.of(context).push(
      //             MaterialPageRoute(
      //               builder: (_) => const BootstrapDebugScreen(),
      //             ),
      //           );
      //         },
      //         child: const Icon(Icons.bug_report_outlined),
      //       )
      //     : null,
    );
  }
}
