import 'dart:io';
import 'dart:ui' as ui;
import 'package:daira/app/providers.dart';
import 'package:daira/app/theme/app_theme.dart';
import 'package:daira/core/api_client.dart';
import 'package:daira/core/models.dart';
import 'package:daira/features/circles/circle_details_screen.dart';
import 'package:daira/features/circles/create_circle_screen.dart';
import 'package:daira/features/circles/payment_sheet.dart';
import 'package:daira/features/home/home_screen.dart';
import 'package:daira/shared/identity.dart';
import 'package:daira/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'models_test.dart' show fixture;
import 'ui_test.dart' show FakeApi;

class ScenarioApi extends FakeApi {
  ScenarioApi({String actor = 'owner', String state = 'collecting'}) {
    user = {
      'id': actor,
      'name': actor == 'owner' ? 'سارة أحمد' : 'مريم علي',
      'email': 'qa@example.invalid',
    };
    circle = fixture(state: state, memberState: 'pending');
    circle['name'] = 'جمعية الأهل';
    circle['actor_member_id'] = actor == 'owner' ? 'owner-member' : 'member';
    circle['currency'] = 'EGP';
    (circle['members'] as List)[0]['name'] = 'سارة أحمد';
    (circle['members'] as List)[1]['name'] = 'مريم علي';
    final round = (circle['rounds'] as List).first;
    round['recipient'] = 'مريم علي';
    round['due_date'] = DateTime.now().toIso8601String().substring(0, 10);
    for (final o in round['obligations'] as List) {
      o['member'] = o['member_id'] == 'member' ? 'مريم علي' : 'سارة أحمد';
      if (state != 'collecting') o['state'] = 'approved';
    }
    if (state != 'collecting') {
      round['approved_minor'] = 20050;
      round['remaining_minor'] = 0;
    }
  }
  late Json circle;
  final extraCircles = <Json>[];
  final calls = <(String, Json)>[];
  bool failMutation = false, failSnapshot = false;
  bool empty = false;
  @override
  Future<Json> post(
    String action,
    Json body, {
    bool authenticated = true,
    bool retry = true,
  }) async {
    if (action == 'meta') {
      return {
        'currencies': [
          {'code': 'USD', 'decimals': 2},
          {'code': 'EGP', 'decimals': 2},
          {'code': 'KWD', 'decimals': 3},
          {'code': 'JPY', 'decimals': 0},
        ],
      };
    }
    if (action == 'snapshot') {
      if (failSnapshot) throw const ApiFailure('offline');
      return {
        'circles': empty ? <Json>[] : [circle, ...extraCircles],
      };
    }
    if ({
      'report',
      'approve',
      'reject',
      'payout',
      'receipt',
      'save',
    }.contains(action)) {
      calls.add((action, Json.from(body)));
      if (failMutation) throw const ApiFailure('offline');
      final round = (circle['rounds'] as List).first;
      if (action == 'save') return circle;
      if (action == 'payout') {
        round['state'] = 'payoutReported';
      } else if (action == 'receipt') {
        round['state'] = 'completed';
        circle['status'] = 'completed';
        circle['current_round'] = null;
      } else {
        final o = (round['obligations'] as List).firstWhere(
          (o) => o['id'] == body['obligation_id'],
        );
        o['state'] = action == 'report'
            ? 'reported'
            : action == 'reject'
            ? 'pending'
            : 'approved';
        o['version'] = (o['version'] as int) + 1;
        if (action == 'report') {
          o['reported_at'] = DateTime.now().toUtc().toIso8601String();
        }
        if (action == 'approve') {
          o['approved_at'] = DateTime.now().toUtc().toIso8601String();
        }
        if (action == 'reject') o['reason'] = body['reason'];
        round['approved_minor'] = (round['obligations'] as List)
            .where((o) => o['state'] == 'approved')
            .fold<int>(0, (n, o) => n + (o['amount_minor'] as int));
        round['remaining_minor'] = 20050 - round['approved_minor'];
        if (round['remaining_minor'] == 0) round['state'] = 'readyForPayout';
      }
      circle['version'] = (circle['version'] as int) + 1;
      return circle;
    }
    return super.post(action, body, authenticated: authenticated, retry: retry);
  }
}

