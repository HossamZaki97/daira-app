import 'package:daira/app/router.dart';
import 'package:daira/core/config.dart';
import 'package:daira/core/models/activity.dart';
import 'package:daira/core/models/app_settings.dart';
import 'package:daira/core/models/circle.dart';
import 'package:daira/core/models/money.dart';
import 'package:daira/core/providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deep links', () {
    test('invite link', () {
      final link = DeepLink.parse(Uri.parse('daira://join?invite=abcd-efgh-2345'));
      expect(link, isA<InviteLink>());
      expect((link! as InviteLink).code, 'ABCDEFGH2345');
    });

    test('auth callback', () {
      expect(DeepLink.parse(Uri.parse('daira://auth-callback')), isA<AuthCallbackLink>());
    });

    test('rejects other schemes, hosts and extra parameters', () {
      expect(DeepLink.parse(Uri.parse('daira-odoo://join?invite=ABCDEFGH2345')), isNull);
      expect(DeepLink.parse(Uri.parse('daira://evil?invite=ABCDEFGH2345')), isNull);
      expect(DeepLink.parse(Uri.parse('daira://join?invite=ABCDEFGH2345&x=1')), isNull);
      expect(DeepLink.parse(Uri.parse('daira://join?invite=ABCDEFGH234O')), isNull); // O is not in the alphabet
    });

    test('normalizes pasted codes', () {
      expect(normalizeInviteCode(' abcd efgh 2345 '), 'ABCDEFGH2345');
      expect(normalizeInviteCode('abcd‐efgh–2345'), 'ABCDEFGH2345');
      expect(normalizeInviteCode('short'), isNull);
    });
  });

  group('endpoint', () {
    test('builds API URLs with query', () {
      const config = AppConfig('https://daira.example.com');
      expect(
        config.endpoint('/circles', {'status': 'active'}).toString(),
        'https://daira.example.com/daira/api/v1/circles?status=active',
      );
    });

    test('plain HTTP only for private hosts when allowed', () {
      expect(const AppConfig('http://10.0.2.2:8019', allowLocalHttp: true).endpoint('/home').port, 8019);
      expect(() => const AppConfig('http://example.com', allowLocalHttp: true).endpoint('/home'), throwsArgumentError);
      expect(() => const AppConfig('http://10.0.2.2:8019').endpoint('/home'), throwsArgumentError);
    });

    test('rejects odd paths', () {
      const config = AppConfig('https://daira.example.com');
      expect(() => config.endpoint('home'), throwsArgumentError);
      expect(() => config.endpoint('/a//b'), throwsArgumentError);
      expect(() => config.endpoint('/a?b'), throwsArgumentError);
    });
  });

  group('money', () {
    test('parses typed amounts exactly', () {
      expect(Money.parseMinor('1250', 2), 125000);
      expect(Money.parseMinor('1,250.5', 2), 125050);
      expect(Money.parseMinor('١٢٥٠٫٥', 2), 125050);
      expect(Money.parseMinor('10.125', 3), 10125);
      expect(Money.parseMinor('10.5', 0), isNull);
      expect(Money.parseMinor('0', 2), isNull);
      expect(Money.parseMinor('-5', 2), isNull);
      expect(Money.parseMinor('abc', 2), isNull);
    });

    test('decimal string for the server', () {
      expect(const Money(125050, currency: 'EGP', decimals: 2).toDecimalString(), '1250.50');
      expect(const Money(5, currency: 'KWD', decimals: 3).toDecimalString(), '0.005');
      expect(const Money(700, currency: 'JPY', decimals: 0).toDecimalString(), '700');
    });

    test('formats without needless decimals', () {
      expect(const Money(125000, currency: 'EGP', decimals: 2).amount('en'), '1,250');
      expect(const Money(125050, currency: 'EGP', decimals: 2).amount('en'), '1,250.50');
    });
  });

  group('models', () {
    test('circle detail', () {
      final circle = Circle.fromJson({
        'id': 'c1',
        'name': 'Family',
        'status': 'active',
        'version': 4,
        'currency': 'EGP',
        'decimals': 2,
        'installment_minor': 100000,
        'cadence': 'month',
        'interval': 1,
        'start_date': '2026-01-01',
        'organizer_id': 'p1',
        'actor_member_id': 'm2',
        'is_organizer': false,
        'current_round': 2,
        'members': [
          {'id': 'm1', 'name': 'Mona', 'shares': 1, 'organizer': true, 'linked': true},
          {'id': 'm2', 'name': 'Ali', 'shares': 2, 'linked': true},
        ],
        'rounds': [
          {
            'number': 2,
            'recipient_id': 'm2',
            'recipient': 'Ali',
            'due_date': '2026-02-01',
            'expected_minor': 300000,
            'approved_minor': 100000,
            'remaining_minor': 200000,
            'state': 'collecting',
            'overdue': true,
            'obligations': [
              {'id': 'o1', 'member_id': 'm2', 'member': 'Ali', 'amount_minor': 200000, 'state': 'reported', 'version': 3},
            ],
          },
        ],
      });
      expect(circle.me?.name, 'Ali');
      expect(circle.totalShares, 3);
      expect(circle.currentRound?.progress, closeTo(1 / 3, 1e-9));
      expect(circle.currentRound?.obligations.single.state, ObligationState.reported);
      expect(circle.currentRound?.obligations.single.version, 3);
      expect(circle.currentRound?.state, RoundState.collecting);
    });

    test('home skips unknown action types', () {
      final home = HomeData.fromJson({
        'actions': [
          {'type': 'pay', 'circle_id': 'c', 'circle': 'C', 'round_number': 1, 'amount_minor': 5, 'currency': 'EGP', 'decimals': 2},
          {'type': 'future_type'},
        ],
        'upcoming': [],
        'next_turn': null,
        'active_circles': 1,
        'unread_notifications': 2,
      });
      expect(home.actions.single.type, HomeActionType.pay);
      expect(home.nextTurn, isNull);
      expect(home.unreadNotifications, 2);
    });

    test('settings defaults', () {
      final settings = AppSettings.fromJson({
        'update': {'required': false, 'available': true, 'latest_build': 9},
        'currencies': [
          {'code': 'EGP', 'decimals': 2, 'symbol': 'E£'},
        ],
        'default_currency': 'EGP',
      });
      expect(settings.signupEnabled, isTrue);
      expect(settings.features.invitations, isTrue);
      expect(settings.currency('EGP')?.decimals, 2);
      expect(settings.suggestedCurrency, 'EGP');
      final state = StartupState(StartupStatus.ready, settings: settings);
      expect(state.offerUpdate, isTrue);
      expect(StartupState(StartupStatus.ready, settings: settings, skippedBuild: 9).offerUpdate, isFalse);
    });
  });

  group('router gates', () {
    String? go(StartupStatus status, bool signedIn, String at) =>
        redirectFor(status: status, signedIn: signedIn, location: at);

    test('backend gates win over everything', () {
      expect(go(StartupStatus.loading, true, Routes.home), Routes.splash);
      expect(go(StartupStatus.maintenance, true, Routes.home), Routes.maintenance);
      expect(go(StartupStatus.updateRequired, false, Routes.signIn), Routes.update);
      expect(go(StartupStatus.offline, true, Routes.home), Routes.offline);
      expect(go(StartupStatus.unavailable, true, Routes.offline), isNull);
    });

    test('session decides between sign-in and the app', () {
      expect(go(StartupStatus.ready, false, Routes.home), Routes.signIn);
      expect(go(StartupStatus.ready, false, Routes.signIn), isNull);
      expect(go(StartupStatus.ready, true, Routes.signIn), Routes.home);
      expect(go(StartupStatus.ready, true, Routes.splash), Routes.home);
      expect(go(StartupStatus.ready, true, Routes.home), isNull);
    });
  });
}
