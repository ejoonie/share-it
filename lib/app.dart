import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/providers/bootstrap_provider.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/bottom_nav_bar.dart';

class ShareItApp extends StatelessWidget {
  final String guestToken;

  const ShareItApp({super.key, required this.guestToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share It',
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
    );
  }
}
