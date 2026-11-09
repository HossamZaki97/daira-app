import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';
import '../../shared/identity.dart';

enum AuthMode { login, register, forgot, confirmation }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  var _form = GlobalKey<FormState>();
  final _emailField = GlobalKey<FormFieldState<String>>();
  final _code = TextEditingController();
  final _cooldowns = <String, int>{};
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  AuthMode _mode = AuthMode.login;
  bool _busy = false,
      _sent = false,
      _visible = false,
      _verified = false,
      _resending = false;
  String get _address => _email.text.trim().toLowerCase();
  int get _seconds => _cooldowns[_address] ?? 0;
  String get _verificationCode =>
      normalizeNumber(_code.text).replaceAll(RegExp(r'[\s-]'), '');
  Timer? _timer;
  Object? _failure;
  void _change(AuthMode mode, {bool clear = false}) {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      _failure = null;
      _sent = false;
      _verified = false;
      _code.clear();
      _visible = false;
      _password.clear();
      _form = GlobalKey<FormState>();
      if (clear) {
        _name.clear();
        _email.clear();
      }
    });
  }

  void _cooldown(String email) {
    _cooldowns[email] = 60;
    if (_timer?.isActive == true) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldowns.updateAll((_, value) => value > 0 ? value - 1 : 0);
      });
      if (_cooldowns.values.every((value) => value == 0)) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (_busy || _seconds > 0 || _emailField.currentState?.validate() != true) {
      return;
    }
    final email = _address;
    setState(() {
      _busy = true;
      _resending = true;
      _failure = null;
    });
    try {
      await ref.read(apiProvider).post('resend', {
        'email': email,
      }, authenticated: false);
      if (mounted) {
        setState(() {
          _code.clear();
          _cooldown(email);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _resending = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final api = ref.read(apiProvider);
      switch (_mode) {
        case AuthMode.login:
          await ref
              .read(authProvider.notifier)
              .login(_email.text.trim(), _password.text);
        case AuthMode.register:
          await api.post('signup', {
            'name': _name.text.trim(),
            'email': _email.text.trim(),
            'password': _password.text,
          }, authenticated: false);
          if (mounted) {
            setState(() {
              _mode = AuthMode.confirmation;
              _password.clear();
              _cooldown(_address);
            });
          }
        case AuthMode.forgot:
          await api.post('forgot', {
            'email': _email.text.trim(),
          }, authenticated: false);
          if (mounted) setState(() => _sent = true);
        case AuthMode.confirmation:
          await api.post('verify_code', {
            'email': _address,
            'code': _verificationCode,
          }, authenticated: false);
          if (mounted) {
            FocusScope.of(context).unfocus();
            setState(() {
              _mode = AuthMode.login;
              _code.clear();
              _password.clear();
              _form = GlobalKey<FormState>();
              _sent = false;
              _verified = true;
            });
          }
      }
    } catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final title = switch (_mode) {
      AuthMode.login => t.signIn,
      AuthMode.register => t.signUp,
      AuthMode.forgot => t.sendReset,
      AuthMode.confirmation => t.confirmEmail,
    };
    final pageTitle = switch (_mode) {
      AuthMode.login => t.signInTitle,
      AuthMode.register => t.signUpTitle,
      AuthMode.forgot => t.recoveryTitle,
      AuthMode.confirmation => t.confirmEmail,
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const DairaMark(size: 48),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            t.appName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      pageTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    if (_mode == AuthMode.register) ...[
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: t.name,
                          counterText: '',
                        ),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : t.requiredField,
                      ),
                      const SizedBox(height: 12),
                    ],
                    KeyedSubtree(
                      key: const Key('email'),
                      child: TextFormField(
                        key: _emailField,
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(labelText: t.email),
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) {
                          setState(() {
                            _verified = false;
                            if (_mode == AuthMode.confirmation) {
                              _code.clear();
                              _failure = null;
                            }
                          });
                        },
                        validator: (value) =>
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value?.trim() ?? '')
                            ? null
                            : t.invalidEmail,
                      ),
                    ),
                    if (_mode == AuthMode.login ||
                        _mode == AuthMode.register) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('password'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: !_visible,
                        decoration: InputDecoration(
                          labelText: t.password,
                          suffixIcon: IconButton(
                            tooltip: t.password,
                            onPressed: _busy
                                ? null
                                : () => setState(() => _visible = !_visible),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                        ),
                        validator: (value) =>
                            (value?.length ?? 0) >=
                                (_mode == AuthMode.register ? 8 : 1)
                            ? null
                            : t.passwordHint,
                      ),
                    ],
                    if (_mode == AuthMode.login)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => _change(AuthMode.forgot),
                          child: Text(t.forgotPassword),
                        ),
                      ),
                    if (_mode == AuthMode.confirmation) ...[
                      const SizedBox(height: 16),
                      Text(t.neutralEmail),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('verification-code'),
                        controller: _code,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        autocorrect: false,
                        enableSuggestions: false,
                        maxLength: 12,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9٠-٩۰-۹\s-]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: t.emailVerificationCode,
                          counterText: '',
                          helperText: t.codeValidity,
                        ),
                        validator: (_) =>
                            RegExp(r'^[0-9]{8}$').hasMatch(_verificationCode)
                            ? null
                            : t.codeFormat,
                      ),
                    ],
                    if (_verified)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(t.emailVerifiedLogin),
                        ),
                      ),
                    if (_sent)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(t.resetSent),
                        ),
                      ),
                    if (_failure != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            errorText(t, _failure!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      key: const Key('submit'),
                      label: _mode == AuthMode.confirmation
                          ? t.verifyCode
                          : title,
                      loading: _busy && !_resending,
                      onPressed: _busy ? null : _submit,
                    ),
                    if (_mode == AuthMode.confirmation)
                      TextButton.icon(
                        key: const Key('resend-confirmation'),
                        onPressed: _busy || _seconds > 0 ? null : _resend,
                        icon: _resending
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.mark_email_unread_outlined,
                                size: 18,
                              ),
                        label: Text(
                          _seconds > 0 ? t.resendCountdown(_seconds) : t.resend,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _change(
                              _mode == AuthMode.login
                                  ? AuthMode.register
                                  : AuthMode.login,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _mode == AuthMode.login ? t.signUp : t.signIn,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (_mode == AuthMode.login ||
                        _mode == AuthMode.forgot) ...[
                      const Divider(height: 28),
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _change(AuthMode.confirmation),
                        icon: const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                        ),
                        label: Text(
                          t.continueVerification,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (_mode == AuthMode.confirmation)
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _change(AuthMode.forgot),
                            child: Text(t.forgotPassword),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _change(AuthMode.register, clear: true),
                            child: Text(t.useAnotherEmail),
                          ),
                        ],
                      ),
                    if (ref.watch(authProvider).error != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : ref.read(authProvider.notifier).restore,
                        child: Text(t.retry),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
