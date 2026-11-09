import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../core/api/api_exception.dart';
import '../core/models/circle.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeName => AppLocalizations.of(this).localeName;
}

extension Messages on AppLocalizations {
  /// One clear sentence for any failure. Field errors are shown on the field instead.
  String error(Object error) {
    if (error is! ApiException) return errorGeneric;
    return switch (error.code) {
      'offline' => errorOffline,
      'unavailable' => errorUnavailable,
      'invalid_credentials' => errorCredentials,
      'account_suspended' => errorSuspended,
      'session_expired' => errorSessionEnded,
      'conflict' || 'invalid_transition' => errorConflict,
      'forbidden' => errorForbidden,
      'rate_limited' => errorRateLimited,
      'invalid_input' => errorInvalidInput,
      'not_found' => errorNotFound,
      'circle_suspended' => errorCircleSuspended,
      'maintenance' => maintenanceTitle,
      'update_required' => updateRequiredTitle,
      _ => errorGeneric,
    };
  }

  String obligation(ObligationState state, {bool overdue = false}) => switch (state) {
    ObligationState.approved => obligationApproved,
    ObligationState.reported => obligationReported,
    ObligationState.pending => overdue ? obligationOverdue : obligationPending,
  };

  String circleStatus(CircleStatus status) => switch (status) {
    CircleStatus.draft => circleDraft,
    CircleStatus.active => circleActive,
    CircleStatus.suspended => circleSuspended,
    CircleStatus.completed => circleCompleted,
    CircleStatus.cancelled => circleCancelled,
  };

  String roundState(RoundState state) => switch (state) {
    RoundState.collecting => roundCollecting,
    RoundState.readyForPayout => roundReady,
    RoundState.payoutReported => roundPayoutReported,
    RoundState.completed => roundCompleted,
  };

  /// "10 Nov 2026" in the app language.
  String date(DateTime value) => DateFormat.yMMMd(localeName).format(value.isUtc ? value.toLocal() : value);
}
