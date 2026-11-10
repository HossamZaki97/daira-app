import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../core/push.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';
import '../settings/preference_controls.dart';

/// Profile, preferences, security, help, sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final profile = ref.watch(sessionProvider)?.profile;
    final content = ref.watch(settingsProvider)?.content ?? const <String>[];
    final info = ref.watch(clientInfoProvider);
    Widget group(List<Widget> rows) => AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(indent: 56),
            row,
          ],
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.tabAccount)),
      body: PageBody(
        children: [
          AppCard(
            onTap: () => showAppSheet<void>(context, builder: (_) => const _NameSheet()),
            child: Row(
              children: [
                InitialsAvatar(profile?.name ?? '', size: 52, highlight: true),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? '', style: context.text.titleMedium),
                      Text(profile?.email ?? '', style: context.text.bodySmall, textDirection: TextDirection.ltr),
                    ],
                  ),
                ),
                Icon(AppIcons.edit, size: 20, color: context.colors.textMuted),
              ],
            ),
          ),
          SectionHeader(t.language),
          const LanguageSelector(),
          SectionHeader(t.appearance),
          const ThemeSelector(),
          SectionHeader(t.security),
          group([
            NavRow(icon: AppIcons.password, title: t.changePassword, onTap: () => context.push(Routes.password)),
            NavRow(icon: AppIcons.devices, title: t.signedInDevices, onTap: () => context.push(Routes.sessions)),
          ]),
          SectionHeader(t.helpAndAbout),
          group([
            if (content.contains('faq')) NavRow(icon: AppIcons.help, title: t.faq, onTap: () => context.push(Routes.content('faq'))),
            if (content.contains('help'))
              NavRow(icon: AppIcons.info, title: t.help, onTap: () => context.push(Routes.content('help'))),
            NavRow(icon: AppIcons.document, title: t.terms, onTap: () => context.push(Routes.content('terms'))),
            NavRow(icon: AppIcons.privacy, title: t.privacy, onTap: () => context.push(Routes.content('privacy'))),
          ]),
          const SizedBox(height: Space.xl),
          group([
            NavRow(
              icon: AppIcons.signOut,
              title: t.signOut,
              onTap: () async {
                final ok = await confirmDialog(context, title: t.signOutTitle, body: t.signOutBody, confirm: t.signOut);
                if (ok) await ref.read(authRepositoryProvider).logout();
              },
            ),
            NavRow(
              icon: AppIcons.delete,
              title: t.deleteAccount,
              danger: true,
              onTap: () => showAppSheet<void>(context, builder: (_) => const _DeleteSheet()),
            ),
          ]),
          const SizedBox(height: Space.lg),
          Center(child: Text(t.versionLabel(info.versionHeader), style: context.text.bodySmall)),
          if (kDebugMode)
            ValueListenableBuilder<String>(
              valueListenable: pushStatus,
              builder: (context, value, _) => Center(
                child: Text('DEBUG push: $value', style: context.text.bodySmall, textDirection: TextDirection.ltr),
              ),
            ),
        ],
      ),
    );
  }
}

class _NameSheet extends ConsumerStatefulWidget {
  const _NameSheet();

  @override
  ConsumerState<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends ConsumerState<_NameSheet> {
  late final _name = TextEditingController(text: ref.read(sessionProvider)?.profile.name);
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountRepositoryProvider).update(name: _name.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.editName, style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(t.editNameBody, style: context.text.bodySmall),
          const SizedBox(height: Space.lg),
          AppTextField(
            controller: _name,
            label: t.fullName,
            icon: AppIcons.user,
            maxLength: 100,
            autofocus: true,
            validator: (v) => (v ?? '').trim().isEmpty ? t.requiredField : null,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Space.lg),
          AppButton(label: t.save, loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

/// Deleting needs the password; the server refuses while the person is in an active circle.
class _DeleteSheet extends ConsumerStatefulWidget {
  const _DeleteSheet();

  @override
  ConsumerState<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends ConsumerState<_DeleteSheet> {
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).deleteAccount(_password.text);
      if (mounted) Navigator.pop(context);
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
    final message = error is ApiException && error.code == 'active_membership'
        ? t.deleteBlocked
        : error is ApiException && error.code == 'invalid_credentials'
        ? t.wrongPassword
        : error == null
        ? null
        : t.error(error);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.deleteAccount, style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(t.deleteBody, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
          const SizedBox(height: Space.lg),
          if (message != null) ...[InlineBanner(title: message, tone: Tone.danger), const SizedBox(height: Space.md)],
          AppTextField(
            controller: _password,
            label: t.password,
            icon: AppIcons.password,
            password: true,
            showPasswordLabel: t.showPassword,
            hidePasswordLabel: t.hidePassword,
            validator: (v) => (v ?? '').isEmpty ? t.requiredField : null,
          ),
          const SizedBox(height: Space.lg),
          AppButton(kind: ButtonKind.danger, label: t.deleteForever, loading: _busy, onPressed: _delete),
          const SizedBox(height: Space.xs),
          AppButton.text(label: t.cancel, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
