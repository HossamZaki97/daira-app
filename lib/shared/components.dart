import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme/app_colors.dart';

String errorText(AppLocalizations t, Object error) =>
    switch (error is ApiFailure ? error.code : '') {
      'offline' => t.errorOffline,
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: highlight
          ? context.dairaColors.selectedSurface
          : context.dairaColors.surfacePrimary,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.dairaColors.borderSubtle),
    ),
    child: child,
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
