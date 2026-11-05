import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens.dart';
import '../providers/session_provider.dart';
import '../widgets/app_loading_indicator.dart';
import 'login_screen.dart';

/// Public introduction: no session, bootstrap request, or sample account needed.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _openingLogin = false;
  bool _finishingLogin = false;

  Future<void> _signIn() async {
    if (_openingLogin) return;
    setState(() => _openingLogin = true);
    final route = MaterialPageRoute<bool>(builder: (_) => const LoginScreen());
    final signedIn = await Navigator.of(context).push<bool>(route);
    if (!mounted) return;
    // Replace the revealed page before the login route animates away.
    // Start the two-second session timer after that animation has finished.
    if (signedIn == true) setState(() => _finishingLogin = true);
    await route.completed;
    if (!mounted) return;
    setState(() => _openingLogin = false);
    // Dismissing login must not bootstrap or change session state.
    if (signedIn == true) {
      await ref.read(sessionNotifierProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) => _finishingLogin
      ? const Scaffold(body: AppLoadingIndicator())
      : Scaffold(
          backgroundColor: const Color(0xFFFFFAF4),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      sliver: SliverList.list(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.savings_outlined,
                                color: PiggyColors.accent,
                                size: 25,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Sharable Piggy',
                                  style: PiggyType.label,
                                ),
                              ),
                              TextButton(
                                onPressed: _openingLogin ? null : _signIn,
                                child: const Text('Sign in'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/welcome_piggy.png',
                              height: 260,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                            ),
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Little expenses.\nA clearer picture.',
                            style: TextStyle(
                              fontSize: 34,
                              height: 1.12,
                              letterSpacing: -1.2,
                              fontWeight: FontWeight.w800,
                              color: PiggyColors.ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'A cozy home for your everyday spending. Keep track on your own, or share a piggy with the people in your life.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.55,
                              color: PiggyColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _Feature(
                            icon: Icons.edit_note_rounded,
                            title: 'Catch the little things',
                            description:
                                'Keep daily expenses together in one simple ledger.',
                          ),
                          const SizedBox(height: 12),
                          const _Feature(
                            icon: Icons.people_outline_rounded,
                            title: 'Your piggy. Or ours.',
                            description:
                                'Share a space for home, a trip, or everyday life.',
                          ),
                          const SizedBox(height: 26),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                            ),
                            onPressed: _openingLogin ? null : _signIn,
                            child: const Text('Get started'),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sign in or create an account with your email.',
                            textAlign: TextAlign.center,
                            style: PiggyType.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PiggyColors.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: PiggyColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PiggyType.itemTitle),
                const SizedBox(height: 4),
                Text(description, style: PiggyType.caption),
              ],
            ),
          ),
        ],
      );
}
