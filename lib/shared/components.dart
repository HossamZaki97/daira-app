import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme/app_colors.dart';

enum StatusTone { info, waiting, success, danger, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {this.tone = StatusTone.info, super.key});
  final String label;
  final StatusTone tone;
  @override
  Widget build(BuildContext context) {
    final colors = context.dairaColors;
    final (foreground, background) = switch (tone) {
      StatusTone.waiting => (
        colors.statusWarning,
        colors.statusWarningContainer,
      ),
      StatusTone.success => (
        colors.statusSuccess,
        colors.statusSuccessContainer,
      ),
      StatusTone.danger => (
        colors.statusOverdue,
        colors.statusOverdueContainer,
      ),
      StatusTone.neutral => (colors.textMuted, colors.statusNeutralContainer),
      StatusTone.info => (colors.actionPrimary, colors.selectedSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.name, {this.receiving = false, super.key});
  final String name;
  final bool receiving;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CircleAvatar(
      radius: 23,
      backgroundColor: receiving
          ? context.dairaColors.accentCyanContainer
          : context.dairaColors.selectedSurface,
      foregroundColor: receiving
          ? context.dairaColors.accentCyan
          : context.dairaColors.actionPrimary,
      child: Text(name.isEmpty ? '' : name.characters.first),
    ),
  );
}

class InfoLine extends StatelessWidget {
  const InfoLine(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(label, style: TextStyle(color: context.dairaColors.textMuted)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {this.action, this.onPressed, super.key});
  final String title;
  final String? action;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (action != null)
          TextButton(onPressed: onPressed, child: Text(action!)),
      ],
    ),
  );
}

String errorText(AppLocalizations t, Object error) =>
    switch (error is ApiFailure ? error.code : '') {
      'offline' => t.errorOffline,
      'invalid_verification_code' => t.verificationCodeInvalid,
      'reason_required' => t.requiredField,
      'invalid_input' => t.requiredField,
      'invalid_amount' => t.amountInvalid,
      'invalid_shares' => t.countInvalid(2, 120),
      'invalid_start_date' => t.startDateInvalid,
      'invalid_credentials' || 'session_expired' => t.errorCredentials,
      'forbidden' => t.errorForbidden,
      'conflict' || 'active_exists' || 'invalid_transition' => t.errorConflict,
      'rate_limited' => t.errorRate,
      'invalid_code' || 'expired' || 'accepted' || 'revoked' => t.invalidCode,
      'member_linked' || 'already_member' => t.alreadyMember,
      _ => t.errorGeneric,
    };

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    child: loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(label, textAlign: TextAlign.center),
          ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({required this.child, this.highlight = false, super.key});
  final Widget child;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: highlight
          ? context.dairaColors.selectedSurface
          : context.dairaColors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.dairaColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String body,
) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(body),
            const SizedBox(height: 20),
            PrimaryButton(
              label: AppLocalizations.of(context).confirm,
              onPressed: () => Navigator.pop(sheet, true),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheet, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
          ],
        ),
      ),
    ) ??
    false;

class FailureView extends StatelessWidget {
  const FailureView(this.error, this.retry, {super.key});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(errorText(AppLocalizations.of(context), error)),
        ),
        TextButton(
          onPressed: retry,
          child: Text(AppLocalizations.of(context).retry),
        ),
      ],
    ),
  );
}
