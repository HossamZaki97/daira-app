import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Daira'**
  String get appName;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow your circles.'**
  String get signInBody;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Fill in this field.'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get invalidEmail;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorOffline;

  /// No description provided for @errorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Daira is not responding right now. Try again shortly.'**
  String get errorUnavailable;

  /// No description provided for @errorCredentials.
  ///
  /// In en, this message translates to:
  /// **'Check your email and password. New accounts must confirm their email first.'**
  String get errorCredentials;

  /// No description provided for @errorSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended. Contact Daira support.'**
  String get errorSuspended;

  /// No description provided for @errorSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get errorSessionEnded;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This changed in the meantime. We refreshed it — check and try again.'**
  String get errorConflict;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do this in this circle.'**
  String get errorForbidden;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a little and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted information.'**
  String get errorInvalidInput;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get errorNotFound;

  /// No description provided for @errorCircleSuspended.
  ///
  /// In en, this message translates to:
  /// **'This circle is suspended by Daira support.'**
  String get errorCircleSuspended;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Daira is under maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re improving the service. Your data is safe — come back shortly.'**
  String get maintenanceBody;

  /// No description provided for @maintenanceUntil.
  ///
  /// In en, this message translates to:
  /// **'Expected back: {until}'**
  String maintenanceUntil(String until);

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Daira to continue'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Update from the store to keep using Daira.'**
  String get updateRequiredBody;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready in the store.'**
  String updateAvailableBody(String version);

  /// No description provided for @updateRequiredFrom.
  ///
  /// In en, this message translates to:
  /// **'Required from {date}'**
  String updateRequiredFrom(String date);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'Daira needs the internet to keep your circles in sync.'**
  String get offlineBody;

  /// No description provided for @unavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Daira'**
  String get unavailableTitle;

  /// No description provided for @unavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The service didn\'t respond. Try again in a moment.'**
  String get unavailableBody;

  /// No description provided for @obligationPending.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get obligationPending;

  /// No description provided for @obligationReported.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get obligationReported;

  /// No description provided for @obligationApproved.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get obligationApproved;

  /// No description provided for @obligationOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get obligationOverdue;

  /// No description provided for @actionPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid'**
  String get actionPaid;

  /// No description provided for @actionReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get actionReceived;

  /// No description provided for @actionNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Not received'**
  String get actionNotReceived;

  /// No description provided for @actionPayout.
  ///
  /// In en, this message translates to:
  /// **'I handed it over'**
  String get actionPayout;

  /// No description provided for @actionReceipt.
  ///
  /// In en, this message translates to:
  /// **'I received it'**
  String get actionReceipt;

  /// No description provided for @circleDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get circleDraft;

  /// No description provided for @circleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get circleActive;

  /// No description provided for @circleSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get circleSuspended;

  /// No description provided for @circleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get circleCompleted;

  /// No description provided for @circleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get circleCancelled;

  /// No description provided for @roundCollecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting'**
  String get roundCollecting;

  /// No description provided for @roundReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to hand over'**
  String get roundReady;

  /// No description provided for @roundPayoutReported.
  ///
  /// In en, this message translates to:
  /// **'Awaiting receipt'**
  String get roundPayoutReported;

  /// No description provided for @roundCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get roundCompleted;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Daira foundation'**
  String get previewTitle;

  /// No description provided for @previewBody.
  ///
  /// In en, this message translates to:
  /// **'This build checks the new design and the connection to the server. The full screens come next.'**
  String get previewBody;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @serverStatus.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverStatus;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @activeCirclesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active circles} =1{1 active circle} other{{count} active circles}}'**
  String activeCirclesCount(int count);

  /// No description provided for @actionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing needs you now} =1{1 thing needs you} other{{count} things need you}}'**
  String actionsCount(int count);

  /// No description provided for @componentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get componentsTitle;

  /// No description provided for @emptyCirclesTitle.
  ///
  /// In en, this message translates to:
  /// **'No circles yet'**
  String get emptyCirclesTitle;

  /// No description provided for @emptyCirclesBody.
  ///
  /// In en, this message translates to:
  /// **'Create a circle for your group, or join one with an invitation code.'**
  String get emptyCirclesBody;

  /// No description provided for @createCircle.
  ///
  /// In en, this message translates to:
  /// **'Create a circle'**
  String get createCircle;

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCode;

  /// No description provided for @roundOf.
  ///
  /// In en, this message translates to:
  /// **'Round {number} of {total}'**
  String roundOf(int number, int total);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
