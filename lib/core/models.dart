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
  final format = NumberFormat.decimalPattern(language);
  final zero = format.symbols.ZERO_DIGIT.codeUnitAt(0);
  String digits(String value) =>
      String.fromCharCodes(value.codeUnits.map((c) => zero + c - 48));
  final fraction = decimals == 0
      ? ''
      : '${format.symbols.DECIMAL_SEP}${digits((minor.abs() % factor).toString().padLeft(decimals, '0'))}';
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

/// Kept only in the current account's memory to retry an unresolved request.
class CommandRequest {
  CommandRequest(this.action, Json payload)
    : body = Map.unmodifiable({...payload, 'command_id': commandId()});
  final String action;
  final Json body;
}

List<ActionItem> actionsFor(
  List<Circle> circles,
  String userId, {
  DateTime? now,
}) {
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
  final today = DateTime(
    now?.year ?? DateTime.now().year,
    now?.month ?? DateTime.now().month,
    now?.day ?? DateTime.now().day,
  );
  int priority(ActionItem item) {
    if (item.action != 'report') return 2;
    final due = DateTime.parse(item.round['due_date'] as String);
    if (due.isBefore(today)) return 0;
    if (due == today) return 1;
    return 3;
  }

  result.sort((a, b) {
    var order = priority(a).compareTo(priority(b));
    if (order == 0) {
      order = (a.round['due_date'] as String).compareTo(
        b.round['due_date'] as String,
      );
    }
    if (order == 0) order = a.circle.id.compareTo(b.circle.id);
    if (order == 0) {
      order = '${a.obligation?['id'] ?? a.action}'.compareTo(
        '${b.obligation?['id'] ?? b.action}',
      );
    }
    return order;
  });
  return result;
}

/// Canonical ASCII input for Odoo Decimal; no floating point conversion.
String normalizeNumber(String value) {
  return String.fromCharCodes(
    value.trim().codeUnits.map((c) {
      if (c >= 0x660 && c <= 0x669) return c - 0x660 + 48;
      if (c >= 0x6f0 && c <= 0x6f9) return c - 0x6f0 + 48;
      return c == 0x66b ? 46 : c;
    }),
  );
}

int? parseMinor(String text, int decimals) {
  final value = normalizeNumber(text);
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final fraction = parts.length > 1 ? parts[1] : '';
  if (fraction.length > decimals) return null;
  final result =
      BigInt.parse(parts[0]) * BigInt.from(10).pow(decimals) +
      BigInt.parse(
        fraction.padRight(decimals, '0').isEmpty
            ? '0'
            : fraction.padRight(decimals, '0'),
      );
  if (result <= BigInt.zero || result > BigInt.from(9000000000000000)) {
    return null;
  }
  return result.toInt();
}

DateTime scheduleDate(DateTime start, String cadence, int interval, int index) {
  final offset = interval * index;
  if (cadence == 'month') {
    final first = DateTime(start.year, start.month + offset);
    final last = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, min(start.day, last));
  }
  final value = DateTime.utc(
    start.year,
    start.month,
    start.day,
  ).add(Duration(days: offset * (cadence == 'week' ? 7 : 1)));
  return DateTime(value.year, value.month, value.day);
}
