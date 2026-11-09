import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../settings/preference_controls.dart';

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Sign-in. (Sign-up, email confirmation and password reset arrive with the
/// full screens in the next phase; the API layer already supports them.)
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _emailField = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _emailField.dispose();
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
      await ref.read(authRepositoryProvider).login(_emailField.text.trim().toLowerCase(), _password.text);
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
    final colors = context.colors;
    final notice = ref.watch(sessionNoticeProvider);
    final error = _error;
    return Scaffold(
      appBar: AppBar(actions: const [LanguageButton(), SizedBox(width: Space.xs)]),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: PageBody(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.md, Space.xl, Space.xxl),
              children: [
                const Align(alignment: AlignmentDirectional.centerStart, child: DairaMark(size: 56)),
                const SizedBox(height: Space.xl),
                Text(t.signInTitle, style: context.text.displaySmall),
                const SizedBox(height: Space.xs),
                Text(t.signInBody, style: context.text.bodyLarge?.copyWith(color: colors.textMuted)),
                const SizedBox(height: Space.xl),
                if (error != null || notice != null) ...[
                  InlineBanner(
                    tone: Tone.danger,
                    title: error != null
                        ? t.error(error)
                        : notice == ApiSignal.suspended
                        ? t.errorSuspended
                        : t.errorSessionEnded,
                  ),
                  const SizedBox(height: Space.md),
                ],
                AppTextField(
                  controller: _emailField,
                  label: t.email,
                  icon: AppIcons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email, AutofillHints.username],
                  textDirection: TextDirection.ltr,
                  enabled: !_busy,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return t.requiredField;
                    return _email.hasMatch(value) ? null : t.invalidEmail;
                  },
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
                const SizedBox(height: Space.xl),
                AppButton(label: t.signIn, loading: _busy, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
