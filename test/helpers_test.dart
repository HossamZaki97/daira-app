import 'package:daira/core/models/circle.dart';
import 'package:daira/features/common.dart';
import 'package:daira/features/invitations/invite_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('days until a calendar date', () {
    final now = DateTime(2026, 11, 10, 23, 30);
    expect(daysUntil(DateTime(2026, 11, 10), now: now), 0);
    expect(daysUntil(DateTime(2026, 11, 13), now: now), 3);
    expect(daysUntil(DateTime(2026, 11, 8), now: now), -2);
  });

  test('invite code grouping', () {
    expect(formatInviteCode('ABCDEFGH2345'), 'ABCD-EFGH-2345');
    expect(formatInviteCode('SHORT'), 'SHORT');
  });

  test('status tones never use the accent', () {
    expect(obligationTone(ObligationState.pending, overdue: true).name, 'danger');
    expect(obligationTone(ObligationState.approved).name, 'success');
    expect(circleTone(CircleStatus.suspended).name, 'danger');
  });
}
