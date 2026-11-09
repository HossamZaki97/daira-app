import 'circle.dart';
import 'json.dart';
import 'money.dart';

Money _money(Json json) =>
    Money(json.integer('amount_minor'), currency: json.str('currency'), decimals: json.integer('decimals', 2));

/// What the home screen asks of the person.
enum HomeActionType {
  /// Member: pay this round («دفعت القسط»).
  pay,

  /// Recipient: confirm the payout arrived («استلمت»).
  receipt,

  /// Organizer: confirm reported payments («وصلني» / «لم يصلني»).
  confirm,

  /// Organizer: hand over the collected amount («سلّمت المبلغ»).
  payout;

  static HomeActionType? parse(String value) {
    for (final t in HomeActionType.values) {
      if (t.name == value) return t;
    }
    return null;
  }
}

class HomeAction {
  const HomeAction({
    required this.type,
    required this.circleId,
    required this.circle,
    required this.roundNumber,
    required this.amount,
    this.obligationId,
    this.version,
    this.dueDate,
    this.recipient,
    this.rejectedReason,
    this.count = 0,
  });

  final HomeActionType type;
  final String circleId;
  final String circle;
  final int roundNumber;
  final Money amount;
  final String? obligationId;
  final int? version;
  final DateTime? dueDate;
  final String? recipient;

  /// Set when the organizer answered «لم يصلني» to an earlier report.
  final String? rejectedReason;

  /// Reported payments waiting for the organizer.
  final int count;

  static HomeAction? fromJson(Json json) {
    final type = HomeActionType.parse(json.str('type'));
    if (type == null) return null;
    return HomeAction(
      type: type,
      circleId: json.str('circle_id'),
      circle: json.str('circle'),
      roundNumber: json.integer('round_number'),
      amount: _money(json),
      obligationId: json.strOrNull('obligation_id'),
      version: json.intOrNull('version'),
      dueDate: json.date('due_date'),
      recipient: json.strOrNull('recipient'),
      rejectedReason: json.strOrNull('rejected_reason'),
      count: json.integer('count'),
    );
  }
}

class UpcomingPayment {
  const UpcomingPayment({
    required this.circleId,
    required this.circle,
    required this.roundNumber,
    required this.amount,
    required this.state,
    this.dueDate,
  });

  factory UpcomingPayment.fromJson(Json json) => UpcomingPayment(
    circleId: json.str('circle_id'),
    circle: json.str('circle'),
    roundNumber: json.integer('round_number'),
    amount: _money(json),
    state: ObligationState.parse(json.str('state')),
    dueDate: json.date('due_date'),
  );

  final String circleId;
  final String circle;
  final int roundNumber;
  final Money amount;
  final ObligationState state;
  final DateTime? dueDate;
}

class NextTurn {
  const NextTurn({
    required this.circleId,
    required this.circle,
    required this.roundNumber,
    required this.totalRounds,
    required this.amount,
    required this.roundsBefore,
    this.dueDate,
  });

  factory NextTurn.fromJson(Json json) => NextTurn(
    circleId: json.str('circle_id'),
    circle: json.str('circle'),
    roundNumber: json.integer('round_number'),
    totalRounds: json.integer('total_rounds'),
    amount: _money(json),
    roundsBefore: json.integer('rounds_before'),
    dueDate: json.date('due_date'),
  );

  final String circleId;
  final String circle;
  final int roundNumber;
  final int totalRounds;
  final Money amount;

  /// Rounds left before this person's turn (0 = this round).
  final int roundsBefore;
  final DateTime? dueDate;
}

/// GET /home
class HomeData {
  const HomeData({
    required this.actions,
    required this.upcoming,
    required this.activeCircles,
    required this.unreadNotifications,
    this.nextTurn,
  });

  factory HomeData.fromJson(Json json) {
    final turn = json.obj('next_turn');
    return HomeData(
      actions: [
        for (final a in json.list('actions'))
          if (HomeAction.fromJson(a) case final action?) action,
      ],
      upcoming: [for (final u in json.list('upcoming')) UpcomingPayment.fromJson(u)],
      nextTurn: turn.isEmpty ? null : NextTurn.fromJson(turn),
      activeCircles: json.integer('active_circles'),
      unreadNotifications: json.integer('unread_notifications'),
    );
  }

  final List<HomeAction> actions;
  final List<UpcomingPayment> upcoming;
  final NextTurn? nextTurn;
  final int activeCircles;
  final int unreadNotifications;
}

/// One in-app notification. The app writes the sentence from [kind] in the
/// reader's language; the server only sends facts.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.read,
    required this.actionRequired,
    this.circleId,
    this.circle,
    this.roundNumber,
    this.member,
    this.actor,
    this.amount,
    this.note,
    this.at,
  });

  factory AppNotification.fromJson(Json json) {
    final minor = json.intOrNull('amount_minor');
    final currency = json.strOrNull('currency');
    return AppNotification(
      id: json.str('id'),
      kind: json.str('kind'),
      read: json.flag('read'),
      actionRequired: json.flag('action_required'),
      circleId: json.strOrNull('circle_id'),
      circle: json.strOrNull('circle'),
      roundNumber: json.intOrNull('round_number'),
      member: json.strOrNull('member'),
      actor: json.strOrNull('actor'),
      amount: minor == null || currency == null
          ? null
          : Money(minor, currency: currency, decimals: json.integer('decimals', 2)),
      note: json.strOrNull('note'),
      at: json.date('at'),
    );
  }

  final String id;

  /// payment_reported, payment_confirmed, payment_not_received, ready_for_payout,
  /// payout_sent, payout_received, member_joined, payment_due_soon,
  /// payment_overdue, circle_completed, circle_suspended, circle_resumed,
  /// circle_cancelled.
  final String kind;
  final bool read;
  final bool actionRequired;
  final String? circleId;
  final String? circle;
  final int? roundNumber;
  final String? member;
  final String? actor;
  final Money? amount;
  final String? note;
  final DateTime? at;
}

/// A page of a newest-first list with a cursor for the next page.
class Paged<T> {
  const Paged(this.items, {this.nextCursor, this.unread = 0});
  final List<T> items;
  final String? nextCursor;
  final int unread;
  bool get hasMore => nextCursor != null;
}
