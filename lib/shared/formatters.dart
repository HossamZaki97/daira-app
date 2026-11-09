import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

String dateLabel(String value, String locale) =>
    DateFormat.yMMMd(locale).format(DateTime.parse(value));
String timeLabel(DateTime value, String locale) =>
    DateFormat.jm(locale).format(value.toLocal());
String timestampLabel(String value, String locale) {
  final date = DateTime.parse(value).toLocal();
  return '${DateFormat.yMMMd(locale).format(date)}${locale.startsWith('ar') ? '،' : ','} ${timeLabel(date, locale)}';
}

String reportedLabel(
  AppLocalizations t,
  String name,
  String value, {
  DateTime? now,
}) {
  final date = DateTime.parse(value).toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final time = timeLabel(date, t.localeName);
  return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day
      ? t.reportedToday(name, time)
      : t.reportedOn(name, DateFormat.yMMMd(t.localeName).format(date), time);
}

bool overdue(String date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return DateTime.parse(
    date,
  ).isBefore(DateTime(today.year, today.month, today.day));
}
