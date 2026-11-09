import '../../core/api_client.dart';
import '../../core/models.dart';

/// Read-only projections; financial transitions remain in Odoo.
class CirclePresentation {
  const CirclePresentation(this.circle);
  final Circle circle;
  Json? get current => circle.status == 'active' ? circle.current : null;
  Json? get recipient => circle.members
      .where((m) => m['id'] == current?['recipient_id'])
      .firstOrNull;
  bool get receiving =>
      current != null && current!['recipient_id'] == circle.actor;
  Json? get ownObligation => rows(
    current?['obligations'],
  ).where((o) => o['member_id'] == circle.actor).firstOrNull;
  Json? get next => circle.rounds
      .where(
        (r) =>
            current != null &&
            (r['number'] as int) > (current!['number'] as int),
      )
      .firstOrNull;
  List<int> turnsFor(String memberId) => [
    for (final round in circle.rounds)
      if (round['recipient_id'] == memberId) round['number'] as int,
  ];
  double get collectionProgress {
    final expected = current?['expected_minor'] as int? ?? 0;
    if (expected <= 0) return 0;
    return ((current!['approved_minor'] as int) / expected).clamp(0, 1);
  }
}

class ObligationSummary {
  const ObligationSummary(this.circle, this.round, this.obligation);
  final Circle circle;
  final Json round;
  final Json obligation;
}

List<ObligationSummary> recentApprovals(List<Circle> circles) {
  final result = <ObligationSummary>[
    for (final circle in circles)
      for (final round in circle.rounds)
        for (final obligation in rows(round['obligations']))
          if (obligation['state'] == 'approved' &&
              obligation['historical'] != true &&
              DateTime.tryParse(obligation['approved_at'] as String? ?? '') !=
                  null)
            ObligationSummary(circle, round, obligation),
  ];
  result.sort((a, b) {
    final date = DateTime.parse(
      b.obligation['approved_at'] as String,
    ).compareTo(DateTime.parse(a.obligation['approved_at'] as String));
    return date != 0
        ? date
        : '${a.circle.id}:${a.obligation['id']}'.compareTo(
            '${b.circle.id}:${b.obligation['id']}',
          );
  });
  return result.take(5).toList();
}

List<ObligationSummary> waitingObligations(List<Circle> circles, String user) =>
    [
      for (final circle in circles.where((c) => c.status == 'active'))
        for (final obligation in rows(
          CirclePresentation(circle).current?['obligations'],
        ))
          if ((obligation['member_id'] == circle.actor &&
                  obligation['state'] == 'reported' &&
                  !circle.isOrganizer(user)) ||
              (circle.isOrganizer(user) &&
                  obligation['member_id'] != circle.actor &&
                  obligation['state'] == 'pending'))
            ObligationSummary(circle, circle.current!, obligation),
    ];
