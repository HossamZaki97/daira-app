import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/models.dart';
import '../../core/api_client.dart';
import '../../shared/formatters.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';

String actionLabel(AppLocalizations t, String action) => switch (action) {
  'report' => t.report,
  'review' => t.review,
  'approve' => t.approve,
  'reject' => t.reject,
  'payout' => t.payout,
  'receipt' => t.receipt,
  _ => t.confirm,
};

Future<void> openAction(BuildContext context, ActionItem action) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PaymentSheet(action: action),
    );

class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({required this.action, super.key});
  final ActionItem action;
  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _reason = TextEditingController();
  bool _confirming = false;
  bool _busy = false,
      _rejecting = false,
      _reasonMissing = false,
      _stale = false;
  Object? _failure;
  CommandRequest? _pending;
  String get _key =>
      '${widget.action.circle.id}:${widget.action.obligation?['id'] ?? widget.action.round['number']}';
  @override
  void initState() {
    super.initState();
    _pending = ref.read(pendingCommandsProvider)[_key];
    if (_pending != null) {
      _rejecting = _pending!.action == 'reject';
      _reason.text = _pending!.body['reason'] as String? ?? '';
    }
  }

  Future<void> _execute(String operation) async {
    if (_busy || _confirming || _stale) return;
    final t = AppLocalizations.of(context);
    if (_pending == null &&
        operation == 'reject' &&
        (_reason.text.trim().isEmpty || _reason.text.trim().length > 500)) {
      setState(() => _reasonMissing = true);
      return;
    }
    if (_pending == null && operation == 'approve') {
      _confirming = true;
      final confirmed = await confirmAction(
        context,
        t.approve,
        t.approveNotice,
      );
      _confirming = false;
      if (!mounted) return;
      if (!confirmed) return;
    }
    setState(() => _busy = true);
    final item = widget.action;
    _pending ??= CommandRequest(operation, {
      'circle_id': item.circle.id,
      'round_number': item.round['number'],
      if (item.obligation != null) 'obligation_id': item.obligation!['id'],
      if (item.obligation != null) 'version': item.obligation!['version'],
      if (operation == 'reject') 'reason': _reason.text.trim(),
    });
    ref.read(pendingCommandsProvider.notifier).state = {
      ...ref.read(pendingCommandsProvider),
      _key: _pending!,
    };
    setState(() => _failure = null);
    try {
      await ref
          .read(circlesProvider.notifier)
          .command(_pending!.action, _pending!.body);
      if (!mounted) return;
      ref.read(pendingCommandsProvider.notifier).state = {
        ...ref.read(pendingCommandsProvider),
      }..remove(_key);
      final circle = ref
          .read(circlesProvider)
          .asData
          ?.value
          .where((c) => c.id == item.circle.id)
          .firstOrNull;
      final message = circle?.status == 'completed'
          ? t.circleFinished
          : circle?.current?['number'] != item.round['number']
          ? t.roundFinished
          : t.actionSuccess;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      // These business responses are definitive; transport/unknown failures are not.
      const definitive = {
        'invalid_input',
        'reason_required',
        'invalid_start_date',
        'conflict',
        'invalid_transition',
        'forbidden',
        'session_expired',
        'rate_limited',
        'not_found',
      };
      if (error is ApiFailure && definitive.contains(error.code)) {
        ref.read(pendingCommandsProvider.notifier).state = {
          ...ref.read(pendingCommandsProvider),
        }..remove(_key);
        _pending = null;
        _stale = {
          'conflict',
          'invalid_transition',
          'forbidden',
          'not_found',
        }.contains(error.code);
      }
      setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context), item = widget.action;
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
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
            Text(
              actionLabel(t, item.action),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(item.circle.name),
            Text(
              '${t.roundOf(item.round['number'] as int, item.circle.rounds.length)} · ${dateLabel(item.round['due_date'] as String, t.localeName)}',
            ),
            if (item.obligation != null)
              Text(item.obligation!['member'] as String),
            Text(
              item.circle.amount(
                (item.obligation?['amount_minor'] ??
                        item.round['expected_minor'])
                    as int,
                t.localeName,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (item.obligation?['reported_at'] != null)
              Text(
                reportedLabel(
                  t,
                  item.obligation!['member'] as String,
                  item.obligation!['reported_at'] as String,
                ),
              ),
            if (item.obligation == null)
              InfoLine(t.beneficiary, item.round['recipient'] as String),
            const SizedBox(height: 12),
            Text(switch (item.action) {
              'payout' => t.payoutNotice,
              'receipt' => t.receiptNotice,
              _ => t.paymentNotice,
            }),
            const SizedBox(height: 20),
            if (_rejecting) ...[
              TextField(
                controller: _reason,
                enabled: !_busy && _pending == null,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: t.reason,
                  errorText: _reasonMissing ? t.requiredField : null,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_failure != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _pending != null ? t.unknownOutcome : errorText(t, _failure!),
                ),
              ),
            PrimaryButton(
              label: _pending != null && !_busy
                  ? t.resolveRequest
                  : _rejecting
                  ? t.reject
                  : actionLabel(
                      t,
                      item.action == 'review' ? 'approve' : item.action,
                    ),
              loading: _busy,
              onPressed: _stale
                  ? null
                  : () => _execute(
                      _rejecting
                          ? 'reject'
                          : item.action == 'review'
                          ? 'approve'
                          : item.action,
                    ),
            ),
            if (item.action == 'review' &&
                !_rejecting &&
                _pending == null &&
                !_stale)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _rejecting = true),
                child: Text(t.reject),
              ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(t.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
