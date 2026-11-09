import 'json.dart';
import 'money.dart';

enum CircleStatus {
  draft,
  active,
  suspended,
  completed,
  cancelled;

  static CircleStatus parse(String value) =>
      CircleStatus.values.firstWhere((s) => s.name == value, orElse: () => CircleStatus.draft);
}

enum RoundState {
  collecting,
  readyForPayout,
  payoutReported,
  completed;

  static RoundState parse(String value) =>
      RoundState.values.firstWhere((s) => s.name == value, orElse: () => RoundState.collecting);
}

/// pending: not paid yet · reported: «دفعت القسط», waiting for the organizer ·
/// approved: «مؤكَّد».
enum ObligationState {
  pending,
  reported,
  approved;

  static ObligationState parse(String value) =>
      ObligationState.values.firstWhere((s) => s.name == value, orElse: () => ObligationState.pending);
}

enum Cadence {
  day,
  week,
  month;

  static Cadence parse(String value) => Cadence.values.firstWhere((c) => c.name == value, orElse: () => Cadence.month);
}

/// Item of GET /circles.
class CircleSummary {
  const CircleSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.version,
    required this.installment,
    required this.cadence,
    required this.interval,
    required this.isOrganizer,
    required this.totalRounds,
    required this.collectedCount,
    required this.memberCount,
    this.currentRound,
    this.currentDueDate,
    this.currentState,
    this.myObligationState,
    this.myNextTurn,
    this.myNextTurnDate,
  });

  factory CircleSummary.fromJson(Json json) {
    final currency = json.str('currency');
    final decimals = json.integer('decimals', 2);
    final current = json.strOrNull('current_state');
    final mine = json.strOrNull('my_obligation_state');
    return CircleSummary(
      id: json.str('id'),
      name: json.str('name'),
      status: CircleStatus.parse(json.str('status')),
      version: json.integer('version'),
      installment: Money(json.integer('installment_minor'), currency: currency, decimals: decimals),
      cadence: Cadence.parse(json.str('cadence')),
      interval: json.integer('interval', 1),
      isOrganizer: json.flag('is_organizer'),
      totalRounds: json.integer('total_rounds'),
      collectedCount: json.integer('collected_count'),
      memberCount: json.integer('member_count'),
      currentRound: json.intOrNull('current_round'),
      currentDueDate: json.date('current_due_date'),
      currentState: current == null ? null : RoundState.parse(current),
      myObligationState: mine == null ? null : ObligationState.parse(mine),
      myNextTurn: json.intOrNull('my_next_turn'),
      myNextTurnDate: json.date('my_next_turn_date'),
    );
  }

  final String id;
  final String name;
  final CircleStatus status;
  final int version;

  /// Per share.
  final Money installment;
  final Cadence cadence;
  final int interval;
  final bool isOrganizer;
  final int totalRounds;
  final int collectedCount;
  final int memberCount;
  final int? currentRound;
  final DateTime? currentDueDate;
  final RoundState? currentState;
  final ObligationState? myObligationState;
  final int? myNextTurn;
  final DateTime? myNextTurnDate;

  /// 0..1 progress of the circle by finished rounds.
  double get progress {
    if (totalRounds == 0 || currentRound == null) return status == CircleStatus.completed ? 1 : 0;
    return ((currentRound! - 1) / totalRounds).clamp(0, 1).toDouble();
  }
}

/// GET /circles/{id}
class Circle {
  const Circle({
    required this.id,
    required this.name,
    required this.status,
    required this.version,
    required this.installment,
    required this.cadence,
    required this.interval,
    required this.startDate,
    required this.organizerId,
    required this.isOrganizer,
    required this.members,
    required this.rounds,
    this.actorMemberId,
    this.currentRoundNumber,
  });

  factory Circle.fromJson(Json json) {
    final currency = json.str('currency');
    final decimals = json.integer('decimals', 2);
    Money money(int minor) => Money(minor, currency: currency, decimals: decimals);
    return Circle(
      id: json.str('id'),
      name: json.str('name'),
      status: CircleStatus.parse(json.str('status')),
      version: json.integer('version'),
      installment: money(json.integer('installment_minor')),
      cadence: Cadence.parse(json.str('cadence')),
      interval: json.integer('interval', 1),
      startDate: json.date('start_date'),
      organizerId: json.str('organizer_id'),
      isOrganizer: json.flag('is_organizer'),
      actorMemberId: json.strOrNull('actor_member_id'),
      members: [for (final m in json.list('members')) Member.fromJson(m)],
      rounds: [for (final r in json.list('rounds')) Round.fromJson(r, money)],
      currentRoundNumber: json.intOrNull('current_round'),
    );
  }

  final String id;
  final String name;
  final CircleStatus status;
  final int version;
  final Money installment;
  final Cadence cadence;
  final int interval;
  final DateTime? startDate;
  final String organizerId;
  final bool isOrganizer;

  /// The member that represents the signed-in person in this circle.
  final String? actorMemberId;
  final List<Member> members;
  final List<Round> rounds;
  final int? currentRoundNumber;

  Round? get currentRound {
    for (final r in rounds) {
      if (r.number == currentRoundNumber) return r;
    }
    return null;
  }

  Member? get me {
    for (final m in members) {
      if (m.id == actorMemberId) return m;
    }
    return null;
  }

  int get totalShares => members.fold(0, (sum, m) => sum + m.shares);
}

class Member {
  const Member({required this.id, required this.name, required this.shares, this.organizer = false, this.userId, this.linked = false});
  factory Member.fromJson(Json json) => Member(
    id: json.str('id'),
    name: json.str('name'),
    shares: json.integer('shares', 1),
    organizer: json.flag('organizer'),
    userId: json.strOrNull('user_id'),
    linked: json.flag('linked'),
  );

