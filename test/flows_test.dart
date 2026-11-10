import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('signed out: welcome → sign in → home with the payment to make', (tester) async {
    final app = await TestHarness.start(tester);
    expect(find.text('Your circles, clearly'), findsOneWidget);

    await tapText(tester, 'Sign in', last: false);
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Mona@Example.invalid ');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret-123');
    await tapText(tester, 'Sign in');

    expect(app.auth.logins, ['mona@example.invalid']);
    expect(find.text('Hi Mona'), findsOneWidget);
    expect(find.text('Pay your installment'), findsOneWidget);
  });

  testWidgets('member reports a payment after confirming', (tester) async {
    final app = await TestHarness.start(tester, signedIn: true);
    app.go(R.circle('c1'));
    await TestHarness.settle(tester);

    expect(find.text('Your installment'), findsOneWidget);
    await tapText(tester, 'I paid', last: false); // the button
    expect(find.text('Did you pay this installment?'), findsOneWidget);
    await tapText(tester, 'I paid'); // the dialog

    expect(app.circles.calls, ['report:o1']);
    expect(find.text('Waiting for the organizer to confirm.'), findsOneWidget);
  });

  testWidgets('organizer: «Not received» needs a reason, then is sent', (tester) async {
    final app = await TestHarness.start(tester, signedIn: true, circle: circleFixture(organizer: true));
    app.go(R.circle('c1'));
    await TestHarness.settle(tester);

    expect(find.text('Payments this round'), findsOneWidget);
    await tapText(tester, 'Not received', last: false);
    expect(find.text('Payment from Ali Hassan did not arrive?'), findsOneWidget);

    await tapText(tester, 'Not received'); // empty reason
    expect(find.text('Fill in this field.'), findsOneWidget);
    expect(app.circles.calls, isEmpty);

    await tester.enterText(find.byType(TextFormField).last, 'No transfer yet');
    await tapText(tester, 'Not received');
    expect(app.circles.calls, ['reject:o2']);
    expect(app.circles.rejectReason, 'No transfer yet');
  });

  testWidgets('create wizard saves a draft with the typed plan', (tester) async {
    final app = await TestHarness.start(tester, signedIn: true);
    app.go(R.newCircle);
    await TestHarness.settle(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Office circle');
    await tester.enterText(find.byType(TextFormField).at(1), '1,000');
    await tapText(tester, 'Next');
    await tester.enterText(find.byType(TextFormField).first, 'Sara');
    await tapText(tester, 'Next');
    expect(find.text('Sara'), findsWidgets); // turn order step
    await tapText(tester, 'Next');
    await tapText(tester, 'Save as draft');

    final plan = app.circles.createdPlan!;
    expect(plan['name'], 'Office circle');
    expect(plan['amount'], '1000.00');
    expect(plan['currency'], 'EGP');
    expect(plan['activate'], false);
    expect(plan['members'], [
      {'name': 'Sara', 'shares': 1},
    ]);
  });
}
