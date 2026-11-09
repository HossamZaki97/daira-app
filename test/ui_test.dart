import 'package:daira/app/providers.dart';
import 'package:daira/app/theme/app_theme.dart';
import 'package:daira/core/api_client.dart';
import 'package:daira/core/config.dart';
import 'package:daira/features/auth/auth_screen.dart';
import 'package:daira/features/circles/circle_details_screen.dart';
import 'package:daira/features/home/home_screen.dart';
import 'package:daira/features/invitations/invitation_sheets.dart';
import 'package:daira/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'api_client_test.dart' show MemoryVault;
import 'models_test.dart' show fixture;

class FakeApi extends ApiClient {
  FakeApi() : super(const AppConfig('https://example.invalid'), MemoryVault());
  Json? user;
  @override
  Json? get storedProfile => user;
  @override
  bool get hasSession => user != null;
  @override
  Future<void> restore() async {}
  @override
  Future<void> login(String email, String password) async {
    user = {'id': 'owner', 'name': 'Owner', 'email': email};
  }

  @override
  Future<Json> post(
    String action,
    Json body, {
    bool authenticated = true,
    bool retry = true,
  }) async => switch (action) {
    'snapshot' => {
      'circles': [fixture()],
    },
    'me' => user ?? {},
    'invites' => {'invitations': []},
    'meta' => {
      'currencies': [
        {'code': 'USD', 'decimals': 2},
      ],
    },
    'invite_preview' => {
      'id': 'invite',
      'circle': 'Family',
      'member': 'Member',
      'expires_at': '2030-01-31',
    },
    _ => {},
  };
}

void main() {
  test('app bars keep system icons readable in light and dark themes', () {
    expect(
      AppTheme.light.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.dark,
    );
    expect(
      AppTheme.dark.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
      Brightness.light,
    );
  });
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'auth home details and join fit 320x568 scale1.5 $language dark=$dark',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(() async {
            tester.platformDispatcher.clearTextScaleFactorTestValue();
            await tester.binding.setSurfaceSize(null);
          });
          final api = FakeApi();
          addTearDown(api.dispose);
          final container = ProviderContainer(
            overrides: [apiProvider.overrideWithValue(api)],
          );
          addTearDown(container.dispose);
          Widget app(Widget screen) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: screen,
            ),
          );
          await tester.pumpWidget(app(const AuthScreen()));
          await tester.pumpAndSettle();
          final t = AppLocalizations.of(
            tester.element(find.byType(AuthScreen)),
          );
          await tester.ensureVisible(find.text(t.signUp));
          await tester.tap(find.text(t.signUp));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('submit')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await container
              .read(authProvider.notifier)
              .login('owner@example.invalid', 'fixture-password');
          await tester.pumpWidget(app(const HomeScreen()));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(app(const CircleDetailsScreen(id: 'circle')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.descendant(
              of: find.byType(TabBar),
              matching: find.text(t.members),
            ),
          );
          await tester.tap(
            find.descendant(
              of: find.byType(TabBar),
              matching: find.text(t.members),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(t.you), findsOneWidget);
          expect(find.text(t.organizer), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            app(const Scaffold(body: JoinSheet(initialCode: '2345ABCDEFGH'))),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(t.checkCode));
          await tester.tap(find.text(t.checkCode));
          await tester.pumpAndSettle();
          expect(find.text(t.acceptInvite), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
