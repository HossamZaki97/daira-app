import 'package:daira/core/models.dart';
import 'package:daira/app/theme/app_colors.dart';
import 'package:daira/features/circles/circle_presentation.dart';
import 'package:daira/l10n/generated/app_localizations.dart';
import 'package:daira/shared/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models_test.dart' show fixture;

void main() {
  setUpAll(() => initializeDateFormatting());
  test(
    'semantic text and status colors meet normal text contrast in both themes',
    () {
      for (final c in [DairaSemanticColors.light, DairaSemanticColors.dark]) {
        for (final pair in [
          (c.textPrimary, c.surfacePrimary),
          (c.textMuted, c.surfacePrimary),
          (c.actionPrimary, c.selectedSurface),
          (c.statusSuccess, c.statusSuccessContainer),
          (c.statusWarning, c.statusWarningContainer),
          (c.statusOverdue, c.statusOverdueContainer),
          (c.onHero, c.heroSurface),
          (c.onHeroMuted, c.heroSurface),
        ]) {
          final a = pair.$1.computeLuminance(), b = pair.$2.computeLuminance();
          final ratio = ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }
      }
    },
  );
  test(
    'recipient and own receiving turns use identifiers, including multiple shares',
    () {
      final data = fixture();
      data['rounds'] = [
        ...data['rounds'] as List,
        {
          ...(data['rounds'] as List).first as Map,
          'number': 2,
          'recipient_id': 'owner-member',
          'recipient': 'Member',
        },
        {...(data['rounds'] as List).first as Map, 'number': 3},
      ];
      final view = CirclePresentation(Circle(data));
      expect(view.receiving, isFalse);
      expect(view.recipient!['id'], 'member');
      expect(view.turnsFor('member'), [1, 3]);
      expect(view.turnsFor('owner-member'), [2]);
    },
  );
  test('draft has no current financial view even when a schedule exists', () {
    final view = CirclePresentation(Circle(fixture()..['status'] = 'draft'));
    expect(view.current, isNull);
    expect(view.collectionProgress, 0);
  });
  test('collection progress uses amount rather than member count', () {
    final data = fixture();
    final round = (data['rounds'] as List).first;
    round['expected_minor'] = 30000;
    round['approved_minor'] = 20000;
    expect(
      CirclePresentation(Circle(data)).collectionProgress,
      closeTo(2 / 3, 0.0001),
    );
  });
  test(
    'actions prioritize overdue and today, then ready workflow, then upcoming',
    () {
      final overdue = fixture()..['id'] = 'overdue';
      (overdue['rounds'] as List).first['due_date'] = '2030-01-01';
      final today = fixture()..['id'] = 'today';
      (today['rounds'] as List).first['due_date'] = '2030-01-02';
      final actions = actionsFor(
        [Circle(fixture()), Circle(today), Circle(overdue)],
        'owner',
        now: DateTime(2030, 1, 2),
      );
      expect(actions.take(2).map((a) => a.circle.id), ['overdue', 'today']);
      expect(actions.last.action, 'report');
      expect(actions.last.circle.id, 'circle');
    },
  );
  test(
    'recent approvals are newest first, bounded and exclude historical data',
    () {
      final data = fixture();
      final round = (data['rounds'] as List).first;
      round['obligations'] = [
        for (var i = 0; i < 8; i++)
          {
            'id': '$i',
            'state': 'approved',
            'approved_at':
                '2030-01-${(i + 1).toString().padLeft(2, '0')}T12:00:00Z',
            'historical': i == 7,
          },
      ];
      final result = recentApprovals([Circle(data)]);
      expect(result.map((r) => r.obligation['id']), ['6', '5', '4', '3', '2']);
    },
  );
  test(
    'Arabic and Persian input is exact for 0, 2 and 3 decimal currencies',
    () {
      expect(parseMinor('١٢٣٫٤٥', 2), 12345);
      expect(parseMinor('۱۲۳.۴۵۶', 3), 123456);
      expect(parseMinor('123', 0), 123);
      for (final value in ['1.001', '-1', '0', '1e3', '1,000', 'NaN']) {
        expect(parseMinor(value, 2), isNull);
      }
      expect(parseMinor('90000000000000.01', 2), isNull);
    },
  );
  test(
    'schedule preserves month-end anchor, leap years and weekly interval',
    () {
      final start = DateTime(2032, 1, 31);
      expect(scheduleDate(start, 'month', 1, 1), DateTime(2032, 2, 29));
      expect(scheduleDate(start, 'month', 1, 2), DateTime(2032, 3, 31));
      expect(scheduleDate(start, 'week', 2, 1), DateTime(2032, 2, 14));
    },
  );
  test(
    'due dates stay civil dates and reporting text distinguishes today',
    () async {
      final t = await AppLocalizations.delegate.load(const Locale('en'));
      expect(dateLabel('2030-01-31', 'en'), contains('31'));
      expect(
        reportedLabel(
          t,
          'Member',
          '2030-01-31T10:15:00',
          now: DateTime(2030, 1, 31, 23),
        ),
        contains('today'),
      );
      expect(
        reportedLabel(
          t,
          'Member',
          '2030-01-31T10:15:00',
          now: DateTime(2030, 2, 1),
        ),
        contains('Jan 31'),
      );
      expect(overdue('2030-01-31', now: DateTime(2030, 1, 31, 23)), isFalse);
    },
  );
}
