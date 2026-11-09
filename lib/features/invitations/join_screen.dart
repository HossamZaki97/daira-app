import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config.dart';
import '../../core/models/circle.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';
import '../state.dart';
import 'invite_sheet.dart';

/// Join a circle with the code the organizer shared: enter it, see what it is, accept.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({this.code, super.key});
  final String? code;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.code == null ? '' : formatInviteCode(widget.code!));
  InvitationPreview? _preview;
  String? _validCode;
  bool _busy = false;
  Object? _error;

  /// One key for this acceptance, reused if the person retries after a network error.
  final _commandId = newCommandId();

  @override
  void initState() {
    super.initState();
    if (widget.code != null) WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    final code = normalizeInviteCode(_code.text)!;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await ref.read(circlesRepositoryProvider).previewInvitation(code);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _validCode = code;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() async {
    final preview = _preview;
    final code = _validCode;
    if (preview == null || code == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final circleId = await ref.read(circlesRepositoryProvider).acceptInvitation(code, preview.id, _commandId);
      refreshLists(ref.invalidate);
      if (!mounted) return;
      showToast(context, context.l10n.joinedCircle(preview.circle), tone: Tone.success);
      context.pushReplacement(Routes.circle(circleId));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(AppLocalizations t, Object error) {
    if (error is ApiException) {
      switch (error.code) {
        case 'invalid_code':
        case 'revoked':
        case 'accepted':
          return t.inviteInvalid;
        case 'expired':
          return t.inviteExpired;
        case 'already_member':
        case 'member_linked':
          return t.inviteAlreadyMember;
        case 'feature_disabled':
          return t.featureDisabled;
      }
    }
    return t.error(error);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final preview = _preview;
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(t.joinWithCode)),
      body: Form(
        key: _form,
        child: PageBody(
          children: [
            if (preview == null) ...[
              const SizedBox(height: Space.md),
              Text(t.joinTitle, style: context.text.titleLarge),
              const SizedBox(height: Space.xs),
              Text(t.joinBody, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
              const SizedBox(height: Space.xl),
              if (error != null) ...[InlineBanner(title: _message(t, error), tone: Tone.danger), const SizedBox(height: Space.md)],
              AppTextField(
                controller: _code,
                label: t.inviteCode,
                hint: 'ABCD-EFGH-2345',
                icon: AppIcons.ticket,
                textDirection: TextDirection.ltr,
                enabled: !_busy,
                autofocus: widget.code == null,
                validator: (v) => normalizeInviteCode(v ?? '') == null ? t.inviteCodeHint : null,
                onSubmitted: (_) => _check(),
              ),
              const SizedBox(height: Space.xl),
              AppButton(label: t.continueAction, loading: _busy, onPressed: _check),
            ] else ...[
              const SizedBox(height: Space.md),
              Text(t.joinPreviewTitle, style: context.text.titleLarge),
              const SizedBox(height: Space.md),
              if (error != null) ...[InlineBanner(title: _message(t, error), tone: Tone.danger), const SizedBox(height: Space.md)],
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preview.circle, style: context.text.titleLarge?.copyWith(color: context.colors.onHero)),
                    Text(t.organizedBy(preview.organizer), style: context.text.bodySmall?.copyWith(color: context.colors.onHeroMuted)),
                    const SizedBox(height: Space.md),
                    AmountText(preview.amount, large: true, color: context.colors.onHero),
                    Text(cadenceLabel(t, preview.cadence, preview.interval),
                        style: context.text.bodySmall?.copyWith(color: context.colors.onHeroMuted)),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(leading: const Icon(AppIcons.user), title: Text(t.joinAs), subtitle: Text(preview.member)),
                    if (preview.turn != null)
                      ListTile(
                        leading: const Icon(AppIcons.turn),
                        title: Text(t.yourTurnRound(preview.turn!)),
                        subtitle: preview.turnDate == null ? null : Text(t.date(preview.turnDate!)),
                      ),
                    if (preview.expiresAt != null)
                      ListTile(
                        leading: const Icon(AppIcons.clock),
                        title: Text(t.expiresOn(t.date(preview.expiresAt!))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              Text(t.joinNote, style: context.text.bodySmall),
              const SizedBox(height: Space.xl),
              AppButton(label: t.joinCircle, loading: _busy, onPressed: _accept),
              const SizedBox(height: Space.xs),
              AppButton.text(label: t.cancel, onPressed: () => context.pop()),
            ],
          ],
        ),
      ),
    );
  }
}
