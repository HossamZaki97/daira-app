import 'package:daira/core/models/money.dart';
import 'package:daira/design/design.dart';
import 'package:daira/l10n/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {ThemeData? theme, Locale locale = const Locale('ar')}) => MaterialApp(
  theme: theme ?? DairaTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('primary button shows the ring loader and ignores taps while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(AppButton(label: 'دفعت القسط', loading: true, onPressed: () => taps++)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(RingLoader), findsOneWidget);
    expect(find.text('دفعت القسط'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('button label and tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(AppButton(label: 'Continue', onPressed: () => taps++)));
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
  });

  testWidgets('both themes expose Daira colors', (tester) async {
    late DairaColors colors;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            colors = context.colors;
            return const DairaMark();
          },
        ),
        theme: DairaTheme.dark,
      ),
    );
    expect(colors.background, DairaColors.dark.background);
    expect(DairaTheme.light.colorScheme.secondary, DairaColors.light.accent);
  });

  testWidgets('amounts render left-to-right with the currency', (tester) async {
    await tester.pumpWidget(_host(const AmountText(Money(125050, currency: 'EGP', decimals: 2)), locale: const Locale('en')));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.textDirection, TextDirection.ltr);
    expect(text.textSpan!.toPlainText(), '1,250.50 EGP');
  });

  testWidgets('status chips and messages render in Arabic', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusChip(context.l10n.obligationReported, icon: AppIcons.waiting),
              InlineBanner(title: context.l10n.errorOffline, tone: Tone.danger),
            ],
          ),
        ),
      ),
    );
    expect(find.text('بانتظار التأكيد'), findsOneWidget);
    expect(find.text('لا يوجد اتصال. تحقّق من الإنترنت وحاول مجددًا.'), findsOneWidget);
  });
}
