import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_provider.dart';
import '../design_system/tokens.dart';
import '../utils/open_support_link.dart';
import '../widgets/verification_code_field.dart';
import '../widgets/auth_step_layout.dart';

// ---------------------------------------------------------------------------
// 로그인 플로우 단계
// ---------------------------------------------------------------------------
enum _LoginStep {
  email, // 1단계: 이메일 입력
  terms, // 2단계(신규): 약관 동의
  chooseMethod, // 2단계(기존, 패스워드 있음): OTP vs 패스워드 선택
  otp, // 3단계: OTP 코드 입력
  password, // 3단계: 패스워드 입력
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _LoginStep _step = _LoginStep.email;
  String _email = '';
  bool _isNewUser = false;

  // 각 단계의 위젯을 교체한다
  Widget _buildStep() {
    return switch (_step) {
      _LoginStep.email => _EmailStep(
          initialEmail: _email,
          onNext: _onEmailNext,
        ),
      _LoginStep.terms => _TermsStep(
          email: _email,
          onAgree: _onTermsAgreed,
          onBack: _goBack,
        ),
      _LoginStep.chooseMethod => _ChooseMethodStep(
          email: _email,
          onChooseOtp: _onChooseOtp,
          onChoosePassword: _onChoosePassword,
          onBack: _goBack,
        ),
      _LoginStep.otp => _OtpStep(
          email: _email,
          isNewUser: _isNewUser,
          onSuccess: ({required bool isNewUser}) =>
              _onLoginSuccess(isNewUser: isNewUser),
          onBack: _goBack,
        ),
      _LoginStep.password => _PasswordStep(
          email: _email,
          onSuccess: ({required bool isNewUser}) =>
              _onLoginSuccess(isNewUser: isNewUser),
          onSwitchToOtp: _onChooseOtp,
          onBack: _goBack,
        ),
    };
  }

  Future<void> _onEmailNext(
    String email, {
    required bool isNewUser,
    required bool hasPassword,
  }) async {
    _email = email;
    _isNewUser = isNewUser;

    if (isNewUser) {
      setState(() => _step = _LoginStep.terms);
    } else if (hasPassword) {
      setState(() => _step = _LoginStep.chooseMethod);
    } else {
      // 기존 유저, 패스워드 없음 → OTP 바로 전송
      await _sendOtpAndGoToStep();
    }
  }

  Future<void> _onTermsAgreed() async {
    // 약관 동의 후 OTP 전송
    await _sendOtpAndGoToStep();
  }

  Future<void> _sendOtpAndGoToStep() async {
    final authRepo = ref.read(sessionRepositoryProvider);
    final requestedStep = _step;
    await authRepo.requestLoginCode(_email);
    if (mounted && _step == requestedStep) {
      setState(() => _step = _LoginStep.otp);
    }
  }

  Future<void> _onChooseOtp() async {
    await _sendOtpAndGoToStep();
  }

  void _onChoosePassword() {
    setState(() => _step = _LoginStep.password);
  }

  void _onLoginSuccess({required bool isNewUser}) {
    if (mounted) Navigator.of(context).pop(true);
  }

