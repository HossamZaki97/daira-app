import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The only icon set in the app (Phosphor, 24 grid, regular stroke; the
/// selected navigation item uses the fill variant). Use these names, never
/// Material icons, so the app and the backend stay consistent.
abstract final class AppIcons {
  // navigation
  static const home = PhosphorIconsRegular.house;
  static const homeActive = PhosphorIconsFill.house;
  static const circles = PhosphorIconsRegular.usersThree;
  static const circlesActive = PhosphorIconsFill.usersThree;
  static const notifications = PhosphorIconsRegular.bellSimple;
  static const notificationsActive = PhosphorIconsFill.bellSimple;
  static const account = PhosphorIconsRegular.userCircle;
  static const accountActive = PhosphorIconsFill.userCircle;

  // actions
  static const add = PhosphorIconsRegular.plus;
  static const remove = PhosphorIconsRegular.minus;
  static const close = PhosphorIconsRegular.x;
  static const check = PhosphorIconsRegular.check;
  static const edit = PhosphorIconsRegular.pencilSimple;
  static const delete = PhosphorIconsRegular.trash;
  static const share = PhosphorIconsRegular.shareNetwork;
  static const copy = PhosphorIconsRegular.copySimple;
  static const more = PhosphorIconsRegular.dotsThree;
  static const refresh = PhosphorIconsRegular.arrowsClockwise;
  static const drag = PhosphorIconsRegular.dotsSixVertical;
  static const invite = PhosphorIconsRegular.userPlus;
  static const ticket = PhosphorIconsRegular.ticket;
  static const signOut = PhosphorIconsRegular.signOut;
  static const send = PhosphorIconsRegular.paperPlaneTilt;

  // money & circle
  static const pay = PhosphorIconsRegular.coins;
  static const payout = PhosphorIconsRegular.handCoins;
  static const receive = PhosphorIconsRegular.wallet;
  static const confirmed = PhosphorIconsRegular.sealCheck;
  static const waiting = PhosphorIconsRegular.hourglassMedium;
  static const calendar = PhosphorIconsRegular.calendarBlank;
  static const clock = PhosphorIconsRegular.clock;
  static const history = PhosphorIconsRegular.clockCounterClockwise;
  static const organizer = PhosphorIconsRegular.crownSimple;
  static const turn = PhosphorIconsRegular.arrowsClockwise;
  static const tasks = PhosphorIconsRegular.listChecks;

  // status & feedback
  static const success = PhosphorIconsRegular.checkCircle;
  static const error = PhosphorIconsRegular.xCircle;
  static const warning = PhosphorIconsRegular.warningCircle;
  static const info = PhosphorIconsRegular.info;
  static const offline = PhosphorIconsRegular.wifiSlash;
  static const maintenance = PhosphorIconsRegular.wrench;
  static const update = PhosphorIconsRegular.arrowCircleUp;

  // account & settings
  static const user = PhosphorIconsRegular.user;
  static const email = PhosphorIconsRegular.envelopeSimple;
  static const password = PhosphorIconsRegular.lockSimple;
  static const show = PhosphorIconsRegular.eye;
  static const hide = PhosphorIconsRegular.eyeSlash;
  static const language = PhosphorIconsRegular.globeSimple;
  static const darkMode = PhosphorIconsRegular.moon;
  static const lightMode = PhosphorIconsRegular.sun;
  static const devices = PhosphorIconsRegular.deviceMobile;
  static const help = PhosphorIconsRegular.question;
  static const document = PhosphorIconsRegular.fileText;
  static const privacy = PhosphorIconsRegular.shieldCheck;
  static const settings = PhosphorIconsRegular.gearSix;

  // direction-aware (mirrored automatically in Arabic)
  static const forward = PhosphorIconsRegular.caretRight;
  static const back = PhosphorIconsRegular.arrowLeft;
  static const expand = PhosphorIconsRegular.caretDown;
}

/// An icon that points "forward"/"back" in the reading direction.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {this.size, this.color, this.semanticLabel, super.key});

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final child = Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    return rtl ? Transform.flip(flipX: true, child: child) : child;
  }
}
