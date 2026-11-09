import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/providers.dart';
import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';

String normalizeCode(String value) =>
    value.replaceAll(RegExp(r'[\s\-\u2010-\u2015]'), '').toUpperCase();

Future<void> openJoin(BuildContext context, {String? code}) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => JoinSheet(initialCode: code),
    );

class JoinSheet extends ConsumerStatefulWidget {
  const JoinSheet({this.initialCode, super.key});
  final String? initialCode;
  @override
  ConsumerState<JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends ConsumerState<JoinSheet> {
  late final _code = TextEditingController(text: widget.initialCode);
  final _command = commandId();
  Json? _preview;
  bool _busy = false;
  Object? _failure;
  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final code = normalizeCode(_code.text);
      final api = ref.read(apiProvider);
      if (_preview == null) {
        final preview = await api.post('invite_preview', {'code': code});
        if (mounted) setState(() => _preview = preview);
      } else {
        await api.post('invite_accept', {
          'code': code,
          'invitation_id': _preview!['id'],
          'command_id': _command,
        });
        await ref.read(circlesProvider.notifier).refresh();
        if (mounted) Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.joinInvite, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_preview == null)
            TextField(
              controller: _code,
              enabled: !_busy,
              textDirection: TextDirection.ltr,
              maxLength: 40,
              decoration: InputDecoration(labelText: t.invitationCode),
            )
          else ...[
            Text(
              _preview!['circle'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(_preview!['member'] as String),
            Text('${t.expires}: ${_preview!['expires_at']}'),
          ],
          if (_failure != null) Text(errorText(t, _failure!)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _preview == null ? t.checkCode : t.acceptInvite,
            loading: _busy,
            onPressed: _submit,
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
        ],
      ),
    );
  }
}

class ManageInvitationSheet extends ConsumerStatefulWidget {
  const ManageInvitationSheet({
    required this.circle,
    required this.member,
    super.key,
  });
  final Circle circle;
  final Json member;
  @override
  ConsumerState<ManageInvitationSheet> createState() =>
      _ManageInvitationSheetState();
}

class _ManageInvitationSheetState extends ConsumerState<ManageInvitationSheet> {
  Json? _invitation;
  String? _code;
  bool _busy = true;
  Object? _failure;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ref.read(apiProvider).post('invites', {
        'circle_id': widget.circle.id,
      });
      final active = rows(result['invitations'])
          .where(
            (i) =>
                i['member_id'] == widget.member['id'] && i['state'] == 'active',
          )
          .firstOrNull;
      if (active == null) {
        final created = await ref.read(apiProvider).post('invite_create', {
          'member_id': widget.member['id'],
        });
        ref.read(invitationSecretsProvider.notifier).state = {
          ...ref.read(invitationSecretsProvider),
          created['id'] as String: created['code'] as String,
        };
        if (mounted) {
          setState(() {
            _invitation = created;
            _code = created['code'] as String;
          });
        }
      } else if (mounted) {
        setState(() {
          _invitation = active;
          _code = ref.read(invitationSecretsProvider)[active['id']];
        });
      }
    } catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(bool replace) async {
    if (_busy || _invitation == null) return;
    final t = AppLocalizations.of(context);
    if (!await confirmAction(
          context,
          replace ? t.replace : t.revoke,
          t.replaceNotice,
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final api = ref.read(apiProvider);
      await api.post('invite_revoke', {
        'member_id': widget.member['id'],
        'invitation_id': _invitation!['id'],
      });
      ref.read(invitationSecretsProvider.notifier).state = {
        ...ref.read(invitationSecretsProvider),
      }..remove(_invitation!['id']);
      _invitation = null;
      _code = null;
      if (replace) {
        final created = await api.post('invite_create', {
          'member_id': widget.member['id'],
        });
        ref.read(invitationSecretsProvider.notifier).state = {
          ...ref.read(invitationSecretsProvider),
          created['id'] as String: created['code'] as String,
        };
        if (mounted) {
          setState(() {
            _invitation = created;
            _code = created['code'] as String;
          });
        }
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.member['name'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(widget.circle.name),
          const SizedBox(height: 16),
          if (_invitation != null) ...[
            Text(t.activeInvite),
            Text('${t.expires}: ${_invitation!['expires_at']}'),
            const SizedBox(height: 12),
            if (_code != null) ...[
              SelectableText(
                _code!,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              PrimaryButton(
                label: t.share,
                onPressed: _busy
                    ? null
                    : () async {
                        final box = context.findRenderObject() as RenderBox?;
                        try {
                          await Share.share(
                            '${t.inviteShare}\n$_code\n$appLinkScheme://join?invite=$_code',
                            sharePositionOrigin: box == null
                                ? const Rect.fromLTWH(0, 0, 1, 1)
                                : box.localToGlobal(Offset.zero) & box.size,
                          );
                        } catch (error) {
                          if (mounted) setState(() => _failure = error);
                        }
                      },
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        try {
                          await Clipboard.setData(ClipboardData(text: _code!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(t.copied)));
                          }
                        } catch (error) {
                          if (mounted) setState(() => _failure = error);
                        }
                      },
                child: Text(t.copy),
              ),
            ] else ...[
              Text(t.codeLost),
              const SizedBox(height: 12),
              PrimaryButton(
                label: t.replace,
                loading: _busy,
                onPressed: () => _revoke(true),
              ),
            ],
            TextButton(
              onPressed: _busy ? null : () => _revoke(false),
              child: Text(t.revoke),
            ),
          ],
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_failure != null) ...[
            Text(errorText(t, _failure!)),
            if (_invitation == null)
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => _busy = true);
                        _load();
                      },
                child: Text(t.retry),
              ),
          ],
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }
}
