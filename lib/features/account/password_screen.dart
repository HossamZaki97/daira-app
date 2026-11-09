import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';

/// Change password. Other devices are signed out by the server; this one stays signed in.
class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  int get _min => ref.read(settingsProvider)?.limits.minPassword ?? 8;

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).changePassword(_current.text, _next.text);
      if (!mounted) return;
      showToast(context, context.l10n.passwordChanged, tone: Tone.success);
      context.pop();
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
    final message = error is ApiException && error.code == 'invalid_credentials'
        ? t.wrongPassword
        : error is ApiException && error.code == 'weak_password'
        ? t.errorWeakPassword(_min)
        : error == null
        ? null
        : t.error(error);
    return Scaffold(
      appBar: AppBar(title: Text(t.changePassword)),
      body: Form(
        key: _form,
        child: AutofillGroup(
          child: PageBody(
            children: [
              const SizedBox(height: Space.md),
              Text(t.changePasswordBody, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
              const SizedBox(height: Space.lg),
              if (message != null) ...[InlineBanner(title: message, tone: Tone.danger), const SizedBox(height: Space.md)],
              AppTextField(
                controller: _current,
                label: t.currentPassword,
                icon: AppIcons.password,
                password: true,
                showPasswordLabel: t.showPassword,
                hidePasswordLabel: t.hidePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').isEmpty ? t.requiredField : null,
              ),
              const SizedBox(height: Space.md),
              AppTextField(
                controller: _next,
                label: t.newPassword,
                icon: AppIcons.password,
                password: true,
                showPasswordLabel: t.showPassword,
                hidePasswordLabel: t.hidePassword,
                helper: t.passwordHint(_min),
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => (v ?? '').length < _min ? t.passwordHint(_min) : null,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: Space.xl),
              AppButton(label: t.save, loading: _busy, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
