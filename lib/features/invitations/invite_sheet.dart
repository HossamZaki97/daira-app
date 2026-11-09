import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config.dart';
import '../../core/models/circle.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';

/// "ABCD-EFGH-2345" — easier to read aloud and type.
String formatInviteCode(String code) =>
    code.length == 12 ? '${code.substring(0, 4)}-${code.substring(4, 8)}-${code.substring(8)}' : code;

Future<void> showInviteSheet(BuildContext context, {required Circle circle, required Member member}) =>
    showAppSheet<void>(context, builder: (_) => _InviteSheet(circle: circle, member: member));

/// Organizer: create, share or revoke the single-use code that links a member
/// to an account. The server keeps only a hash, so a code is shown once.
class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet({required this.circle, required this.member});
  final Circle circle;
  final Member member;

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  Invitation? _current;
  String? _code;
  bool _loading = true;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await ref.read(circlesRepositoryProvider).invitations(widget.circle.id);
      _current = all.where((i) => i.memberId == widget.member.id).firstOrNull;
    } catch (error) {
      _error = error;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final invitation = await ref.read(circlesRepositoryProvider).invite(widget.circle.id, widget.member.id);
      if (!mounted) return;
      setState(() {
        _current = invitation;
        _code = invitation.code;
      });
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke() async {
    final current = _current;
    if (current == null) return;
    final t = context.l10n;
    final ok = await confirmDialog(context, title: t.revokeTitle, body: t.revokeBody, confirm: t.revoke, danger: true);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(circlesRepositoryProvider).revokeInvitation(current.id);
      if (!mounted) return;
      setState(() {
        _current = null;
        _code = null;
      });
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(String code) {
    final t = context.l10n;
    final link = Uri(scheme: appLinkScheme, host: 'join', queryParameters: {'invite': code}).toString();
    return t.inviteMessage(widget.member.name, widget.circle.name, formatInviteCode(code), link);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    final code = _code;
    final active = _current?.isActive ?? false;
    final hours = ref.watch(settingsProvider)?.limits.inviteHours ?? 72;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.inviteTitle(widget.member.name), style: context.text.titleLarge),
        const SizedBox(height: Space.xs),
        Text(t.inviteBody(hours), style: context.text.bodyMedium?.copyWith(color: colors.textMuted)),
        const SizedBox(height: Space.lg),
        if (_loading)
          const Padding(padding: EdgeInsets.all(Space.xl), child: Center(child: RingLoader()))
        else if (_error != null)
          InlineBanner(
            title: t.error(_error!),
            tone: Tone.danger,
            action: AppButton.text(label: t.retry, onPressed: _load),
          )
        else if (code != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: Space.lg),
            decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(Radii.lg)),
            child: SelectableText(
              formatInviteCode(code),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: DairaType.amountL.copyWith(letterSpacing: 2, color: colors.text),
            ),
          ),
          const SizedBox(height: Space.xs),
          if (_current?.expiresAt != null)
            Text(t.expiresOn(t.date(_current!.expiresAt!)), textAlign: TextAlign.center, style: context.text.bodySmall),
          const SizedBox(height: Space.lg),
          AppButton(label: t.share, icon: AppIcons.share, onPressed: () => Share.share(_message(code))),
          const SizedBox(height: Space.sm),
          AppButton.secondary(
            label: t.copyCode,
            icon: AppIcons.copy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) showToast(context, t.copied);
            },
          ),
        ] else if (active) ...[
          InlineBanner(
            title: t.inviteActive,
            body: _current?.expiresAt == null ? null : t.inviteActiveBody(t.date(_current!.expiresAt!)),
            tone: Tone.pending,
            icon: AppIcons.ticket,
          ),
          const SizedBox(height: Space.lg),
          AppButton(kind: ButtonKind.danger, label: t.revokeAndNew, loading: _busy, onPressed: _revoke),
        ] else
          AppButton(label: t.createInvite, icon: AppIcons.ticket, loading: _busy, onPressed: _create),
        if (code != null) ...[
          const SizedBox(height: Space.xs),
          AppButton.text(label: t.revoke, onPressed: _busy ? null : _revoke),
        ],
      ],
    );
  }
}