  final String id;
  final String name;
  final int shares;
  final bool organizer;
  final String? userId;

  /// Joined with an account (accepted the invitation).
  final bool linked;
}

class Round {
  const Round({
    required this.number,
    required this.recipientId,
    required this.recipient,
    required this.expected,
    required this.approved,
    required this.remaining,
    required this.state,
    required this.obligations,
    this.dueDate,
    this.legacy = false,
    this.overdue = false,
    this.payoutAt,
    this.receivedAt,
  });

  factory Round.fromJson(Json json, Money Function(int) money) => Round(
    number: json.integer('number'),
    recipientId: json.str('recipient_id'),
    recipient: json.str('recipient'),
    dueDate: json.date('due_date'),
    expected: money(json.integer('expected_minor')),
    approved: money(json.integer('approved_minor')),
    remaining: money(json.integer('remaining_minor')),
    state: RoundState.parse(json.str('state')),
    legacy: json.flag('legacy'),
    overdue: json.flag('overdue'),
    payoutAt: json.date('payout_at'),
    receivedAt: json.date('received_at'),
    obligations: [for (final o in json.list('obligations')) Obligation.fromJson(o, money)],
  );

  final int number;
  final String recipientId;
  final String recipient;
  final DateTime? dueDate;
  final Money expected;
  final Money approved;
  final Money remaining;
  final RoundState state;

  /// Completed before the circle was added to Daira (imported history).
  final bool legacy;
  final bool overdue;
  final DateTime? payoutAt;
  final DateTime? receivedAt;
  final List<Obligation> obligations;

  double get progress => expected.minor == 0 ? 0 : (approved.minor / expected.minor).clamp(0, 1).toDouble();
}

class Obligation {
  const Obligation({
    required this.id,
    required this.memberId,
    required this.member,
    required this.amount,
    required this.state,
    required this.version,
    this.overdue = false,
    this.reportedAt,
    this.approvedAt,
    this.reason,
    this.historical = false,
  });

  factory Obligation.fromJson(Json json, Money Function(int) money) => Obligation(
    id: json.str('id'),
    memberId: json.str('member_id'),
    member: json.str('member'),
    amount: money(json.integer('amount_minor')),
    state: ObligationState.parse(json.str('state')),
    version: json.integer('version', 1),
    overdue: json.flag('overdue'),
    reportedAt: json.date('reported_at'),
    approvedAt: json.date('approved_at'),
    reason: json.strOrNull('reason'),
    historical: json.flag('historical'),
  );

  final String id;
  final String memberId;
  final String member;
  final Money amount;
  final ObligationState state;

  /// Sent back with every command so a stale screen cannot overwrite newer data.
  final int version;
  final bool overdue;
  final DateTime? reportedAt;
  final DateTime? approvedAt;

  /// Why the organizer said «لم يصلني».
  final String? reason;
  final bool historical;
}

/// One entry of the circle audit trail (GET /circles/{id}/events).
class CircleEvent {
  const CircleEvent({
    required this.id,
    required this.action,
    required this.actor,
    this.byAdmin = false,
    this.at,
    this.roundNumber,
    this.member,
    this.note,
  });

  factory CircleEvent.fromJson(Json json) => CircleEvent(
    id: json.str('id'),
    action: json.str('action'),
    actor: json.str('actor'),
    byAdmin: json.flag('by_admin'),
    at: json.date('at'),
    roundNumber: json.intOrNull('round_number'),
    member: json.strOrNull('member'),
    note: json.strOrNull('note'),
  );

  final String id;
  final String action;
  final String actor;
  final bool byAdmin;
  final DateTime? at;
  final int? roundNumber;
  final String? member;
  final String? note;
}

/// Latest invitation of a member (GET /circles/{id}/invitations).
class Invitation {
  const Invitation({required this.id, required this.memberId, required this.state, this.expiresAt, this.code});
  factory Invitation.fromJson(Json json) => Invitation(
    id: json.str('id'),
    memberId: json.str('member_id'),
    state: json.str('state'),
    expiresAt: json.date('expires_at'),
    code: json.strOrNull('code'),
  );

  final String id;
  final String memberId;

  /// active | accepted | expired | revoked
  final String state;
  final DateTime? expiresAt;

  /// Only returned once, right after creating it.
  final String? code;

  bool get isActive => state == 'active' && (expiresAt == null || expiresAt!.isAfter(DateTime.now().toUtc()));
}

/// POST /invitations/preview — what the invited person will join.
class InvitationPreview {
  const InvitationPreview({
    required this.id,
    required this.circle,
    required this.member,
    required this.organizer,
    required this.amount,
    required this.cadence,
    required this.interval,
    this.expiresAt,
    this.turn,
    this.turnDate,
  });

  factory InvitationPreview.fromJson(Json json) => InvitationPreview(
    id: json.str('id'),
    circle: json.str('circle'),
    member: json.str('member'),
    organizer: json.str('organizer'),
    amount: Money(json.integer('amount_minor'), currency: json.str('currency'), decimals: json.integer('decimals', 2)),
    cadence: Cadence.parse(json.str('cadence')),
    interval: json.integer('interval', 1),
    expiresAt: json.date('expires_at'),
    turn: json.intOrNull('turn'),
    turnDate: json.date('turn_date'),
  );

  final String id;
  final String circle;
  final String member;
  final String organizer;
  final Money amount;
  final Cadence cadence;
  final int interval;
  final DateTime? expiresAt;
  final int? turn;
  final DateTime? turnDate;
}
