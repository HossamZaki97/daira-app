import 'dart:math';
import 'package:intl/intl.dart';
import 'api_client.dart';

String commandId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

List<Json> rows(Object? value) =>
    (value as List? ?? []).map((e) => Json.from(e as Map)).toList();

String money(int minor, String currency, int decimals, String language) {
  final factor = pow(10, decimals).toInt();
  final whole = minor.abs() ~/ factor;
  final fraction = decimals == 0
      ? ''
      : '.${(minor.abs() % factor).toString().padLeft(decimals, '0')}';
  // Format the integer component only. No floating-point conversion of money.
  return '\u2066${minor < 0 ? '-' : ''}${NumberFormat.decimalPattern(language).format(whole)}$fraction $currency\u2069';
}

class Circle {
  Circle(this.data);
  final Json data;
  String get id => data['id'] as String;
  String get name => data['name'] as String;
  String get status => data['status'] as String;
  String get actor => data['actor_member_id'] as String;
  String get currency => data['currency'] as String;
  int get decimals => data['decimals'] as int;
  int get version => data['version'] as int;
  List<Json> get members => rows(data['members']);
  List<Json> get rounds => rows(data['rounds']);
  bool isOrganizer(String userId) => data['organizer_id'] == userId;
  Json? get current =>
      rounds.where((r) => r['number'] == data['current_round']).firstOrNull;
  String amount(int minor, String language) =>
      money(minor, currency, decimals, language);
}

class ActionItem {
  const ActionItem(this.circle, this.round, this.obligation, this.action);
  final Circle circle;
  final Json round;
  final Json? obligation;
  final String action;
}

List<ActionItem> actionsFor(List<Circle> circles, String userId) {
  final result = <ActionItem>[];
  for (final circle in circles.where((c) => c.status == 'active')) {
    final round = circle.current;
    if (round == null) continue;
    for (final obligation in rows(round['obligations'])) {
      if (obligation['member_id'] == circle.actor &&
          obligation['state'] == 'pending') {
        result.add(ActionItem(circle, round, obligation, 'report'));
      } else if (circle.isOrganizer(userId) &&
          obligation['state'] == 'reported') {
        result.add(ActionItem(circle, round, obligation, 'review'));
      }
    }
    if (round['state'] == 'readyForPayout' && circle.isOrganizer(userId)) {
      result.add(ActionItem(circle, round, null, 'payout'));
    } else if (round['state'] == 'payoutReported' &&
        round['recipient_id'] == circle.actor) {
      result.add(ActionItem(circle, round, null, 'receipt'));
    }
  }
  result.sort(
    (a, b) => (a.round['due_date'] as String).compareTo(
      b.round['due_date'] as String,
    ),
  );
  return result;
}
