import 'json.dart';

class Profile {
  const Profile({required this.id, required this.name, required this.email, this.lang = 'ar'});
  factory Profile.fromJson(Json json) =>
      Profile(id: json.str('id'), name: json.str('name'), email: json.str('email'), lang: json.str('lang', 'ar'));

  final String id;
  final String name;
  final String email;
  final String lang;

  Json toJson() => {'id': id, 'name': name, 'email': email, 'lang': lang};
}

/// One signed-in phone, from GET /me/sessions.
class DeviceSession {
  const DeviceSession({
    required this.id,
    this.device,
    this.platform,
    this.appVersion,
    this.lastUsedAt,
    this.current = false,
  });

  factory DeviceSession.fromJson(Json json) => DeviceSession(
    id: json.str('id'),
    device: json.strOrNull('device'),
    platform: json.strOrNull('platform'),
    appVersion: json.strOrNull('app_version'),
    lastUsedAt: json.date('last_used_at'),
    current: json.flag('current'),
  );

  final String id;
  final String? device;
  final String? platform;
  final String? appVersion;
  final DateTime? lastUsedAt;
  final bool current;
}
