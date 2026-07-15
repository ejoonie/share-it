import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_provider.dart';

// ---------------------------------------------------------------------------
// 로그인 플로우 단계
// ---------------------------------------------------------------------------
enum _LoginStep {
  email,        // 1단계: 이메일 입력
  terms,        // 2단계(신규): 약관 동의
  chooseMethod, // 2단계(기존, 패스워드 있음): OTP vs 패스워드 선택
  otp,          // 3단계: OTP 코드 입력
  password,     // 3단계: 패스워드 입력
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

  // 로그인 전 게스트 상태를 기억해둔다
  String? _guestTokenBeforeLogin;
  bool _wasGuest = false;

  // 각 단계의 위젯을 교체한다
  Widget _buildStep() {
    return switch (_step) {
      _LoginStep.email => _EmailStep(
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
          onSuccess: ({required bool isNewUser}) => _onLoginSuccess(isNewUser: isNewUser),
          onBack: _goBack,
        ),
      _LoginStep.password => _PasswordStep(
          email: _email,
          onSuccess: ({required bool isNewUser}) => _onLoginSuccess(isNewUser: isNewUser),
          onSwitchToOtp: _onChooseOtp,
          onBack: _goBack,
        ),
    };
  }

  Future<void> _onEmailNext(String email, {required bool isNewUser, required bool hasPassword}) async {
    _email = email;
    _isNewUser = isNewUser;

    // 이메일 입력 시점에 현재 세션이 게스트인지 기록
    final sessionData = ref.read(sessionNotifierProvider).data;
    _wasGuest = sessionData?.user?.isGuest ?? false;
    if (_wasGuest) {
      _guestTokenBeforeLogin = ref.read(sessionRepositoryProvider).getCurrentToken();
    }

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
    await authRepo.requestLoginCode(_email);
    if (mounted) setState(() => _step = _LoginStep.otp);
  }

  Future<void> _onChooseOtp() async {
    await _sendOtpAndGoToStep();
  }

  void _onChoosePassword() {
    setState(() => _step = _LoginStep.password);
  }

  void _onLoginSuccess({required bool isNewUser}) {
    _handleGuestMigration(isNewUser: isNewUser);
  }

  Future<void> _handleGuestMigration({required bool isNewUser}) async {
    final guestToken = _guestTokenBeforeLogin;

    if (!_wasGuest || guestToken == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (isNewUser) {
      // 신규 가입 → 게스트 데이터 자동 이전
      try {
        await ref.read(sessionRepositoryProvider).mergeGuestData(guestToken);
      } catch (_) {
        // 이전 실패는 조용히 무시 (계정은 이미 생성됨)
      }
      if (mounted) Navigator.of(context).pop();
    } else {
      // 기존 계정 로그인 → 사용자에게 이전 여부 물어본다
      if (!mounted) return;
      final move = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Move your data?'),
          content: const Text(
            'You have data from your guest session. Would you like to move it to your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, move it'),
            ),
          ],
        ),
      );

      if (move == true) {
        try {
          await ref.read(sessionRepositoryProvider).mergeGuestData(guestToken);
        } catch (_) {
          // 조용히 무시
        }
      }

      if (mounted) Navigator.of(context).pop();
    }
  }

  void _goBack() {
    setState(() => _step = _LoginStep.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
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
  final Future<void> Function(String email, {required bool isNewUser, required bool hasPassword}) onNext;

  const _EmailStep({required this.onNext});

  @override
  ConsumerState<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends ConsumerState<_EmailStep> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final authRepo = ref.read(sessionRepositoryProvider);
      final result = await authRepo.checkEmail(_emailController.text.trim());
      await widget.onNext(
        _emailController.text.trim(),
        isNewUser: result.isNewUser,
        hasPassword: result.hasPassword,
      );
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      key: const ValueKey('email'),
      title: 'Sign in',
      subtitle: 'Enter your email to continue',
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
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: true,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Next',
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
  final VoidCallback onAgree;
  final VoidCallback onBack;

  const _TermsStep({required this.email, required this.onAgree, required this.onBack});

  @override
  State<_TermsStep> createState() => _TermsStepState();
}

class _TermsStepState extends State<_TermsStep> {
  bool _agreed = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_agreed) return;
    setState(() => _isLoading = true);
    widget.onAgree();
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      key: const ValueKey('terms'),
      title: 'Welcome!',
      subtitle: 'Please agree to the terms to create your account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'An account will be created for this email.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                children: const [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Color(0xFF3dbfa8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF3dbfa8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Create Account & Send Code',
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
class _ChooseMethodStep extends StatelessWidget {
  final String email;
  final VoidCallback onChooseOtp;
  final VoidCallback onChoosePassword;
  final VoidCallback onBack;

  const _ChooseMethodStep({
    required this.email,
    required this.onChooseOtp,
    required this.onChoosePassword,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      key: const ValueKey('chooseMethod'),
      title: 'Welcome back',
      subtitle: email,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MethodTile(
            icon: Icons.lock_outlined,
            title: 'Use Password',
            subtitle: 'Sign in with your password',
            onTap: onChoosePassword,
          ),
          const SizedBox(height: 12),
          _MethodTile(
            icon: Icons.mail_outlined,
            title: 'Send Login Code',
            subtitle: 'Get a one-time code via email',
            onTap: onChooseOtp,
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
  final VoidCallback onTap;

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
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3dbfa8).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF3dbfa8)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final authRepo = ref.read(sessionRepositoryProvider);
      final result = await authRepo.verifyLoginCode(widget.email, code);
      widget.onSuccess(isNewUser: result.isNewUser);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = 'Invalid or expired code'; });
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
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
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      key: const ValueKey('otp'),
      title: 'Enter the code',
      subtitle: 'We sent a 6-digit code to\n${widget.email}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Login code',
              prefixIcon: Icon(Icons.pin_outlined),
              hintText: '000000',
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autofocus: true,
            onChanged: (_) { if (_error != null) setState(() => _error = null); },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: 'Verify',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _resending ? null : _resend,
              child: _resending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
  final VoidCallback onSwitchToOtp;
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
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _passwordController.text;
    if (pw.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final authRepo = ref.read(sessionRepositoryProvider);
      final result = await authRepo.loginWithPassword(widget.email, pw);
      widget.onSuccess(isNewUser: result.isNewUser);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = 'Incorrect password'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      key: const ValueKey('password'),
      title: 'Enter password',
      subtitle: widget.email,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) _ErrorBanner(message: _error!),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onChanged: (_) { if (_error != null) setState(() => _error = null); },
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
              onPressed: widget.onSwitchToOtp,
              child: const Text('Use a login code instead'),
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
class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: (isLoading || !enabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3dbfa8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
