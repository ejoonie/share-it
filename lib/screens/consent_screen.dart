import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../providers/session_provider.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const ConsentScreen({super.key, required this.user});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _canProceed => _agreedToTerms && _agreedToPrivacy;

  Future<void> _accept() async {
    if (!_canProceed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(sessionRepositoryProvider).acceptTerms();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Share It!'),
          backgroundColor: Color(0xFF43A047),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.waving_hand_outlined,
                  size: 60, color: Color(0xFF5E81AC)),
              const SizedBox(height: 20),
              Text(
                'Hello, ${widget.user.nickName}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Before you get started, please review and accept our terms.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 14),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: open terms URL
                                  },
                              ),
                            ],
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      CheckboxListTile(
                        value: _agreedToPrivacy,
                        onChanged: (v) =>
                            setState(() => _agreedToPrivacy = v ?? false),
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 14),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: open privacy policy URL
                                  },
                              ),
                            ],
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],

              const Spacer(),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_canProceed && !_isLoading) ? _accept : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