  void _goBack() {
    setState(() => _step = _LoginStep.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PiggyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sharable Piggy', style: PiggyType.label),
        foregroundColor: PiggyColors.ink,
        leading: _step == _LoginStep.email
            ? const CloseButton()
            : BackButton(onPressed: _goBack),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildStep(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1단계: 이메일 입력
// ---------------------------------------------------------------------------
class _EmailStep extends ConsumerStatefulWidget {
  final Future<void> Function(
    String email, {
    required bool isNewUser,
    required bool hasPassword,
  }) onNext;

  final String initialEmail;
  const _EmailStep({required this.onNext, required this.initialEmail});

  @override
  ConsumerState<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends ConsumerState<_EmailStep> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController =
      TextEditingController(text: widget.initialEmail);
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(sessionRepositoryProvider);
      final result = await authRepo.checkEmail(_emailController.text.trim());
      if (!mounted) return;
      await widget.onNext(
        _emailController.text.trim(),
        isNewUser: result.isNewUser,
        hasPassword: result.hasPassword,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not continue. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthStepLayout(
      key: const ValueKey('email'),
      icon: Icons.savings_outlined,
      title: 'Sign in',
      subtitle: 'Sign in or create an account with your email.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) _ErrorBanner(message: _error!),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'example@email.com',
              ),
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: true,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!v.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Continue',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2단계(신규): 약관 동의
// ---------------------------------------------------------------------------
class _TermsStep extends StatefulWidget {
  final String email;
  final Future<void> Function() onAgree;
  final VoidCallback onBack;

  const _TermsStep({
    required this.email,
    required this.onAgree,
    required this.onBack,
  });

  @override
  State<_TermsStep> createState() => _TermsStepState();
}

class _TermsStepState extends State<_TermsStep> {
  bool _agreed = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_agreed || _isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.onAgree();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send the code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthStepLayout(
      key: const ValueKey('terms'),
      icon: Icons.favorite_border_rounded,
      title: 'Create account',
      subtitle: 'One last thing before we create your account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PiggyColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'An account will be created for this email.',
                  style: TextStyle(color: PiggyColors.secondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null) _ErrorBanner(message: _error!),
          CheckboxListTile(
            value: _agreed,
            onChanged:
                _isLoading ? null : (v) => setState(() => _agreed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: PiggyColors.ink),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: PiggyColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => openSupportLink(
                            context,
                            'https://sharablepiggy.com/terms',
                          ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: PiggyColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => openSupportLink(
                            context,
                            'https://sharablepiggy.com/privacy',
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Agree & continue',
            isLoading: _isLoading,
            enabled: _agreed,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2단계(기존, 패스워드 있음): 인증 방법 선택
// ---------------------------------------------------------------------------
class _ChooseMethodStep extends StatefulWidget {
  final String email;
  final Future<void> Function() onChooseOtp;
  final VoidCallback onChoosePassword;
  final VoidCallback onBack;

  const _ChooseMethodStep({
    required this.email,
    required this.onChooseOtp,
    required this.onChoosePassword,
    required this.onBack,
  });

  @override
  State<_ChooseMethodStep> createState() => _ChooseMethodStepState();
}

class _ChooseMethodStepState extends State<_ChooseMethodStep> {
  bool _sending = false;
  String? _error;
  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onChooseOtp();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send the code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthStepLayout(
      key: const ValueKey('chooseMethod'),
      icon: Icons.waving_hand_outlined,
      title: 'Welcome back',
      subtitle: widget.email,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          _MethodTile(
            icon: Icons.lock_outlined,
            title: 'Use Password',
            subtitle: 'Sign in with your password',
            onTap: _sending ? null : widget.onChoosePassword,
          ),
          const SizedBox(height: 12),
          _MethodTile(
            icon: Icons.mail_outlined,
            title: _sending ? 'Sending code…' : 'Email me a code',
            subtitle: 'Get a one-time code via email',
            onTap: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PiggyColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PiggyColors.accent.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: PiggyColors.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PiggyColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PiggyColors.muted),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3단계: OTP 코드 입력
// ---------------------------------------------------------------------------
class _OtpStep extends ConsumerStatefulWidget {
  final String email;
  final bool isNewUser;
  final void Function({required bool isNewUser}) onSuccess;
  final VoidCallback onBack;

  const _OtpStep({
    required this.email,
    required this.isNewUser,
    required this.onSuccess,
    required this.onBack,
  });

  @override
  ConsumerState<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends ConsumerState<_OtpStep> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || _resending) return;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authRepo = ref.read(sessionRepositoryProvider);
      final result = await authRepo.verifyLoginCode(widget.email, code);
      if (mounted) widget.onSuccess(isNewUser: result.isNewUser);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid or expired code';
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_resending || _isLoading) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final authRepo = ref.read(sessionRepositoryProvider);
      await authRepo.requestLoginCode(widget.email);
      if (mounted) {
        setState(() => _resending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code sent again')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resending = false;
          _error = 'Could not resend the code. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthStepLayout(
      key: const ValueKey('otp'),
      icon: Icons.mark_email_read_outlined,
      title: 'Verify email',
      subtitle: 'We sent a 6-digit code to\n${widget.email}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          VerificationCodeField(
            controller: _codeController,
            enabled: !_isLoading && !_resending,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Verify & continue',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: (_resending || _isLoading) ? null : _resend,
              child: _resending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Didn't receive it? Send again"),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3단계: 패스워드 입력
// ---------------------------------------------------------------------------
class _PasswordStep extends ConsumerStatefulWidget {
  final String email;
  final void Function({required bool isNewUser}) onSuccess;
  final Future<void> Function() onSwitchToOtp;
  final VoidCallback onBack;

  const _PasswordStep({
    required this.email,
    required this.onSuccess,
    required this.onSwitchToOtp,
    required this.onBack,
  });

  @override
  ConsumerState<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends ConsumerState<_PasswordStep> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  bool _sendingCode = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || _sendingCode) return;
    final pw = _passwordController.text;
    if (pw.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authRepo = ref.read(sessionRepositoryProvider);
      final result = await authRepo.loginWithPassword(widget.email, pw);
      if (mounted) widget.onSuccess(isNewUser: result.isNewUser);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Incorrect password';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthStepLayout(
      key: const ValueKey('password'),
      icon: Icons.lock_outline_rounded,
      title: 'Enter password',
      subtitle: widget.email,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          TextFormField(
            controller: _passwordController,
            autofillHints: const [AutofillHints.password],
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_isLoading && !_sendingCode,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Sign In',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: (_isLoading || _sendingCode)
                  ? null
                  : () async {
                      setState(() {
                        _sendingCode = true;
                        _error = null;
                      });
                      try {
                        await widget.onSwitchToOtp();
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => _error =
                                'Could not send the code. Please try again.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _sendingCode = false);
                      }
                    },
              child: Text(
                _sendingCode ? 'Sending code…' : 'Email me a code instead',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 공통 레이아웃
// ---------------------------------------------------------------------------
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: (isLoading || !enabled) ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PiggyColors.errorSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: PiggyColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: PiggyColors.error,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
