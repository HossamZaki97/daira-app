import 'package:flutter/material.dart';

import '../core/api/api_exception.dart';
import '../core/models/circle.dart';
import '../design/design.dart';
import '../l10n/messages.dart';

/// Tone for each money state (see design-tokens.json status mapping).
Tone obligationTone(ObligationState state, {bool overdue = false}) => switch (state) {
  ObligationState.approved => Tone.success,
  ObligationState.reported => Tone.pending,
  ObligationState.pending => overdue ? Tone.danger : Tone.pending,
};

Tone roundTone(RoundState state) => switch (state) {
  RoundState.readyForPayout || RoundState.completed => Tone.success,
  _ => Tone.pending,
};

Tone circleTone(CircleStatus status) => switch (status) {
  CircleStatus.active => Tone.success,
  CircleStatus.suspended || CircleStatus.cancelled => Tone.danger,
  _ => Tone.info,
};

IconData obligationIcon(ObligationState state) => switch (state) {
  ObligationState.approved => AppIcons.confirmed,
  ObligationState.reported => AppIcons.waiting,
  ObligationState.pending => AppIcons.pay,
};

class ObligationChip extends StatelessWidget {
  const ObligationChip(this.state, {this.overdue = false, super.key});
  final ObligationState state;
  final bool overdue;

  @override
  Widget build(BuildContext context) => StatusChip(
    context.l10n.obligation(state, overdue: overdue),
    tone: obligationTone(state, overdue: overdue),
    icon: obligationIcon(state),
  );
}

class CircleStatusChip extends StatelessWidget {
  const CircleStatusChip(this.status, {super.key});
  final CircleStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusChip(context.l10n.circleStatus(status), tone: circleTone(status));
}

/// "Every month", "Every 2 weeks"…
String cadenceLabel(AppLocalizations t, Cadence cadence, int interval) => switch (cadence) {
  Cadence.day => t.everyDays(interval),
  Cadence.week => t.everyWeeks(interval),
  Cadence.month => t.everyMonths(interval),
};

/// "just now", "5 min ago", "3 h ago", otherwise the date.
String relativeTime(AppLocalizations t, DateTime value, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).toUtc().difference(value.toUtc());
  if (diff.inMinutes < 1) return t.justNow;
  if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
  return t.date(value);
}

/// Days until a calendar date (negative when past). Dates have no time zone.
int daysUntil(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final a = DateTime.utc(today.year, today.month, today.day);
  final b = DateTime.utc(date.year, date.month, date.day);
  return b.difference(a).inDays;
}

/// "Due today", "Due in 3 days", "3 days late".
String dueLabel(AppLocalizations t, DateTime date) {
  final days = daysUntil(date);
  if (days == 0) return t.dueToday;
  if (days > 0) return t.dueInDays(days);
  return t.daysLate(-days);
}

/// Shows an error from a command as a toast.
void showError(BuildContext context, Object error) => showToast(context, context.l10n.error(error), tone: Tone.danger);

/// Simple yes/no question. Returns true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  bool danger = false,
}) async {
  final t = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: danger ? TextButton.styleFrom(foregroundColor: context.colors.danger) : null,
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Full-area failure with retry, used by every screen that loads data.
class LoadError extends StatelessWidget {
  const LoadError(this.error, {required this.onRetry, super.key});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final offline = error is ApiException && (error as ApiException).isOffline;
    return ErrorView(
      title: offline ? t.offlineTitle : t.unavailableTitle,
      message: t.error(error),
      retryLabel: t.retry,
      offline: offline,
      onRetry: onRetry,
    );
  }
}
