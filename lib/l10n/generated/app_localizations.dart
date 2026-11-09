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

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @circles.
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get circles;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

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

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @sendReset.
  ///
  /// In en, this message translates to:
  /// **'Send recovery link'**
  String get sendReset;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get confirmEmail;

  /// No description provided for @neutralEmail.
  ///
  /// In en, this message translates to:
  /// **'If this email is eligible, a message will arrive. If you already have an account, sign in or reset your password. Open the latest message to continue.'**
  String get neutralEmail;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If this address has an account, a recovery link will arrive.'**
  String get resetSent;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation email'**
  String get resend;

  /// No description provided for @useAnotherEmail.
  ///
  /// In en, this message translates to:
  /// **'Use another email'**
  String get useAnotherEmail;

  /// No description provided for @waitToResend.
  ///
  /// In en, this message translates to:
  /// **'Please wait 60 seconds before sending again.'**
  String get waitToResend;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Complete this field.'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'Connection unavailable. Check your connection and try again.'**
  String get errorOffline;

  /// No description provided for @errorCredentials.
  ///
  /// In en, this message translates to:
  /// **'Check your credentials and confirm your email before signing in.'**
  String get errorCredentials;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'The information changed. It has been refreshed; please review it.'**
  String get errorConflict;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'This action is not available to your membership.'**
  String get errorForbidden;

  /// No description provided for @errorRate.
  ///
  /// In en, this message translates to:
  /// **'Please wait before trying again.'**
  String get errorRate;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'The request could not be completed. Try again.'**
  String get errorGeneric;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'This code is invalid, expired, revoked or already used.'**
  String get invalidCode;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This account already belongs to the circle, or the membership is linked.'**
  String get alreadyMember;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Your circles, clearly'**
  String get welcome;

  /// No description provided for @homeBody.
  ///
  /// In en, this message translates to:
  /// **'Track contributions and each member’s turn. Money moves outside Daira.'**
  String get homeBody;

  /// No description provided for @createCircle.
  ///
  /// In en, this message translates to:
  /// **'Create circle'**
  String get createCircle;

  /// No description provided for @joinInvite.
  ///
  /// In en, this message translates to:
  /// **'Join with invitation'**
  String get joinInvite;

  /// No description provided for @noCircles.
  ///
  /// In en, this message translates to:
  /// **'Your circles will appear here. Create one or join with an invitation.'**
  String get noCircles;

  /// No description provided for @nothingRequired.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs your action right now.'**
  String get nothingRequired;

  /// No description provided for @requiredActions.
  ///
  /// In en, this message translates to:
  /// **'Needs your action'**
  String get requiredActions;

  /// No description provided for @waitingOthers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for others'**
  String get waitingOthers;

  /// No description provided for @recentlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recently approved'**
  String get recentlyCompleted;

  /// No description provided for @allActions.
  ///
  /// In en, this message translates to:
  /// **'View all actions'**
  String get allActions;

  /// No description provided for @circleName.
  ///
  /// In en, this message translates to:
  /// **'Circle name'**
  String get circleName;

  /// No description provided for @installment.
  ///
  /// In en, this message translates to:
  /// **'Contribution per share'**
  String get installment;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @cadence.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get cadence;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get interval;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'First due date'**
  String get startDate;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Member name'**
  String get memberName;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @organizerShares.
  ///
  /// In en, this message translates to:
  /// **'Your shares'**
  String get organizerShares;

  /// No description provided for @orderHint.
  ///
  /// In en, this message translates to:
  /// **'Turns follow the member order, one turn per share; your turns come last.'**
  String get orderHint;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get saveDraft;

  /// No description provided for @saveCircle.
  ///
  /// In en, this message translates to:
  /// **'Save circle'**
  String get saveCircle;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate circle'**
  String get activate;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get beneficiary;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected payout'**
  String get expected;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Approved collection'**
  String get collected;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @collecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting contributions'**
  String get collecting;

  /// No description provided for @readyForPayout.
  ///
  /// In en, this message translates to:
  /// **'Collection complete; waiting for payout report'**
  String get readyForPayout;

  /// No description provided for @payoutReported.
  ///
  /// In en, this message translates to:
  /// **'Organizer reported payout; waiting for recipient acknowledgment'**
  String get payoutReported;

  /// No description provided for @historical.
  ///
  /// In en, this message translates to:
  /// **'Historical round; payout was not verified by Daira'**
  String get historical;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get pending;

  /// No description provided for @reported.
  ///
  /// In en, this message translates to:
  /// **'Waiting for organizer approval'**
  String get reported;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report payment'**
  String get report;

  /// No description provided for @paymentNotice.
  ///
  /// In en, this message translates to:
  /// **'Payment happens outside Daira. This records your declaration only.'**
  String get paymentNotice;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review report'**
  String get review;

  /// No description provided for @reportedAt.
  ///
  /// In en, this message translates to:
  /// **'Reported at'**
  String get reportedAt;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject and request correction'**
  String get reject;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason (required, up to 500 characters)'**
  String get reason;

  /// No description provided for @payout.
  ///
  /// In en, this message translates to:
  /// **'Record round payout'**
  String get payout;

  /// No description provided for @payoutNotice.
  ///
  /// In en, this message translates to:
  /// **'This records the organizer’s declaration; it is not a bank transfer or recipient acknowledgment.'**
  String get payoutNotice;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt'**
  String get receipt;

  /// No description provided for @receiptNotice.
  ///
  /// In en, this message translates to:
  /// **'Confirm only after you receive the full round amount outside the app.'**
  String get receiptNotice;

  /// No description provided for @audit.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get audit;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully.'**
  String get saved;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @manageInvite.
  ///
  /// In en, this message translates to:
  /// **'Manage invitation'**
  String get manageInvite;

  /// No description provided for @activeInvite.
  ///
  /// In en, this message translates to:
  /// **'Active invitation'**
  String get activeInvite;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCode;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share invitation'**
  String get share;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Code copied.'**
  String get copied;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke invitation'**
  String get revoke;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Revoke and issue new code'**
  String get replace;

  /// No description provided for @replaceNotice.
  ///
  /// In en, this message translates to:
  /// **'The previous code will stop working. Share the replacement with the member again.'**
  String get replaceNotice;

  /// No description provided for @codeLost.
  ///
  /// In en, this message translates to:
  /// **'The invitation is still valid for its recipient. Its code cannot be recovered after this session ends.'**
  String get codeLost;

  /// No description provided for @checkCode.
  ///
  /// In en, this message translates to:
  /// **'Check code'**
  String get checkCode;

  /// No description provided for @acceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get acceptInvite;

  /// No description provided for @inviteShare.
  ///
  /// In en, this message translates to:
  /// **'Join my circle in Daira using this invitation code:'**
  String get inviteShare;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark appearance'**
  String get darkMode;

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
