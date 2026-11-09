import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';

enum AuthMode { login, register, forgot, confirmation }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  var _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  AuthMode _mode = AuthMode.login;
  bool _busy = false, _sent = false, _visible = false;
  int _seconds = 0;
  Timer? _timer;
  Object? _failure;
  void _change(AuthMode mode, {bool clear = false}) {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      _failure = null;
      _sent = false;
      _visible = false;
      _password.clear();
      _form = GlobalKey<FormState>();
      if (clear) {
        _name.clear();
        _email.clear();
      }
    });
  }

  void _cooldown() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) timer.cancel();
    });
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
              _cooldown();
            });
          }
        case AuthMode.forgot:
          await api.post('forgot', {
            'email': _email.text.trim(),
          }, authenticated: false);
          if (mounted) setState(() => _sent = true);
        case AuthMode.confirmation:
          if (_seconds > 0) return;
          await api.post('resend', {
            'email': _email.text.trim(),
          }, authenticated: false);
          if (mounted) setState(_cooldown);
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
                    Text(
                      t.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 24),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    if (_mode == AuthMode.register) ...[
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        maxLength: 100,
                        decoration: InputDecoration(labelText: t.name),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : t.requiredField,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const Key('email'),
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: t.email),
                      validator: (value) =>
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value?.trim() ?? '')
                          ? null
                          : t.invalidEmail,
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
                    if (_mode == AuthMode.confirmation)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(t.neutralEmail),
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
                          ? _seconds > 0
                                ? '${t.resend} ($_seconds)'
                                : t.resend
                          : title,
                      loading: _busy,
                      onPressed: _mode == AuthMode.confirmation && _seconds > 0
                          ? null
                          : _submit,
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _change(
                              _mode == AuthMode.login
                                  ? AuthMode.register
                                  : AuthMode.login,
                            ),
                      child: Text(
                        _mode == AuthMode.login ? t.signUp : t.signIn,
                      ),
                    ),
                    if (_mode == AuthMode.login ||
                        _mode == AuthMode.confirmation)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _change(AuthMode.forgot),
                        child: Text(t.forgotPassword),
                      ),
                    if (_mode == AuthMode.confirmation)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _change(AuthMode.register, clear: true),
                        child: Text(t.useAnotherEmail),
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
