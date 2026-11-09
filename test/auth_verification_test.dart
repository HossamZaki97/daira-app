import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:daira/app/providers.dart';
import 'package:daira/app/theme/app_theme.dart';
import 'package:daira/core/api_client.dart';
import 'package:daira/features/auth/auth_screen.dart';
import 'package:daira/l10n/generated/app_localizations.dart';
import 'package:daira/shared/identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'ui_test.dart' show FakeApi;

class VerificationApi extends FakeApi {
  final calls = <(String, Json)>[];
  bool confirmed = false;
  Completer<Json>? resendPending;
  @override
  Future<void> login(String email, String password) async {
    if (!confirmed) throw const ApiFailure('invalid_credentials');
    await super.login(email, password);
  }

  @override
  Future<Json> post(
    String action,
    Json body, {
    bool authenticated = true,
    bool retry = true,
  }) async {
    calls.add((action, Json.from(body)));
    if (action == 'signup') return {'confirmation_required': true};
    if (action == 'resend') {
      return resendPending?.future ?? Future.value({'sent_if_eligible': true});
    }
    if (action == 'forgot') return {'sent_if_eligible': true};
    if (action == 'verify_code') {
      if (body['code'] != '12345678') {
        throw const ApiFailure('invalid_verification_code');
      }
      confirmed = true;
      return {'completed': true};
    }
    return super.post(action, body, authenticated: authenticated, retry: retry);
  }
}

Future<ProviderContainer> mountAuth(
  WidgetTester tester,
  VerificationApi api, {
  String language = 'ar',
  bool dark = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 568));
  tester.platformDispatcher.textScaleFactorTestValue = 1.5;
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
            RepaintBoundary(key: const Key('auth-capture'), child: child!),
        home: const AuthScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

