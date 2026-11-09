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
      'If this email is eligible, a message will arrive. If you already have an account, sign in or reset your password. Open the latest message to continue.';

  @override
  String get resetSent =>
      'If this address has an account, a recovery link will arrive.';

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
  String get remaining => 'Remaining';

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
}
