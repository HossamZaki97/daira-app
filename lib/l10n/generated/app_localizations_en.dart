// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Daira';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get later => 'Later';

  @override
  String get ok => 'OK';

  @override
  String get continueAction => 'Continue';

  @override
  String get loading => 'Loading…';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInBody => 'Sign in to follow your circles.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get requiredField => 'Fill in this field.';

  @override
  String get invalidEmail => 'Enter a valid email.';

  @override
  String get errorOffline =>
      'No connection. Check your internet and try again.';

  @override
  String get errorUnavailable =>
      'Daira is not responding right now. Try again shortly.';

  @override
  String get errorCredentials =>
      'Check your email and password. New accounts must confirm their email first.';

  @override
  String get errorSuspended =>
      'This account is suspended. Contact Daira support.';

  @override
  String get errorSessionEnded => 'Your session ended. Sign in again.';

  @override
  String get errorConflict =>
      'This changed in the meantime. We refreshed it — check and try again.';

  @override
  String get errorForbidden => 'You can\'t do this in this circle.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Wait a little and try again.';

  @override
  String get errorInvalidInput => 'Check the highlighted information.';

  @override
  String get errorNotFound => 'This item is no longer available.';

  @override
  String get errorCircleSuspended =>
      'This circle is suspended by Daira support.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get maintenanceTitle => 'Daira is under maintenance';

  @override
  String get maintenanceBody =>
      'We\'re improving the service. Your data is safe — come back shortly.';

  @override
  String maintenanceUntil(String until) {
    return 'Expected back: $until';
  }

  @override
  String get updateRequiredTitle => 'Update Daira to continue';

  @override
  String get updateRequiredBody =>
      'This version is no longer supported. Update from the store to keep using Daira.';

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String updateAvailableBody(String version) {
    return 'Version $version is ready in the store.';
  }

  @override
  String updateRequiredFrom(String date) {
    return 'Required from $date';
  }

  @override
  String get updateNow => 'Update';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get offlineBody =>
      'Daira needs the internet to keep your circles in sync.';

  @override
  String get unavailableTitle => 'Can\'t reach Daira';

  @override
  String get unavailableBody =>
      'The service didn\'t respond. Try again in a moment.';

  @override
  String get obligationPending => 'Due';

  @override
  String get obligationReported => 'Awaiting confirmation';

  @override
  String get obligationApproved => 'Confirmed';

  @override
  String get obligationOverdue => 'Overdue';

  @override
  String get actionPaid => 'I paid';

  @override
  String get actionReceived => 'Received';

  @override
  String get actionNotReceived => 'Not received';

  @override
  String get actionPayout => 'I handed it over';

  @override
  String get actionReceipt => 'I received it';

  @override
  String get circleDraft => 'Draft';

  @override
  String get circleActive => 'Active';

  @override
  String get circleSuspended => 'Suspended';

  @override
  String get circleCompleted => 'Completed';

  @override
  String get circleCancelled => 'Cancelled';

  @override
  String get roundCollecting => 'Collecting';

  @override
  String get roundReady => 'Ready to hand over';

  @override
  String get roundPayoutReported => 'Awaiting receipt';

  @override
  String get roundCompleted => 'Completed';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get previewTitle => 'Daira foundation';

  @override
  String get previewBody =>
      'This build checks the new design and the connection to the server. The full screens come next.';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get serverStatus => 'Server';

  @override
  String get connected => 'Connected';

  @override
  String activeCirclesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active circles',
      one: '1 active circle',
      zero: 'No active circles',
    );
    return '$_temp0';
  }

  @override
  String actionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things need you',
      one: '1 thing needs you',
      zero: 'Nothing needs you now',
    );
    return '$_temp0';
  }

  @override
  String get componentsTitle => 'Components';

  @override
  String get emptyCirclesTitle => 'No circles yet';

  @override
  String get emptyCirclesBody =>
      'Create a circle for your group, or join one with an invitation code.';

  @override
  String get createCircle => 'Create a circle';

  @override
  String get joinWithCode => 'Join with a code';

  @override
  String roundOf(int number, int total) {
    return 'Round $number of $total';
  }

  @override
  String dueOn(String date) {
    return 'Due $date';
  }
}
