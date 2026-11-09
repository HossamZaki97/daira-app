import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../settings/preference_controls.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _validateEmail(AppLocalizations t, String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return t.requiredField;
  return _emailPattern.hasMatch(v) ? null : t.invalidEmail;
}

String _cleanEmail(TextEditingController c) => c.text.trim().toLowerCase();

/// Message for an auth failure, including the auth-only codes.
String _authError(AppLocalizations t, Object error, {int minPassword = 8}) {
  if (error is ApiException) {
    switch (error.code) {
      case 'weak_password':
        return t.errorWeakPassword(minPassword);
      case 'signup_disabled':
        return t.errorSignupDisabled;
      case 'invalid_verification_code':
        return t.errorVerificationCode;
      case 'invalid_input' when error.field == 'password':
        return t.errorWeakPassword(minPassword);
      case 'invalid_input' when error.field == 'email':
        return t.invalidEmail;
    }
  }
  return t.error(error);
}

/// Shared frame: language switch, mark, title, one sentence, then the form.
class _AuthFrame extends StatelessWidget {
  const _AuthFrame({required this.title, required this.body, required this.children, this.icon});
  final String title;
  final String body;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [LanguageButton(), SizedBox(width: Space.xs)]),
    body: SafeArea(
      child: AutofillGroup(
        child: PageBody(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.xs, Space.xl, Space.xxl),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: icon == null
                  ? const DairaMark(size: 52)
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
                      child: Icon(icon, size: 28, color: context.colors.onPrimaryContainer),
                    ),
            ),
            const SizedBox(height: Space.xl),
            Text(title, style: context.text.displaySmall),
            const SizedBox(height: Space.xs),
            Text(body, style: context.text.bodyLarge?.copyWith(color: context.colors.textMuted)),
            const SizedBox(height: Space.xl),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.md),
    child: InlineBanner(title: message, tone: Tone.danger),
  );
}

