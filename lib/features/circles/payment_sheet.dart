import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/models.dart';
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
  bool _busy = false, _rejecting = false, _reasonMissing = false;
  Object? _failure;
  String? _command;
  String? _lastOperation;
  Future<void> _execute(String operation) async {
    if (_busy) return;
    final t = AppLocalizations.of(context);
    if (operation == 'reject' && _reason.text.trim().isEmpty) {
      setState(() => _reasonMissing = true);
      return;
    }
    if (operation == 'approve' &&
        !await confirmAction(context, t.approve, t.paymentNotice)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    if (_lastOperation != operation) {
      _command = commandId();
      _lastOperation = operation;
    }
    final item = widget.action;
    try {
      await ref.read(circlesProvider.notifier).command(operation, {
        'command_id': _command,
        'circle_id': item.circle.id,
        'round_number': item.round['number'],
        if (item.obligation != null) 'obligation_id': item.obligation!['id'],
        if (item.obligation != null) 'version': item.obligation!['version'],
        if (operation == 'reject') 'reason': _reason.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) setState(() => _failure = error);
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
          Text(
            actionLabel(t, item.action),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(item.circle.name),
          Text(
            '${t.round} ${item.round['number']} • ${item.round['due_date']}',
          ),
          if (item.obligation != null)
            Text(item.obligation!['member'] as String),
          Text(
            item.circle.amount(
              (item.obligation?['amount_minor'] ?? item.round['expected_minor'])
                  as int,
              t.localeName,
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (item.obligation?['reported_at'] != null)
            Text('${t.reportedAt}: ${item.obligation!['reported_at']}'),
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
              enabled: !_busy,
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
            Semantics(liveRegion: true, child: Text(errorText(t, _failure!))),
          PrimaryButton(
            label: _rejecting
                ? t.reject
                : actionLabel(
                    t,
                    item.action == 'review' ? 'approve' : item.action,
                  ),
            loading: _busy,
            onPressed: () => _execute(
              _rejecting
                  ? 'reject'
                  : item.action == 'review'
                  ? 'approve'
                  : item.action,
            ),
          ),
          if (item.action == 'review' && !_rejecting)
            TextButton(
              onPressed: _busy ? null : () => setState(() => _rejecting = true),
              child: Text(t.reject),
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
