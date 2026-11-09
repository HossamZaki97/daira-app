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

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCircles.
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get tabCircles;

  /// No description provided for @tabNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tabNotifications;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your circles, clearly'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Track every installment and every turn with your group. Money moves outside Daira.'**
  String get welcomeBody;

  /// No description provided for @welcomePoint1.
  ///
  /// In en, this message translates to:
  /// **'Every due date in one place'**
  String get welcomePoint1;

  /// No description provided for @welcomePoint2.
  ///
  /// In en, this message translates to:
  /// **'Payments confirmed by the organizer'**
  String get welcomePoint2;

  /// No description provided for @welcomePoint3.
  ///
  /// In en, this message translates to:
  /// **'Everyone knows their turn'**
  String get welcomePoint3;

  /// No description provided for @welcomeTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the '**
  String get welcomeTermsPrefix;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacy;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get faq;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// No description provided for @signUpBody.
  ///
  /// In en, this message translates to:
  /// **'We will send a code to confirm your email.'**
  String get signUpBody;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters.'**
  String passwordHint(int min);

  /// No description provided for @signUpTerms.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to the terms of use.'**
  String get signUpTerms;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccountSignIn;

  /// No description provided for @noAccountCreate.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get noAccountCreate;

  /// No description provided for @confirmEmailLink.
  ///
  /// In en, this message translates to:
  /// **'I have a confirmation code'**
  String get confirmEmailLink;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a password of at least {min} characters.'**
  String errorWeakPassword(int min);

  /// No description provided for @errorSignupDisabled.
  ///
  /// In en, this message translates to:
  /// **'New accounts are paused for now. Try again later.'**
  String get errorSignupDisabled;

  /// No description provided for @errorVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'The code is wrong or expired. Check the latest email or send a new code.'**
  String get errorVerificationCode;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-digit code from the email we sent. You can also tap the link in the same email.'**
  String get verifyBody;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get verificationCode;

  /// No description provided for @verificationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8 digits.'**
  String get verificationCodeHint;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmEmail;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Send again in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @confirmationResent.
  ///
  /// In en, this message translates to:
  /// **'If the email needs confirming, a new code is on its way.'**
  String get confirmationResent;

  /// No description provided for @emailConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed. Sign in to continue.'**
  String get emailConfirmed;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email. We will send a link to choose a new password.'**
  String get forgotBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendResetLink;

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  /// No description provided for @resetSentBody.
  ///
  /// In en, this message translates to:
  /// **'If an account uses this email, a reset link is on its way. Choose the new password from the link, then sign in here.'**
  String get resetSentBody;

  /// No description provided for @useAnotherEmail.
  ///
  /// In en, this message translates to:
  /// **'Use another email'**
  String get useAnotherEmail;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String hello(String name);

  /// No description provided for @needsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get needsYou;

  /// No description provided for @nothingNeeded.
  ///
  /// In en, this message translates to:
  /// **'You are all set. Nothing needs you now.'**
  String get nothingNeeded;

  /// No description provided for @upcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get upcomingPayments;

  /// No description provided for @roundNumber.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String roundNumber(int number);

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @turnIsNow.
  ///
  /// In en, this message translates to:
  /// **'This round is yours'**
  String get turnIsNow;

  /// No description provided for @turnInRounds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Next round} other{In {count} rounds}}'**
  String turnInRounds(int count);

  /// No description provided for @actionPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay your installment'**
  String get actionPayTitle;

  /// No description provided for @actionReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm you received the payout'**
  String get actionReceiptTitle;

  /// No description provided for @actionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment to confirm} other{{count} payments to confirm}}'**
  String actionConfirmTitle(int count);

  /// No description provided for @actionPayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand the amount to {name}'**
  String actionPayoutTitle(String name);

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @notReceivedReason.
  ///
  /// In en, this message translates to:
  /// **'Not received: {reason}'**
  String notReceivedReason(String reason);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Due tomorrow} other{Due in {count} days}}'**
  String dueInDays(int count);

  /// No description provided for @daysLate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day late} other{{count} days late}}'**
  String daysLate(int count);

  /// No description provided for @everyDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String everyDays(int count);

  /// No description provided for @everyWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String everyWeeks(int count);

  /// No description provided for @everyMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every month} other{Every {count} months}}'**
  String everyMonths(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 h ago} other{{count} h ago}}'**
  String hoursAgo(int count);

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get filterDrafts;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get filterCompleted;

  /// No description provided for @noDrafts.
  ///
  /// In en, this message translates to:
  /// **'No drafts'**
  String get noDrafts;

  /// No description provided for @noCompleted.
  ///
  /// In en, this message translates to:
  /// **'No finished circles yet'**
  String get noCompleted;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @myTurnRound.
  ///
  /// In en, this message translates to:
  /// **'Your turn: round {round}'**
  String myTurnRound(int round);

  /// No description provided for @draftHint.
  ///
  /// In en, this message translates to:
  /// **'Draft — finish it and start the circle.'**
  String get draftHint;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityLog;

  /// No description provided for @confirmPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you pay this installment?'**
  String get confirmPaidTitle;

  /// No description provided for @confirmPaidBody.
  ///
  /// In en, this message translates to:
  /// **'Daira does not move money. This tells the organizer you paid so they can confirm it.'**
  String get confirmPaidBody;

  /// No description provided for @paidDone.
  ///
  /// In en, this message translates to:
  /// **'Sent to the organizer for confirmation.'**
  String get paidDone;

  /// No description provided for @approvedDone.
  ///
  /// In en, this message translates to:
  /// **'{member}\'s payment confirmed.'**
  String approvedDone(String member);

  /// No description provided for @rejectedDone.
  ///
  /// In en, this message translates to:
  /// **'The member will see your reason.'**
  String get rejectedDone;

  /// No description provided for @confirmPayoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you hand over the amount?'**
  String get confirmPayoutTitle;

  /// No description provided for @confirmPayoutBody.
  ///
  /// In en, this message translates to:
  /// **'{recipient} will be asked to confirm receiving it.'**
  String confirmPayoutBody(String recipient);

  /// No description provided for @payoutDone.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the recipient to confirm.'**
  String get payoutDone;

  /// No description provided for @confirmReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you receive the amount?'**
  String get confirmReceiptTitle;

  /// No description provided for @confirmReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'Confirming closes this round for everyone.'**
  String get confirmReceiptBody;

  /// No description provided for @receiptDone.
  ///
  /// In en, this message translates to:
  /// **'Round closed. Thank you!'**
  String get receiptDone;

  /// No description provided for @circleSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'This circle is paused'**
  String get circleSuspendedTitle;

  /// No description provided for @circleSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Daira support paused it. Payments resume when it is resumed.'**
  String get circleSuspendedBody;

  /// No description provided for @circleCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'This circle was cancelled'**
  String get circleCancelledTitle;

  /// No description provided for @circleCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Circle completed — everyone got their turn'**
  String get circleCompletedTitle;

  /// No description provided for @yourPayment.
  ///
  /// In en, this message translates to:
  /// **'Your installment'**
  String get yourPayment;

  /// No description provided for @yourPayout.
  ///
  /// In en, this message translates to:
  /// **'Your payout'**
  String get yourPayout;

  /// No description provided for @payoutSentToYou.
  ///
  /// In en, this message translates to:
  /// **'The organizer says {amount} was handed to you.'**
  String payoutSentToYou(String amount);

  /// No description provided for @handOver.
  ///
  /// In en, this message translates to:
  /// **'Hand over'**
  String get handOver;

  /// No description provided for @readyForPayoutBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone paid. Hand the amount to {recipient}.'**
  String readyForPayoutBody(String recipient);

  /// No description provided for @waitingRecipient.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to confirm receipt.'**
  String waitingRecipient(String name);

  /// No description provided for @paymentsThisRound.
  ///
  /// In en, this message translates to:
  /// **'Payments this round'**
  String get paymentsThisRound;

  /// No description provided for @toReview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 to review} other{{count} to review}}'**
  String toReview(int count);

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(int count);

  /// No description provided for @turnOrder.
  ///
  /// In en, this message translates to:
  /// **'Turn order'**
  String get turnOrder;

  /// No description provided for @perShare.
  ///
  /// In en, this message translates to:
  /// **'{amount} per share'**
  String perShare(String amount);

  /// No description provided for @youOrganize.
  ///
  /// In en, this message translates to:
  /// **'You organize'**
  String get youOrganize;

  /// No description provided for @yourTurnNow.
  ///
  /// In en, this message translates to:
  /// **'This round is yours'**
  String get yourTurnNow;

  /// No description provided for @recipientIs.
  ///
  /// In en, this message translates to:
  /// **'{name} receives this round'**
  String recipientIs(String name);

  /// No description provided for @collectedOf.
  ///
  /// In en, this message translates to:
  /// **'{collected} of {total} confirmed'**
  String collectedOf(String collected, String total);

  /// No description provided for @notReceivedHint.
  ///
  /// In en, this message translates to:
  /// **'Pay again or talk to the organizer, then tap «I paid».'**
  String get notReceivedHint;

  /// No description provided for @payHint.
  ///
  /// In en, this message translates to:
  /// **'Pay the organizer the way you agreed, then tell them here.'**
  String get payHint;

  /// No description provided for @waitingOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the organizer to confirm.'**
  String get waitingOrganizer;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by the organizer.'**
  String get paymentConfirmed;

  /// No description provided for @youName.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youName(String name);

  /// No description provided for @reportedAt.
  ///
  /// In en, this message translates to:
  /// **'Paid {time}'**
  String reportedAt(String time);

  /// No description provided for @rejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment from {member} did not arrive?'**
  String rejectTitle(String member);

  /// No description provided for @rejectBody.
  ///
  /// In en, this message translates to:
  /// **'Write the reason. The member will see it and can pay again.'**
  String get rejectBody;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. no transfer received yet'**
  String get reasonHint;

  /// No description provided for @sharesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 share} other{{count} shares}}'**
  String sharesCount(int count);

  /// No description provided for @memberJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get memberJoined;

  /// No description provided for @memberNotJoined.
  ///
  /// In en, this message translates to:
  /// **'Not joined yet'**
  String get memberNotJoined;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @importedRound.
  ///
  /// In en, this message translates to:
  /// **'Before Daira'**
  String get importedRound;

  /// No description provided for @startCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'Start this circle?'**
  String get startCircleTitle;

  /// No description provided for @startCircleBody.
  ///
  /// In en, this message translates to:
  /// **'Members, amounts and turns can no longer change after the start.'**
  String get startCircleBody;

  /// No description provided for @startCircle.
  ///
  /// In en, this message translates to:
  /// **'Start the circle'**
  String get startCircle;

  /// No description provided for @circleStarted.
  ///
  /// In en, this message translates to:
  /// **'The circle has started.'**
  String get circleStarted;

  /// No description provided for @draftTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftTitle;

  /// No description provided for @draftBody.
  ///
  /// In en, this message translates to:
  /// **'Only you can see it. Edit it or start it when ready.'**
  String get draftBody;

  /// No description provided for @editDraft.
  ///
  /// In en, this message translates to:
  /// **'Edit draft'**
  String get editDraft;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite {name}'**
  String inviteTitle(String name);

  /// No description provided for @inviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share a single-use code. It works for {hours} hours and links this member to their own account.'**
  String inviteBody(int hours);

  /// No description provided for @createInvite.
  ///
  /// In en, this message translates to:
  /// **'Create invitation code'**
  String get createInvite;

  /// No description provided for @inviteActive.
  ///
  /// In en, this message translates to:
  /// **'An invitation is already active'**
  String get inviteActive;

  /// No description provided for @inviteActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}. For safety the code is shown only once — revoke it to create a new one.'**
  String inviteActiveBody(String date);

  /// No description provided for @revokeAndNew.
  ///
  /// In en, this message translates to:
  /// **'Revoke and create a new one'**
  String get revokeAndNew;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke invitation'**
  String get revoke;

  /// No description provided for @revokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this invitation?'**
  String get revokeTitle;

  /// No description provided for @revokeBody.
  ///
  /// In en, this message translates to:
  /// **'The code will stop working right away.'**
  String get revokeBody;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(String date);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi {member}! Join \"{circle}\" on Daira with this code: {code}\nOr open: {link}'**
  String inviteMessage(String member, String circle, String code, String link);

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your invitation code'**
  String get joinTitle;

  /// No description provided for @joinBody.
  ///
  /// In en, this message translates to:
  /// **'The organizer shares a 12-character code with you.'**
  String get joinBody;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get inviteCode;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 12 characters of the code.'**
  String get inviteCodeHint;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code is not valid. Ask the organizer for a new one.'**
  String get inviteInvalid;

  /// No description provided for @inviteExpired.
  ///
  /// In en, this message translates to:
  /// **'This code expired. Ask the organizer for a new one.'**
  String get inviteExpired;

  /// No description provided for @inviteAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'You are already in this circle, or this place is taken.'**
  String get inviteAlreadyMember;

  /// No description provided for @featureDisabled.
  ///
  /// In en, this message translates to:
  /// **'This option is turned off for now.'**
  String get featureDisabled;

  /// No description provided for @joinPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Join this circle?'**
  String get joinPreviewTitle;

  /// No description provided for @organizedBy.
  ///
  /// In en, this message translates to:
  /// **'Organized by {name}'**
  String organizedBy(String name);

  /// No description provided for @joinAs.
  ///
  /// In en, this message translates to:
  /// **'You join as'**
  String get joinAs;

  /// No description provided for @yourTurnRound.
  ///
  /// In en, this message translates to:
  /// **'Your turn: round {round}'**
  String yourTurnRound(int round);

  /// No description provided for @joinNote.
  ///
  /// In en, this message translates to:
  /// **'You confirm your own payments here; the organizer confirms receiving them.'**
  String get joinNote;

  /// No description provided for @joinCircle.
  ///
  /// In en, this message translates to:
  /// **'Join the circle'**
  String get joinCircle;

  /// No description provided for @joinedCircle.
  ///
  /// In en, this message translates to:
  /// **'You joined {circle}.'**
  String joinedCircle(String circle);

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivity;

  /// No description provided for @byDairaSupport.
  ///
  /// In en, this message translates to:
  /// **'Daira support'**
  String get byDairaSupport;

  /// No description provided for @evCircleSaved.
  ///
  /// In en, this message translates to:
  /// **'Circle details saved'**
  String get evCircleSaved;

  /// No description provided for @evReport.
  ///
  /// In en, this message translates to:
  /// **'{member} paid round {round}'**
  String evReport(String member, int round);

  /// No description provided for @evApprove.
  ///
  /// In en, this message translates to:
  /// **'Payment of {member} for round {round} confirmed'**
  String evApprove(String member, int round);

  /// No description provided for @evReject.
  ///
  /// In en, this message translates to:
  /// **'Payment of {member} for round {round} not received'**
  String evReject(String member, int round);

  /// No description provided for @evCollectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Round {round} fully collected'**
  String evCollectionCompleted(int round);

  /// No description provided for @evPayout.
  ///
  /// In en, this message translates to:
  /// **'Round {round} amount handed over'**
  String evPayout(int round);

  /// No description provided for @evReceipt.
  ///
  /// In en, this message translates to:
  /// **'Round {round} received and closed'**
  String evReceipt(int round);

  /// No description provided for @evCircleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Circle completed'**
  String get evCircleCompleted;

  /// No description provided for @evInvitationCreated.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get evInvitationCreated;

  /// No description provided for @evInvitationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invitation revoked'**
  String get evInvitationRevoked;

  /// No description provided for @evInvitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Member joined'**
  String get evInvitationAccepted;

  /// No description provided for @evCircleSuspended.
  ///
  /// In en, this message translates to:
  /// **'Circle paused by support'**
  String get evCircleSuspended;

  /// No description provided for @evCircleResumed.
  ///
  /// In en, this message translates to:
  /// **'Circle resumed'**
  String get evCircleResumed;

  /// No description provided for @evCircleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Circle cancelled'**
  String get evCircleCancelled;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @noNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Payments, confirmations and turns will show up here.'**
  String get noNotificationsBody;

  /// No description provided for @needsAction.
  ///
  /// In en, this message translates to:
  /// **'Needs your action'**
  String get needsAction;

  /// No description provided for @ntPaymentReported.
  ///
  /// In en, this message translates to:
  /// **'{actor} paid round {round} — confirm it'**
  String ntPaymentReported(String actor, int round);

  /// No description provided for @ntPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{actor} confirmed your payment for round {round}'**
  String ntPaymentConfirmed(String actor, int round);

  /// No description provided for @ntPaymentNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Your payment for round {round} did not arrive: {reason}'**
  String ntPaymentNotReceived(int round, String reason);

  /// No description provided for @ntReadyForPayout.
  ///
  /// In en, this message translates to:
  /// **'Round {round} is collected — hand it to {member}'**
  String ntReadyForPayout(int round, String member);

  /// No description provided for @ntPayoutSent.
  ///
  /// In en, this message translates to:
  /// **'{actor} handed you {amount} — confirm receipt'**
  String ntPayoutSent(String actor, String amount);

  /// No description provided for @ntPayoutReceived.
  ///
  /// In en, this message translates to:
  /// **'{actor} confirmed receiving round {round}'**
  String ntPayoutReceived(String actor, int round);

  /// No description provided for @ntMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'{actor} joined the circle'**
  String ntMemberJoined(String actor);

  /// No description provided for @ntDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Installment for round {round} is due soon ({amount})'**
  String ntDueSoon(int round, String amount);

  /// No description provided for @ntOverdue.
  ///
  /// In en, this message translates to:
  /// **'Installment for round {round} is overdue ({amount})'**
  String ntOverdue(int round, String amount);

  /// No description provided for @ntCircleCompleted.
  ///
  /// In en, this message translates to:
  /// **'The circle is complete'**
  String get ntCircleCompleted;

  /// No description provided for @ntCircleSuspended.
  ///
  /// In en, this message translates to:
  /// **'The circle was paused by support'**
  String get ntCircleSuspended;

  /// No description provided for @ntCircleResumed.
  ///
  /// In en, this message translates to:
  /// **'The circle is active again'**
  String get ntCircleResumed;

  /// No description provided for @ntCircleCancelled.
  ///
  /// In en, this message translates to:
  /// **'The circle was cancelled'**
  String get ntCircleCancelled;

  /// No description provided for @ntGeneric.
  ///
  /// In en, this message translates to:
  /// **'New update'**
  String get ntGeneric;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @signedInDevices.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get signedInDevices;

  /// No description provided for @helpAndAbout.
  ///
  /// In en, this message translates to:
  /// **'Help and about'**
  String get helpAndAbout;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in any time.'**
  String get signOutBody;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be closed and your name removed from finished circles. You cannot undo this.'**
  String get deleteBody;

  /// No description provided for @deleteBlocked.
  ///
  /// In en, this message translates to:
  /// **'You are still in an active circle. Finish it before deleting your account.'**
  String get deleteBlocked;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is not correct.'**
  String get wrongPassword;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteForever;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get editName;

  /// No description provided for @editNameBody.
  ///
  /// In en, this message translates to:
  /// **'Shown to the members of your circles.'**
  String get editNameBody;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @changePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Other devices will be signed out. This one stays signed in.'**
  String get changePasswordBody;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @devicesBody.
  ///
  /// In en, this message translates to:
  /// **'End any session you do not recognise.'**
  String get devicesBody;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'Sign out device'**
  String get endSession;

  /// No description provided for @endSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out this device?'**
  String get endSessionTitle;

  /// No description provided for @endOthersTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices?'**
  String get endOthersTitle;

  /// No description provided for @endSessionBody.
  ///
  /// In en, this message translates to:
  /// **'It will need to sign in again.'**
  String get endSessionBody;

  /// No description provided for @endOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices'**
  String get endOthers;

  /// No description provided for @contentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get contentEmpty;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String lastUpdated(String date);

  /// No description provided for @newCircle.
  ///
  /// In en, this message translates to:
  /// **'New circle'**
  String get newCircle;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total} · {title}'**
  String stepOf(int step, int total, String title);

  /// No description provided for @stepBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get stepBasics;

  /// No description provided for @stepMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get stepMembers;

  /// No description provided for @stepOrder.
  ///
  /// In en, this message translates to:
  /// **'Turns'**
  String get stepOrder;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get stepReview;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get saveDraft;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get draftSaved;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this circle?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'What you entered will be lost.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @startDatePast.
  ///
  /// In en, this message translates to:
  /// **'The first due date is in the past. Choose today or later, or mark rounds already completed.'**
  String get startDatePast;

  /// No description provided for @draftChanged.
  ///
  /// In en, this message translates to:
  /// **'This draft changed on another device. Reopen it and try again.'**
  String get draftChanged;

  /// No description provided for @circleName.
  ///
  /// In en, this message translates to:
  /// **'Circle name'**
  String get circleName;

  /// No description provided for @circleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Family circle 2026'**
  String get circleNameHint;

  /// No description provided for @installmentPerShare.
  ///
  /// In en, this message translates to:
  /// **'Installment per share'**
  String get installmentPerShare;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get amountInvalid;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @cadence.
  ///
  /// In en, this message translates to:
  /// **'Payment schedule'**
  String get cadence;

  /// No description provided for @cadenceDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get cadenceDays;

  /// No description provided for @cadenceWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get cadenceWeeks;

  /// No description provided for @cadenceMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get cadenceMonths;

  /// No description provided for @firstDueDate.
  ///
  /// In en, this message translates to:
  /// **'First due date'**
  String get firstDueDate;

  /// No description provided for @lastDueDate.
  ///
  /// In en, this message translates to:
  /// **'Last due date'**
  String get lastDueDate;

  /// No description provided for @firstDueDateHint.
  ///
  /// In en, this message translates to:
  /// **'Each round follows the schedule from this date.'**
  String get firstDueDateHint;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @membersStepBody.
  ///
  /// In en, this message translates to:
  /// **'Add the other members by name. They can join with an invitation later.'**
  String get membersStepBody;

  /// No description provided for @memberNumber.
  ///
  /// In en, this message translates to:
  /// **'Member {number}'**
  String memberNumber(int number);

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMember;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @totalShares.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 share in total} other{{count} shares in total = {count} rounds}}'**
  String totalShares(int count);

  /// No description provided for @payoutPerRound.
  ///
  /// In en, this message translates to:
  /// **'Each round collects {amount}.'**
  String payoutPerRound(String amount);

  /// No description provided for @sharesLimit.
  ///
  /// In en, this message translates to:
  /// **'A circle needs 2 to {max} shares in total.'**
  String sharesLimit(int max);

  /// No description provided for @orderBody.
  ///
  /// In en, this message translates to:
  /// **'Drag to set who receives each round. One turn per share.'**
  String get orderBody;

  /// No description provided for @orderFixedBody.
  ///
  /// In en, this message translates to:
  /// **'Turns follow the order members were added; you receive last.'**
  String get orderFixedBody;

  /// No description provided for @resetOrder.
  ///
  /// In en, this message translates to:
  /// **'Reset order'**
  String get resetOrder;

  /// No description provided for @noImportedRounds.
  ///
  /// In en, this message translates to:
  /// **'New circle (no rounds before Daira)'**
  String get noImportedRounds;

  /// No description provided for @importedRounds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round already completed} other{{count} rounds already completed}}'**
  String importedRounds(int count);

  /// No description provided for @importedHint.
  ///
  /// In en, this message translates to:
  /// **'For a circle that already started: the first rounds are marked done.'**
  String get importedHint;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @membersLabel.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersLabel;

  /// No description provided for @roundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get roundsLabel;

  /// No description provided for @importedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed before Daira'**
  String get importedLabel;

  /// No description provided for @eachRoundCollects.
  ///
  /// In en, this message translates to:
  /// **'Each round collects'**
  String get eachRoundCollects;

  /// No description provided for @reviewNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Money moves outside Daira'**
  String get reviewNoteTitle;

  /// No description provided for @reviewNoteBody.
  ///
  /// In en, this message translates to:
  /// **'Daira records who paid and who received, so everyone sees the same truth.'**
  String get reviewNoteBody;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;
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
