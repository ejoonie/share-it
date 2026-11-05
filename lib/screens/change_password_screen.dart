import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/components/dialogs.dart';
import '../providers/session_provider.dart';
import '../widgets/verification_code_field.dart';
import '../widgets/auth_step_layout.dart';
import '../design_system/tokens.dart';

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
  final _codeController = TextEditingController();

  // Step 2 – new password
  final _passwordFormKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String? _errorMessage;

  String get _enteredCode => _codeController.text;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Step 0: request OTP ─────────────────────────────────────────────────

  Future<void> _requestCode() async {
    if (_isLoading) return;
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  // ── Step 1: verify code ──────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    if (_isLoading) return;
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
    if (_isLoading) return;
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
      if (!mounted) return;
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
      backgroundColor: PiggyColors.background,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PiggyColors.ink,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: AuthStepLayout(
            key: ValueKey(_step),
            icon: _step == 1
                ? Icons.mark_email_read_outlined
                : Icons.lock_outline_rounded,
            title: switch (_step) {
              0 => 'Change password',
              1 => 'Verify email',
              _ => 'New password'
            },
            subtitle: switch (_step) {
              0 => 'We’ll send a verification code to your account email.',
              1 => 'Enter the 6-digit code from your email.',
              _ => 'Choose a password with at least 6 characters.',
            },
            child: _buildStep(),
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
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _errorBanner(_errorMessage!),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _requestCode,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send Verification Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: _signOut,
            child: Text(
              'Sign Out',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: _deleteAccount,
            child: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showPiggyConfirmation(
      context: context,
      title: 'Delete Account',
      message:
          'This will permanently delete your account and all your data. This action cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.person_remove_outlined,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(sessionNotifierProvider.notifier).deleteAccount();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showPiggyConfirmation(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      icon: Icons.logout_rounded,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(sessionNotifierProvider.notifier).signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerificationCodeField(
          controller: _codeController,
          enabled: !_isLoading,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
          onSubmitted: (_) {
            if (!_isLoading) _verifyCode();
          },
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _errorBanner(_errorMessage!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
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
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
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
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
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
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _changePassword,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Change Password',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
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
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
