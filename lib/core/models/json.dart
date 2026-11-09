typedef Json = Map<String, dynamic>;

/// Tolerant readers: a missing or wrongly typed value falls back instead of
/// crashing the screen. The server contract lives in api/openapi.json.
extension JsonRead on Json {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    return value is String ? value : fallback;
  }

  String? strOrNull(String key) {
    final value = this[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int integer(String key, [int fallback = 0]) => intOrNull(key) ?? fallback;

  int? intOrNull(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  bool flag(String key) => this[key] == true;

  Json obj(String key) {
    final value = this[key];
    return value is Map ? Json.from(value) : <String, dynamic>{};
  }

  List<Json> list(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Json.from(item),
    ];
  }

  List<String> strings(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }

  /// Calendar date ("2026-11-10") or UTC timestamp ("2026-11-10T08:00:00Z").
  DateTime? date(String key) {
    final value = this[key];
    return value is String ? DateTime.tryParse(value) : null;
  }
}
