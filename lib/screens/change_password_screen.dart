import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_provider.dart';

/// Three-step password change flow:
///   1. Request OTP (step 0)
///   2. Enter 6-digit code (step 1)
///   3. Enter new password + confirm (step 2)
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  int _step = 0;

  // Step 1 – code entry
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(6, (_) => FocusNode());

  // Step 2 – new password
  final _passwordFormKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String? _errorMessage;

  String get _enteredCode =>
      _codeControllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Step 0: request OTP ─────────────────────────────────────────────────

  Future<void> _requestCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(sessionRepositoryProvider).requestPasswordChange();
      if (!mounted) return;
      setState(() {
        _step = 1;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  // ── Step 1: verify code ──────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    if (_enteredCode.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    // Move to step 2 – actual password validation happens on submit
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _step = 2;
      _isLoading = false;
    });
  }

  // ── Step 2: change password ──────────────────────────────────────────────

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(sessionRepositoryProvider).changePassword(
            code: _enteredCode,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Color(0xFF43A047),
        ),
      );
      Navigator.pop(context);
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
        // If the code was invalid, go back to code entry
        if (e.toString().contains('Invalid or expired')) _step = 1;
      });
    }
  }

  String _friendlyError(Exception e) {
    final msg = e.toString();
    if (msg.contains('Invalid or expired')) {
      return 'Invalid or expired code. Please request a new one.';
    }
    if (msg.contains('confirmation')) {
      return 'Passwords do not match.';
    }
    if (msg.contains('503') || msg.contains('Failed to send')) {
      return 'Failed to send email. Please try again later.';
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildRequestStep(),
      1 => _buildCodeStep(),
      2 => _buildPasswordStep(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Widgets ─────────────────────────────────────────────────────────────

  Widget _buildRequestStep() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_outlined,
            size: 60, color: Color(0xFF5E81AC)),
        const SizedBox(height: 20),
        const Text(
          'Change Password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We will send a verification code to your registered email address.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _errorBanner(_errorMessage!),
        ],
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestCode,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Send Verification Code',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 60, color: Color(0xFF5E81AC)),
        const SizedBox(height: 20),
        const Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to your email.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            return _CodeBox(
              controller: _codeControllers[i],
              focusNode: _codeFocusNodes[i],
              onChanged: (val) {
                if (val.length == 1 && i < 5) {
                  _codeFocusNodes[i + 1].requestFocus();
                } else if (val.isEmpty && i > 0) {
                  _codeFocusNodes[i - 1].requestFocus();
                }
              },
            );
          }),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _errorBanner(_errorMessage!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Next',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _step = 0;
              _errorMessage = null;
            }),
            child: const Text('Resend code'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outlined, size: 60, color: Color(0xFF5E81AC)),
          const SizedBox(height: 20),
          const Text(
            'Set New Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a strong password (at least 6 characters).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please enter a password';
              }
              if (v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _changePassword(),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please confirm your password';
              }
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _errorBanner(_errorMessage!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Change Password',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        onChanged: onChanged,
      ),
    );
  }
}
