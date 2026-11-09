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
  String get home => 'Home';

  @override
  String get circles => 'Circles';

  @override
  String get actions => 'Actions';

  @override
  String get settings => 'Settings';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get sendReset => 'Send recovery link';

  @override
  String get confirmEmail => 'Confirm your email';

  @override
  String get neutralEmail =>
      'If this email is eligible for confirmation, you will receive a link and a code. You can use either. If your account is already confirmed, sign in or reset your password.';

  @override
  String get resetSent =>
      'If this email is eligible, you will receive password recovery instructions or a request to confirm your email first.';

  @override
  String get resend => 'Resend confirmation email';

  @override
  String get useAnotherEmail => 'Use another email';

  @override
  String get waitToResend => 'Please wait 60 seconds before sending again.';

  @override
  String get passwordHint => 'Use at least 8 characters.';

  @override
  String get requiredField => 'Complete this field.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get errorOffline =>
      'Connection unavailable. Check your connection and try again.';

  @override
  String get errorCredentials =>
      'Check your credentials and confirm your email before signing in.';

  @override
  String get errorConflict =>
      'The information changed. It has been refreshed; please review it.';

  @override
  String get errorForbidden =>
      'This action is not available to your membership.';

  @override
  String get errorRate => 'Please wait before trying again.';

  @override
  String get errorGeneric => 'The request could not be completed. Try again.';

  @override
  String get invalidCode =>
      'This code is invalid, expired, revoked or already used.';

  @override
  String get alreadyMember =>
      'This account already belongs to the circle, or the membership is linked.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get welcome => 'Your circles, clearly';

  @override
  String get homeBody =>
      'Track contributions and each member’s turn. Money moves outside Daira.';

  @override
  String get createCircle => 'Create circle';

  @override
  String get joinInvite => 'Join with invitation';

  @override
  String get noCircles =>
      'Your circles will appear here. Create one or join with an invitation.';

  @override
  String get nothingRequired => 'Nothing needs your action right now.';

  @override
  String get requiredActions => 'Needs your action';

  @override
  String get waitingOthers => 'Waiting for others';

  @override
  String get recentlyCompleted => 'Recently approved';

  @override
  String get allActions => 'View all actions';

  @override
  String get circleName => 'Circle name';

  @override
  String get installment => 'Contribution per share';

  @override
  String get currency => 'Currency';

  @override
  String get cadence => 'Schedule';

  @override
  String get days => 'Days';

  @override
  String get weeks => 'Weeks';

  @override
  String get months => 'Months';

  @override
  String get interval => 'Every';

  @override
  String get startDate => 'First due date';

  @override
  String get members => 'Members';

  @override
  String get addMember => 'Add member';

  @override
  String get memberName => 'Member name';

  @override
  String get shares => 'Shares';

  @override
  String get organizerShares => 'Your shares';

  @override
  String get orderHint =>
      'Turns follow the member order, one turn per share; your turns come last.';

  @override
  String get saveDraft => 'Save as draft';

  @override
  String get saveCircle => 'Save circle';

  @override
  String get activate => 'Activate circle';

  @override
  String get draft => 'Draft';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get you => 'You';

  @override
  String get organizer => 'Organizer';

  @override
  String get round => 'Round';

  @override
  String get rounds => 'Rounds';

  @override
  String get beneficiary => 'Recipient';

  @override
  String get dueDate => 'Due date';

  @override
  String get expected => 'Expected payout';

  @override
  String get collected => 'Approved collection';

  @override
  String get remaining => 'Remaining to approve';

  @override
  String get collecting => 'Collecting contributions';

  @override
  String get readyForPayout => 'Collection complete; waiting for payout report';

  @override
  String get payoutReported =>
      'Organizer reported payout; waiting for recipient acknowledgment';

  @override
  String get historical => 'Historical round; payout was not verified by Daira';

  @override
  String get pending => 'Not reported';

  @override
  String get reported => 'Waiting for organizer approval';

  @override
  String get approved => 'Approved';

  @override
  String get report => 'Report payment';

  @override
  String get paymentNotice =>
      'Payment happens outside Daira. This records your declaration only.';

  @override
  String get review => 'Review report';

  @override
  String get reportedAt => 'Reported at';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject and request correction';

  @override
  String get reason => 'Reason (required, up to 500 characters)';

  @override
  String get payout => 'Record round payout';

  @override
  String get payoutNotice =>
      'This records the organizer’s declaration; it is not a bank transfer or recipient acknowledgment.';

  @override
  String get receipt => 'Confirm receipt';

  @override
  String get receiptNotice =>
      'Confirm only after you receive the full round amount outside the app.';

  @override
  String get audit => 'Activity log';

  @override
  String get saved => 'Saved successfully.';

  @override
  String get invite => 'Invite';

  @override
  String get manageInvite => 'Manage invitation';

  @override
  String get activeInvite => 'Active invitation';

  @override
  String get expires => 'Expires';

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get copy => 'Copy code';

  @override
  String get share => 'Share invitation';

  @override
  String get copied => 'Code copied.';

  @override
  String get revoke => 'Revoke invitation';

  @override
  String get replace => 'Revoke and issue new code';

  @override
  String get replaceNotice =>
      'The previous code will stop working. Share the replacement with the member again.';

  @override
  String get codeLost =>
      'The invitation is still valid for its recipient. Its code cannot be recovered after this session ends.';

  @override
  String get checkCode => 'Check code';

  @override
  String get acceptInvite => 'Accept invitation';

  @override
  String get inviteShare =>
      'Join my circle in Daira using this invitation code:';

  @override
  String get logout => 'Sign out';

  @override
  String get darkMode => 'Dark appearance';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String roundOf(int number, int total) {
    return 'Round $number of $total';
  }

  @override
  String get currentRound => 'Current round';

  @override
  String get currentRecipient => 'Current recipient';

  @override
  String get yourReceivingTurn => 'Your turn to receive';

  @override
  String get nextRound => 'Next round';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get overdue => 'Overdue';

  @override
  String get ownContribution => 'Your contribution';

  @override
  String get roundAmount => 'Round amount';

  @override
  String get yourTurns => 'Your receiving turns';

  @override
  String get receivingTurns => 'Receiving turns';

  @override
  String get latestActivity => 'Latest activity';

  @override
  String allCircles(int count) {
    return 'View all ($count)';
  }

  @override
  String filterCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get allFilter => 'All';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String shareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shares',
      one: '1 share',
    );
    return '$_temp0';
  }

  @override
  String approvalCount(int approved, int total) {
    return '$approved of $total contributions approved';
  }

  @override
  String get collectionDone => 'Collection complete';

  @override
  String get awaitingReceipt => 'Waiting for receipt confirmation';

  @override
  String lastSync(String time) {
    return 'Updated $time';
  }

  @override
  String get updating => 'Updating';

  @override
  String get syncPending =>
      'Could not refresh. Showing the last available information.';

  @override
  String get unknownOutcome =>
      'We could not confirm the result. Retry to resolve this request without duplicating it.';

  @override
  String get resolveRequest => 'Resolve and retry';

  @override
  String get actionSuccess => 'Action recorded.';

  @override
  String get roundFinished =>
      'Round complete. The next round is now available.';

  @override
  String get circleFinished => 'The circle is complete.';

  @override
  String get approveNotice =>
      'Approve after verifying that the contribution was received outside the app.';

  @override
  String reportedToday(String name, String time) {
    return '$name reported today at $time';
  }

  @override
  String reportedOn(String name, String date, String time) {
    return '$name reported on $date at $time';
  }

  @override
  String get basicsStep => 'Basics';

  @override
  String get membersStep => 'Members and shares';

  @override
  String get scheduleStep => 'Schedule';

  @override
  String get reviewStep => 'Review';

  @override
  String stepOf(int number, int total) {
    return 'Step $number of $total';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get edit => 'Edit';

  @override
  String get schedulePreview => 'Receiving schedule';

  @override
  String get viewSchedule => 'View full schedule';

  @override
  String get hideSchedule => 'Show less';

  @override
  String get deleteMember => 'Remove member';

  @override
  String get amountInvalid =>
      'Enter a positive amount with the correct currency precision.';

  @override
  String countInvalid(int min, int max) {
    return 'Enter a number from $min to $max.';
  }

  @override
  String get activationNotice =>
      'Activation fixes the amounts, shares and schedule. Review them before continuing.';

  @override
  String get continueSetup => 'Continue setup';

  @override
  String get noActivity => 'No activity yet.';

  @override
  String get linked => 'Account linked';

  @override
  String get notLinked => 'Not joined yet';

  @override
  String get inviteRecipient => 'Invite recipient';

  @override
  String get recipientNeedsAccount =>
      'The recipient needs to join to confirm receipt.';

  @override
  String get joinSuccess => 'You joined the circle.';

  @override
  String get emptyTitle => 'Start your first circle?';

  @override
  String get settingsAccount => 'Account';

  @override
  String get appearance => 'Appearance and language';

  @override
  String get roundCompleted => 'Round complete';

  @override
  String get noActionsTitle => 'You’re all caught up';

  @override
  String get startDateInvalid => 'Choose today or a future start date.';

  @override
  String get activeFilter => 'Active';

  @override
  String get draftFilter => 'Drafts';

  @override
  String get completedFilter => 'Completed';

  @override
  String get thisIsYou => 'This is you';

  @override
  String get continueVerification => 'Complete email confirmation';

  @override
  String get emailVerificationCode => 'Email verification code';

  @override
  String get verifyCode => 'Verify code';

  @override
  String get codeValidity => '8 digits · valid for 10 minutes';

  @override
  String get codeFormat => 'Enter the 8-digit code.';

  @override
  String get verificationCodeInvalid =>
      'The code is invalid, expired or already used. Use the latest email or request a new one.';

  @override
  String get emailVerifiedLogin =>
      'Email confirmed. Sign in with your account password.';

  @override
  String resendCountdown(int seconds) {
    return 'Resend confirmation ($seconds)';
  }

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signUpTitle => 'Start with Daira';

  @override
  String get recoveryTitle => 'Reset your password';

  @override
  String get noCirclesTitle => 'No circles yet';

  @override
  String get memberContributions => 'Member contributions';
}