// ------------------------------------------------------------------ sign in
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({this.email, super.key});
  final String? email;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    ref.read(sessionNoticeProvider.notifier).state = null;
    try {
      await ref.read(authRepositoryProvider).login(_cleanEmail(_email), _password.text);
      // The router moves on as soon as the session exists.
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final notice = ref.watch(sessionNoticeProvider);
    final error = _error;
    return Form(
      key: _form,
      child: _AuthFrame(
        title: t.signInTitle,
        body: t.signInBody,
        children: [
          if (error != null)
            _ErrorBanner(_authError(t, error))
          else if (notice != null)
            _ErrorBanner(notice == ApiSignal.suspended ? t.errorSuspended : t.errorSessionEnded),
          AppTextField(
            controller: _email,
            label: t.email,
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            textDirection: TextDirection.ltr,
            enabled: !_busy,
            validator: (v) => _validateEmail(t, v),
          ),
          const SizedBox(height: Space.md),
          AppTextField(
            controller: _password,
            label: t.password,
            icon: AppIcons.password,
            password: true,
            showPasswordLabel: t.showPassword,
            hidePasswordLabel: t.hidePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !_busy,
            validator: (v) => (v ?? '').isEmpty ? t.requiredField : null,
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton.text(
              label: t.forgotPassword,
              onPressed: () => context.push('${Routes.forgot}?email=${Uri.encodeQueryComponent(_cleanEmail(_email))}'),
            ),
          ),
          const SizedBox(height: Space.md),
          AppButton(label: t.signIn, loading: _busy, onPressed: _submit),
          const SizedBox(height: Space.sm),
          AppButton.text(
            label: t.confirmEmailLink,
            onPressed: () => context.push('${Routes.verify}?email=${Uri.encodeQueryComponent(_cleanEmail(_email))}'),
          ),
          AppButton.text(label: t.noAccountCreate, onPressed: () => context.pushReplacement(Routes.signUp)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ sign up
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  int get _min => ref.read(settingsProvider)?.limits.minPassword ?? 8;

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _cleanEmail(_email);
    try {
      await ref.read(authRepositoryProvider).signup(
        name: _name.text.trim(),
        email: email,
        password: _password.text,
        lang: ref.read(localeProvider).languageCode,
      );
      if (mounted) context.pushReplacement('${Routes.verify}?email=${Uri.encodeQueryComponent(email)}');
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final enabled = ref.watch(settingsProvider)?.signupEnabled ?? true;
    final error = _error;
    return Form(
      key: _form,
      child: _AuthFrame(
        title: t.signUpTitle,
        body: t.signUpBody,
        children: [
          if (!enabled) _ErrorBanner(t.errorSignupDisabled),
          if (error != null) _ErrorBanner(_authError(t, error, minPassword: _min)),
          AppTextField(
            controller: _name,
            label: t.fullName,
            icon: AppIcons.user,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            maxLength: 100,
            enabled: !_busy && enabled,
            validator: (v) => (v ?? '').trim().isEmpty ? t.requiredField : null,
          ),
          const SizedBox(height: Space.md),
          AppTextField(
            controller: _email,
            label: t.email,
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            textDirection: TextDirection.ltr,
            enabled: !_busy && enabled,
            validator: (v) => _validateEmail(t, v),
          ),
          const SizedBox(height: Space.md),
          AppTextField(
            controller: _password,
            label: t.password,
            icon: AppIcons.password,
            password: true,
            showPasswordLabel: t.showPassword,
            hidePasswordLabel: t.hidePassword,
            helper: t.passwordHint(_min),
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !_busy && enabled,
            validator: (v) => (v ?? '').length < _min ? t.passwordHint(_min) : null,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Space.xl),
          AppButton(label: t.createAccount, loading: _busy, onPressed: enabled ? _submit : null),
          const SizedBox(height: Space.sm),
          Text(t.signUpTerms, textAlign: TextAlign.center, style: context.text.bodySmall),
          Center(child: AppButton.text(label: t.terms, onPressed: () => context.push(Routes.content('terms')))),
          AppButton.text(label: t.haveAccountSignIn, onPressed: () => context.pushReplacement(Routes.signIn)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ verify email
/// Enter the 8-digit code from the confirmation email (the link in the same
/// email works too). Confirming does not sign in; the person signs in next.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});
  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  bool _busy = false;
  bool _resending = false;
  int _wait = 0;
  Timer? _timer;
  Object? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _cleanEmail(_email);
    try {
      await ref.read(authRepositoryProvider).verifyCode(email, _code.text.trim());
      if (!mounted) return;
      showToast(context, context.l10n.emailConfirmed, tone: Tone.success);
      context.pushReplacement('${Routes.signIn}?email=${Uri.encodeQueryComponent(email)}');
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final t = context.l10n;
    if (_validateEmail(t, _email.text) != null) {
      _form.currentState?.validate();
      return;
    }
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(_cleanEmail(_email));
      if (!mounted) return;
      showToast(context, t.confirmationResent);
      _startWait();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startWait() {
    _timer?.cancel();
    setState(() => _wait = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _wait <= 1) {
        timer.cancel();
        if (mounted) setState(() => _wait = 0);
        return;
      }
      setState(() => _wait--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final error = _error;
    return Form(
      key: _form,
      child: _AuthFrame(
        icon: AppIcons.email,
        title: t.verifyTitle,
        body: t.verifyBody,
        children: [
          if (error != null) _ErrorBanner(_authError(t, error)),
          AppTextField(
            controller: _email,
            label: t.email,
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            enabled: !_busy,
            validator: (v) => _validateEmail(t, v),
          ),
          const SizedBox(height: Space.md),
          AppTextField(
            controller: _code,
            label: t.verificationCode,
            hint: '12345678',
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
            enabled: !_busy,
            autofocus: widget.email.isNotEmpty,
            validator: (v) => RegExp(r'^\d{8}$').hasMatch((v ?? '').trim()) ? null : t.verificationCodeHint,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Space.xl),
          AppButton(label: t.confirmEmail, loading: _busy, onPressed: _submit),
          const SizedBox(height: Space.sm),
          AppButton.secondary(
            label: _wait > 0 ? t.resendIn(_wait) : t.resendCode,
            loading: _resending,
            onPressed: _wait > 0 ? null : _resend,
          ),
          const SizedBox(height: Space.sm),
          AppButton.text(label: t.backToSignIn, onPressed: () => context.go(Routes.signIn)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ forgot password
/// Sends the reset email. The new password is chosen on the page the email
/// opens; then the person signs in here.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.email, super.key});
  final String? email;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _busy = false;
  bool _sent = false;
  Object? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_cleanEmail(_email));
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final error = _error;
    if (_sent) {
      return _AuthFrame(
        icon: AppIcons.send,
        title: t.checkEmailTitle,
        body: t.resetSentBody,
        children: [
          AppButton(
            label: t.signIn,
            onPressed: () => context.go('${Routes.signIn}?email=${Uri.encodeQueryComponent(_cleanEmail(_email))}'),
          ),
          const SizedBox(height: Space.sm),
          AppButton.text(label: t.useAnotherEmail, onPressed: () => setState(() => _sent = false)),
        ],
      );
    }
    return Form(
      key: _form,
      child: _AuthFrame(
        icon: AppIcons.password,
        title: t.forgotTitle,
        body: t.forgotBody,
        children: [
          if (error != null) _ErrorBanner(_authError(t, error)),
          AppTextField(
            controller: _email,
            label: t.email,
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            textDirection: TextDirection.ltr,
            enabled: !_busy,
            validator: (v) => _validateEmail(t, v),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Space.xl),
          AppButton(label: t.sendResetLink, loading: _busy, onPressed: _submit),
          const SizedBox(height: Space.sm),
          AppButton.text(label: t.backToSignIn, onPressed: () => context.go(Routes.signIn)),
        ],
      ),
    );
  }
}
