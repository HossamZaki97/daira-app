import 'package:daira/app/router.dart';
import 'package:daira/core/api/api_client.dart';
import 'package:daira/core/api/client_info.dart';
import 'package:daira/core/config.dart';
import 'package:daira/core/data/repositories.dart';
import 'package:daira/core/models/account.dart';
import 'package:daira/core/models/activity.dart';
import 'package:daira/core/models/app_settings.dart';
import 'package:daira/core/models/circle.dart';
import 'package:daira/core/models/json.dart';
import 'package:daira/core/providers.dart';
import 'package:daira/design/theme.dart';
import 'package:daira/l10n/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryVault implements SessionVault {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

const testInfo = ClientInfo(platform: 'other', version: '2.0.0', build: 1);

Json profileJson = {'id': 'p1', 'name': 'Mona Adel', 'email': 'mona@example.invalid', 'lang': 'en'};

Json sessionJson() => {'access_token': 'a', 'refresh_token': 'r', 'profile': profileJson};

AppSettings testSettings() => AppSettings.fromJson({
  'api_version': 2,
  'maintenance': {'active': false},
  'update': {'required': false, 'available': false},
  'signup_enabled': true,
  'features': {'invitations': true, 'import_history': true, 'multi_shares': true, 'turn_order': true},
  'currencies': [
    {'code': 'EGP', 'decimals': 2, 'symbol': 'E£'},
  ],
  'default_currency': 'EGP',
  'suggested_currency': 'EGP',
  'limits': {'max_members': 60, 'max_shares': 20, 'max_total_shares': 120, 'min_password': 8, 'invite_hours': 72},
  'announcements': [],
  'content': ['terms', 'privacy'],
});

/// A circle in round 1; [mine] is the signed-in member's obligation state.
Circle circleFixture({bool organizer = false, String mine = 'pending', String other = 'reported', int version = 1}) =>
    Circle.fromJson({
      'id': 'c1',
      'name': 'Family circle',
      'status': 'active',
      'version': version,
      'currency': 'EGP',
      'decimals': 2,
      'installment_minor': 100000,
      'cadence': 'month',
      'interval': 1,
      'start_date': '2026-11-01',
      'organizer_id': organizer ? 'p1' : 'p2',
      'actor_member_id': 'm1',
      'is_organizer': organizer,
      'current_round': 1,
      'members': [
        {'id': 'm1', 'name': 'Mona Adel', 'shares': 1, 'organizer': organizer, 'linked': true},
        {'id': 'm2', 'name': 'Ali Hassan', 'shares': 1, 'organizer': !organizer, 'linked': true},
      ],
      'rounds': [
        {
          'number': 1,
          'recipient_id': 'm2',
          'recipient': 'Ali Hassan',
          'due_date': '2026-12-01',
          'expected_minor': 200000,
          'approved_minor': 0,
          'remaining_minor': 200000,
          'state': 'collecting',
          'obligations': [
            {'id': 'o1', 'member_id': 'm1', 'member': 'Mona Adel', 'amount_minor': 100000, 'state': mine, 'version': version},
            {'id': 'o2', 'member_id': 'm2', 'member': 'Ali Hassan', 'amount_minor': 100000, 'state': other, 'version': 1},
          ],
        },
        {
          'number': 2,
          'recipient_id': 'm1',
          'recipient': 'Mona Adel',
          'due_date': '2027-01-01',
          'expected_minor': 200000,
          'approved_minor': 0,
          'remaining_minor': 200000,
          'state': 'collecting',
          'obligations': [],
        },
      ],
    });

class FakeAppRepository implements AppRepository {
  @override
  Future<AppSettings> config() async => testSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.api);
  final ApiClient api;
  final logins = <String>[];

  @override
  Future<Session> login(String email, String password) async {
    logins.add(email);
    return api.startSession(sessionJson());
  }

  @override
  Future<void> logout() => api.logout();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountRepository implements AccountRepository {
  HomeData homeData = HomeData.fromJson({
    'actions': [
      {
        'type': 'pay',
        'circle_id': 'c1',
        'circle': 'Family circle',
        'round_number': 1,
        'amount_minor': 100000,
        'currency': 'EGP',
        'decimals': 2,
        'due_date': '2099-12-01',
      },
    ],
    'upcoming': [],
    'next_turn': null,
    'active_circles': 1,
    'unread_notifications': 0,
  });

  @override
  Future<HomeData> home() async => homeData;

  @override
  Future<Profile> me() async => Profile.fromJson(profileJson);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCirclesRepository implements CirclesRepository {
  FakeCirclesRepository(this.circle);
  Circle circle;
  final calls = <String>[];
  Json? createdPlan;
  String? rejectReason;

  @override
  Future<List<CircleSummary>> list([CircleFilter? filter]) async => const [];

  @override
  Future<Circle> get(String id) async => circle;

  @override
  Future<Circle> reportPayment(String circleId, Obligation o, String commandId) async {
    calls.add('report:${o.id}');
    return circle = circleFixture(mine: 'reported', version: o.version + 1);
  }

  @override
  Future<Circle> approvePayment(String circleId, Obligation o, String commandId) async {
    calls.add('approve:${o.id}');
    return circle = circleFixture(organizer: true, other: 'approved');
  }

  @override
  Future<Circle> rejectPayment(String circleId, Obligation o, String reason, String commandId) async {
    calls.add('reject:${o.id}');
    rejectReason = reason;
    return circle = circleFixture(organizer: true, other: 'pending');
  }

  @override
  Future<Circle> create(Json plan, String commandId) async {
    calls.add('create');
    createdPlan = plan;
    return circle;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<int> unreadCount() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The whole app with fake data, in English, on a phone-sized screen.
class TestHarness {
  TestHarness._(this.container, this.api, this.circles, this.auth);

  final ProviderContainer container;
  final ApiClient api;
  final FakeCirclesRepository circles;
  final FakeAuthRepository auth;

  static Future<TestHarness> start(WidgetTester tester, {bool signedIn = false, Circle? circle}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'language': 'en', 'theme': 'light'});
    final preferences = await SharedPreferences.getInstance();
    final api = ApiClient(const AppConfig('https://daira.example.invalid'), MemoryVault(), testInfo);
    if (signedIn) await api.startSession(sessionJson());
    final circles = FakeCirclesRepository(circle ?? circleFixture());
    final auth = FakeAuthRepository(api);
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        clientInfoProvider.overrideWithValue(testInfo),
        apiProvider.overrideWithValue(api),
        appRepositoryProvider.overrideWithValue(FakeAppRepository()),
        authRepositoryProvider.overrideWithValue(auth),
        accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
        circlesRepositoryProvider.overrideWithValue(circles),
        notificationsRepositoryProvider.overrideWithValue(FakeNotificationsRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: DairaTheme.light,
            locale: ref.watch(localeProvider),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    // Splash keeps a short minimum time on screen.
    await tester.pump(const Duration(milliseconds: 1600));
    await settle(tester);
    return TestHarness._(container, api, circles, auth);
  }

  void go(String location) => container.read(routerProvider).go(location);

  /// Like pumpAndSettle, but tolerant of the endless ring loader.
  static Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }
}

Future<void> tapText(WidgetTester tester, String text, {bool last = true}) async {
  final finder = last ? find.text(text).last : find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await TestHarness.settle(tester);
}

/// Routes used by the tests, re-exported for readability.
typedef R = Routes;
