import 'package:daira/core/api_client.dart';
import 'package:daira/core/config.dart';
import 'package:daira/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

Json fixture({
  String currency = 'USD',
  String state = 'collecting',
  String memberState = 'reported',
}) => {
  'id': 'circle',
  'name': 'Family',
  'status': 'active',
  'version': 1,
  'organizer_id': 'owner',
  'actor_member_id': 'owner-member',
  'currency': currency,
  'decimals': currency == 'KWD' ? 3 : 2,
  'installment_minor': 10025,
  'current_round': 1,
  'members': [
    {
      'id': 'owner-member',
      'user_id': 'owner',
      'name': 'Owner',
      'organizer': true,
      'shares': 1,
    },
    {
      'id': 'member',
      'user_id': 'other',
      'name': 'Member',
      'organizer': false,
      'shares': 1,
    },
  ],
  'rounds': [
    {
      'number': 1,
      'recipient_id': 'member',
      'recipient': 'Member',
      'due_date': '2030-01-31',
      'state': state,
      'expected_minor': 20050,
      'approved_minor': 0,
      'remaining_minor': 20050,
      'obligations': [
        {
          'id': 'a',
          'member_id': 'owner-member',
          'member': 'Owner',
          'amount_minor': 10025,
          'state': 'pending',
          'version': 1,
        },
        {
          'id': 'b',
          'member_id': 'member',
          'member': 'Member',
          'amount_minor': 10025,
          'state': memberState,
          'version': 1,
        },
      ],
    },
  ],
  'events': <Json>[],
};

void main() {
  test(
    'Odoo invitation links are isolated from the old app and auth callbacks',
    () {
      const code = '2345ABCDEFGH';
      expect(
        invitationCodeFromUri(Uri.parse('daira-odoo://join?invite=$code')),
        code,
      );
      for (final link in [
        'daira://join?invite=$code',
        'daira-odoo://auth-callback?invite=$code',
        'https://join?invite=$code',
        'daira-odoo://user@join?invite=$code',
        'daira-odoo://join:80?invite=$code',
        'daira-odoo://join/other?invite=$code',
        'daira-odoo://join?invite=$code&redirect=https://example.invalid',
        'daira-odoo://join?invite=$code&invite=$code',
        'daira-odoo://join?invite=$code#fragment',
      ]) {
        expect(invitationCodeFromUri(Uri.parse(link)), isNull);
      }
    },
  );
  test(
    'currency amounts remain exact, including large values and three decimals',
    () {
      expect(money(10025, 'USD', 2, 'en'), contains('100.25 USD'));
      expect(money(10025, 'KWD', 3, 'en'), contains('10.025 KWD'));
      expect(
        money(9000000000000000, 'JPY', 0, 'en'),
        contains('9,000,000,000,000,000 JPY'),
      );
    },
  );
  test('actions follow authenticated membership and organizer permission', () {
    final circle = Circle(fixture());
    expect(actionsFor([circle], 'owner').map((a) => a.action), [
      'report',
      'review',
    ]);
    final memberData = fixture()..['actor_member_id'] = 'member';
    expect(actionsFor([Circle(memberData)], 'other'), isEmpty);
    expect(
      actionsFor([
        Circle(memberData),
      ], 'other').any((a) => a.action == 'review'),
      isFalse,
    );
  });
  test('payout and receipt are separate role-restricted actions', () {
    final ready = fixture(state: 'readyForPayout', memberState: 'approved');
    expect(
      actionsFor([Circle(ready)], 'owner').any((a) => a.action == 'payout'),
      isTrue,
    );
    final sent = fixture(state: 'payoutReported', memberState: 'approved')
      ..['actor_member_id'] = 'member';
    expect(actionsFor([Circle(sent)], 'other').single.action, 'receipt');
    expect(
      actionsFor([
        Circle(fixture(state: 'collecting')),
      ], 'owner').any((a) => a.action == 'receipt'),
      isFalse,
    );
  });
  test(
    'different currencies remain independent and actions are sorted by due date',
    () {
      final later = fixture(currency: 'KWD')..['id'] = 'later';
      (later['rounds'] as List).first['due_date'] = '2030-03-01';
      final actions = actionsFor([Circle(later), Circle(fixture())], 'owner');
      expect(actions.first.circle.currency, 'USD');
      expect(actions.last.circle.currency, 'KWD');
    },
  );
  test('API URL validation rejects public cleartext and URL credentials', () {
    expect(
      () => const AppConfig(
        'http://example.com',
        allowLocalHttp: true,
      ).endpoint('me'),
      throwsArgumentError,
    );
    expect(
      () => const AppConfig(
        'http://10.attacker.com',
        allowLocalHttp: true,
      ).endpoint('me'),
      throwsArgumentError,
    );
    expect(
      () => const AppConfig('https://example.com').endpoint('//attacker.com'),
      throwsArgumentError,
    );
    expect(
      () => const AppConfig('https://user:pass@example.com').endpoint('me'),
      throwsArgumentError,
    );
    expect(
      const AppConfig(
        'http://10.0.2.2:8077',
        allowLocalHttp: true,
      ).endpoint('me').path,
      '/daira/api/v1/me',
    );
    expect(
      const AppConfig('https://example.com').endpoint('me').scheme,
      'https',
    );
  });
  test('command identifiers are UUID v4 with independent entropy', () {
    final ids = List.generate(100, (_) => commandId());
    expect(ids.toSet(), hasLength(100));
    expect(
      ids,
      everyElement(
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      ),
    );
  });
}