AppLocalizations texts(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(AuthScreen)));
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Cairo');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Cairo-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('one brand and ordered primary, secondary and recovery actions', (
    tester,
  ) async {
    final api = VerificationApi();
    await mountAuth(tester, api);
    final t = texts(tester);
    expect(find.byType(DairaMark), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    final primary = tester.getTopLeft(find.byKey(const Key('submit'))).dy;
    final secondary = tester.getTopLeft(find.byType(OutlinedButton)).dy;
    final recovery = tester.getTopLeft(find.text(t.forgotPassword)).dy;
    final confirmation = tester
        .getTopLeft(find.text(t.continueVerification))
        .dy;
    expect(recovery, lessThan(primary));
    expect(primary, lessThan(secondary));
    expect(secondary, lessThan(confirmation));
    const output = String.fromEnvironment('DAIRA_REVIEW_DIR');
    Future<void> capture(String name) async {
      if (output.isEmpty) return;
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('auth-capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    // Export only when explicitly requested, with illustrative test data.
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pumpAndSettle();
    await capture('login');
    await tap(tester, find.text(t.continueVerification));
    expect(find.byType(DairaMark), findsOneWidget);
    await capture('confirm-email');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'unconfirmed login offers confirmation and resend does not require code',
    (tester) async {
      final api = VerificationApi();
      final container = await mountAuth(tester, api);
      final t = texts(tester);
      await tester.enterText(
        find.byKey(const Key('email')),
        'pending@example.invalid',
      );
      await tester.enterText(
        find.byKey(const Key('password')),
        'initial-password',
      );
      await tap(tester, find.byKey(const Key('submit')));
      expect(find.text(t.errorCredentials), findsOneWidget);
      await tap(tester, find.text(t.continueVerification));
      expect(find.text('pending@example.invalid'), findsOneWidget);
      await tap(tester, find.byKey(const Key('resend-confirmation')));
      expect(api.calls.where((c) => c.$1 == 'resend'), hasLength(1));
      expect(find.text(t.codeFormat), findsNothing);
      expect(container.read(authProvider).profile, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'registration is neutral, countdown lasts 60 seconds and alternate email starts clean',
    (tester) async {
      final api = VerificationApi();
      await mountAuth(tester, api);
      final t = texts(tester);
      await tap(tester, find.text(t.signUp));
      await tester.enterText(
        find.widgetWithText(TextFormField, t.name),
        'Member',
      );
      await tester.enterText(
        find.byKey(const Key('email')),
        'pending@example.invalid',
      );
      await tester.enterText(
        find.byKey(const Key('password')),
        'initial-password',
      );
      await tap(tester, find.byKey(const Key('submit')));
      expect(find.text(t.neutralEmail), findsOneWidget);
      TextButton resend() => tester.widget<TextButton>(
        find.byKey(const Key('resend-confirmation')),
      );
      expect(resend().onPressed, isNull);
      await tester.pump(const Duration(seconds: 59));
      expect(resend().onPressed, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(resend().onPressed, isNotNull);
      await tap(tester, find.byKey(const Key('resend-confirmation')));
      expect(api.calls.where((c) => c.$1 == 'resend'), hasLength(1));
      await tap(tester, find.text(t.useAnotherEmail));
      final password = tester.widget<TextFormField>(
        find.byKey(const Key('password')),
      );
      expect(password.controller!.text, isEmpty);
      expect(find.text('pending@example.invalid'), findsNothing);
      expect(find.byKey(const Key('verification-code')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'existing confirmed signup stays neutral and does not expose account existence',
    (tester) async {
      final api = VerificationApi()..confirmed = true;
      final container = await mountAuth(tester, api);
      final t = texts(tester);
      await tap(tester, find.text(t.signUp));
      await tester.enterText(
        find.widgetWithText(TextFormField, t.name),
        'Another name',
      );
      await tester.enterText(
        find.byKey(const Key('email')),
        'existing@example.invalid',
      );
      await tester.enterText(
        find.byKey(const Key('password')),
        'another-password',
      );
      await tap(tester, find.byKey(const Key('submit')));
      expect(find.text(t.neutralEmail), findsOneWidget);
      expect(container.read(authProvider).profile, isNull);
      await tap(tester, find.text(t.forgotPassword));
      await tap(tester, find.byKey(const Key('submit')));
      expect(find.text(t.resetSent), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'code failure is localized and success returns to login without a session',
    (tester) async {
      final api = VerificationApi();
      final container = await mountAuth(tester, api);
      final t = texts(tester);
      await tester.enterText(
        find.byKey(const Key('email')),
        'pending@example.invalid',
      );
      await tap(tester, find.text(t.continueVerification));
      await tester.enterText(
        find.byKey(const Key('verification-code')),
        '00000000',
      );
      await tap(tester, find.byKey(const Key('submit')));
      expect(find.text(t.verificationCodeInvalid), findsOneWidget);
      expect(container.read(authProvider).profile, isNull);
      await tester.enterText(
        find.byKey(const Key('verification-code')),
        '١٢٣٤ ٥٦٧٨',
      );
      await tap(tester, find.byKey(const Key('submit')));
      expect(api.calls.last.$2['code'], '12345678');
      expect(find.text(t.emailVerifiedLogin), findsOneWidget);
      expect(find.byKey(const Key('password')), findsOneWidget);
      expect(container.read(authProvider).profile, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'resend prevents duplicate taps while loading and cooldown survives switching modes',
    (tester) async {
      final api = VerificationApi();
      await mountAuth(tester, api);
      final t = texts(tester);
      await tester.enterText(
        find.byKey(const Key('email')),
        'pending@example.invalid',
      );
      await tap(tester, find.text(t.continueVerification));
      api.resendPending = Completer<Json>();
      final button = find.byKey(const Key('resend-confirmation'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      expect(api.calls.where((c) => c.$1 == 'resend'), hasLength(1));
      api.resendPending!.complete({'sent_if_eligible': true});
      await tester.pumpAndSettle();
      await tap(tester, find.text(t.signIn));
      await tap(tester, find.text(t.continueVerification));
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('confirmation fits 320x568 scale 1.5 $language dark=$dark', (
        tester,
      ) async {
        final api = VerificationApi();
        await mountAuth(tester, api, language: language, dark: dark);
        final t = texts(tester);
        await tap(tester, find.text(t.continueVerification));
        await tester.enterText(
          find.byKey(const Key('email')),
          'pending@example.invalid',
        );
        await tester.enterText(
          find.byKey(const Key('verification-code')),
          '12345678',
        );
        await tester.ensureVisible(find.text(t.useAnotherEmail));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