Future<ProviderContainer> mount(
  WidgetTester tester,
  ScenarioApi api, {
  Widget screen = const HomeScreen(),
  String language = 'ar',
  bool dark = false,
  Size size = const Size(320, 568),
  double scale = 1.5,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() async {
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  });
  final container = ProviderContainer(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  addTearDown(api.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: Locale(language),
        theme: dark ? AppTheme.dark : AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            RepaintBoundary(key: const Key('capture'), child: child!),
        home: Consumer(
          builder: (context, ref, _) {
            final auth = ref.watch(authProvider);
            return auth.loading ? const SizedBox.shrink() : screen;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

AppLocalizations texts(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));
Future<void> sheetTap(WidgetTester tester, String label) async {
  final finder = find
      .descendant(of: find.byType(PaymentSheet), matching: find.text(label))
      .last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> buttonTap(WidgetTester tester, String label) async {
  final finder = find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Cairo');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Cairo-$weight.ttf'));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('empty Home shows one identity and one action per entry point', (
    tester,
  ) async {
    final api = ScenarioApi()..empty = true;
    await mount(tester, api);
    final t = texts(tester);
    expect(find.byType(DairaMark), findsOneWidget);
    expect(find.text(t.createCircle), findsOneWidget);
    expect(find.text(t.joinInvite), findsOneWidget);
    expect(find.text(t.noCirclesTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'report, self review and approve update Home and badge immediately',
    (tester) async {
      final api = ScenarioApi();
      await mount(tester, api);
      final t = texts(tester);
      await buttonTap(tester, t.report);
      await sheetTap(tester, t.report);
      expect(find.byType(PaymentSheet), findsNothing);
      expect(api.calls.last.$1, 'report');
      await buttonTap(tester, t.review);
      await sheetTap(tester, t.approve);
      await buttonTap(tester, t.confirm);
      expect(api.calls.last.$1, 'approve');
      expect(find.byType(PaymentSheet), findsNothing);
      expect(find.text(t.nothingRequired), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'rejection requires reason; unresolved retry freezes its exact command',
    (tester) async {
      final api = ScenarioApi();
      final round = (api.circle['rounds'] as List).first;
      round['obligations'][0]['state'] = 'reported';
      await mount(tester, api);
      final t = texts(tester);
      await buttonTap(tester, t.review);
      await sheetTap(tester, t.reject);
      await sheetTap(tester, t.reject);
      expect(find.text(t.requiredField), findsOneWidget);
      expect(api.calls, isEmpty);
      await tester.enterText(
        find.descendant(
          of: find.byType(PaymentSheet),
          matching: find.byType(TextField),
        ),
        'المبلغ لم يصل',
      );
      api.failMutation = true;
      await sheetTap(tester, t.reject);
      expect(find.text(t.unknownOutcome), findsOneWidget);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byType(PaymentSheet),
          matching: find.byType(TextField),
        ),
      );
      expect(field.enabled, isFalse);
      final original = api.calls.last.$2;
      await sheetTap(tester, t.cancel);
      await buttonTap(tester, t.review);
      expect(find.text(t.resolveRequest), findsOneWidget);
      api.failMutation = false;
      await sheetTap(tester, t.resolveRequest);
      expect(api.calls.last.$2, original);
      expect(find.byType(PaymentSheet), findsNothing);
      expect((round['obligations'] as List).first['state'], 'pending');
      await buttonTap(tester, t.report);
      await sheetTap(tester, t.report);
      expect((round['obligations'] as List).first['state'], 'reported');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'last approval, organizer payout and self receipt remain three distinct Home states',
    (tester) async {
      final api = ScenarioApi();
      final round = (api.circle['rounds'] as List).first;
      round['recipient_id'] = 'owner-member';
      round['recipient'] = 'سارة أحمد';
      round['obligations'][0]['state'] = 'approved';
      round['obligations'][1]['state'] = 'reported';
      await mount(tester, api);
      final t = texts(tester);
      await buttonTap(tester, t.review);
      await sheetTap(tester, t.approve);
      await buttonTap(tester, t.confirm);
      expect(round['state'], 'readyForPayout');
      expect(find.text(t.payout), findsOneWidget);
      expect(find.text(t.receipt), findsNothing);
      await buttonTap(tester, t.payout);
      await sheetTap(tester, t.payout);
      expect(round['state'], 'payoutReported');
      expect(find.text(t.receipt), findsOneWidget);
      expect(find.text(t.payout), findsNothing);
      await buttonTap(tester, t.receipt);
      await sheetTap(tester, t.receipt);
      expect(api.calls.map((c) => c.$1), ['approve', 'payout', 'receipt']);
      expect(api.circle['status'], 'completed');
      expect(find.text(t.nothingRequired), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Home limits actions and circle previews and routes to the full list',
    (tester) async {
      final api = ScenarioApi();
      for (var i = 2; i <= 5; i++) {
        final data = fixture(memberState: 'pending')
          ..['id'] = 'circle-$i'
          ..['name'] = 'Circle $i';
        api.extraCircles.add(data);
      }
      await mount(tester, api, size: const Size(390, 844), scale: 1);
      final t = texts(tester);
      final actions = find.text(t.report);
      // Three action cards, including a single primary hero.
      expect(actions, findsNWidgets(3));
      await tester.scrollUntilVisible(
        find.text(t.allCircles(5)),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await buttonTap(tester, t.allCircles(5));
      expect(find.text(t.filterCount(t.allFilter, 5)), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Circle 5'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Circle 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'You badge uses account ID, never identical names or organizer position',
    (tester) async {
      final api = ScenarioApi(actor: 'unlinked');
      for (final member in api.circle['members'] as List) {
        member['name'] = 'Same name';
      }
      await mount(tester, api, screen: const CircleDetailsScreen(id: 'circle'));
      final t = texts(tester),
          tab = find.descendant(
            of: find.byType(TabBar),
            matching: find.text(t.members),
          );
      await tester.ensureVisible(tab);
      await tester.pumpAndSettle();
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(find.text(t.you), findsNothing);
      expect(find.text(t.currentRecipient), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'draft editing preserves identity and version and saves without activation',
    (tester) async {
      final api = ScenarioApi();
      api.circle['status'] = 'draft';
      await mount(
        tester,
        api,
        screen: CreateCircleScreen(draft: Circle(api.circle)),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('create-next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('create-next')));
      await tester.pumpAndSettle();
      final saved = api.calls.single.$2;
      expect(saved['id'], 'circle');
      expect(saved['version'], 1);
      expect(saved['activate'], isFalse);
      expect(saved['amount'], '100.25');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'an upcoming round opens a read-only preview without financial actions',
    (tester) async {
      final api = ScenarioApi();
      final current = Json.from((api.circle['rounds'] as List).first as Map);
      api.circle['rounds'] = <Json>[
        current,
        {
          ...current,
          'number': 2,
          'recipient_id': 'owner-member',
          'recipient': 'سارة أحمد',
          'due_date': '2030-01-31',
        },
      ];
      await mount(tester, api, screen: const CircleDetailsScreen(id: 'circle'));
      final t = texts(tester);
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('round-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text(t.schedulePreview),
        250,
        scrollable: scroll,
      );
      await buttonTap(tester, t.schedulePreview);
      await tester.scrollUntilVisible(
        find.text(t.roundOf(2, 2)),
        250,
        scrollable: scroll,
      );
      await buttonTap(tester, t.roundOf(2, 2));
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(t.upcoming),
        ),
        findsOneWidget,
      );
      for (final label in [
        t.report,
        t.approve,
        t.reject,
        t.payout,
        t.receipt,
      ]) {
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(label),
          ),
          findsNothing,
        );
      }
      expect(api.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final actor in ['owner', 'other']) {
    for (final state in ['readyForPayout', 'payoutReported']) {
      testWidgets('round CTA is role specific: $actor $state', (tester) async {
        final api = ScenarioApi(actor: actor, state: state);
        await mount(
          tester,
          api,
          screen: const CircleDetailsScreen(id: 'circle'),
        );
        final t = texts(tester),
            allowed =
                (actor == 'owner' && state == 'readyForPayout') ||
                (actor == 'other' && state == 'payoutReported');
        final label = state == 'readyForPayout' ? t.payout : t.receipt;
        if (allowed) {
          final finder = find.text(label);
          await tester.scrollUntilVisible(
            finder,
            200,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('round-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
          await sheetTap(tester, label);
          expect(
            api.calls.last.$1,
            state == 'readyForPayout' ? 'payout' : 'receipt',
          );
          expect(find.byType(PaymentSheet), findsNothing);
          final result = find.text(
            state == 'readyForPayout' ? t.awaitingReceipt : t.circleFinished,
          );
          final scroll = find
              .descendant(
                of: find.byKey(const ValueKey('round-scroll')),
                matching: find.byType(Scrollable),
              )
              .first;
          tester.state<ScrollableState>(scroll).position.jumpTo(0);
          await tester.pumpAndSettle();
          expect(result, findsWidgets);
        } else {
          expect(find.text(label), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'four-step setup fits 320x568 scale 1.5 $language dark=$dark',
        (tester) async {
          final api = ScenarioApi();
          await mount(
            tester,
            api,
            screen: const CreateCircleScreen(),
            language: language,
            dark: dark,
          );
          final t = texts(tester);
          await tester.enterText(
            find.byKey(const Key('circle-name')),
            'Family',
          );
          await tester.enterText(
            find.byKey(const Key('circle-amount')),
            '١٠٠٫٢٥',
          );
          await tester.tap(find.byKey(const Key('create-next')));
          await tester.pumpAndSettle();
          final member = find.widgetWithText(
            TextFormField,
            '${t.memberName} 1',
          );
          await tester.ensureVisible(member);
          await tester.enterText(member, 'Mariam');
          await tester.tap(find.byKey(const Key('create-next')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('create-next')));
          await tester.pumpAndSettle();
          expect(find.text(t.reviewStep), findsOneWidget);
          await buttonTap(tester, t.back);
          await buttonTap(tester, t.back);
          expect(find.text('Mariam'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final dark in [false, true]) {
    testWidgets(
      'approved identity and primary screens render for visual review dark=$dark',
      (tester) async {
        final api = ScenarioApi(actor: 'other');
        api.circle['rounds'] = <Json>[
          ...((api.circle['rounds'] as List).map((r) => Json.from(r as Map))),
          {
            ...Json.from((api.circle['rounds'] as List).first as Map),
            'number': 2,
            'recipient_id': 'owner-member',
            'recipient': 'سارة أحمد',
            'due_date': '2030-01-31',
            'obligations': [],
          },
        ];
        await mount(
          tester,
          api,
          size: const Size(390, 844),
          scale: 1,
          dark: dark,
        );
        final t = texts(tester);
        // Optional review export outside the repository; not a golden baseline.
        const output = String.fromEnvironment('DAIRA_REVIEW_DIR');
        Future<void> capture(String name) async {
          if (output.isEmpty) return;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(output).create(recursive: true);
            await File(
              '$output/$name${dark ? '-dark' : ''}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('home');
        final card = find.text('جمعية الأهل').last;
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byType(CircleDetailsScreen), findsOneWidget);
        await capture('round');
        final tab = find.descendant(
          of: find.byType(TabBar),
          matching: find.text(t.members),
        );
        await tester.ensureVisible(tab);
        await tester.pumpAndSettle();
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(find.text(t.you), findsOneWidget);
        expect(find.text(t.currentRecipient), findsOneWidget);
        await capture('members');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
