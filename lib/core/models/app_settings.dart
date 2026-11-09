import 'json.dart';

/// GET /app/config — everything the backend decides at start-up.
class AppSettings {
  const AppSettings({
    required this.apiVersion,
    required this.maintenance,
    required this.update,
    required this.signupEnabled,
    required this.features,
    required this.currencies,
    required this.defaultCurrency,
    required this.suggestedCurrency,
    required this.limits,
    required this.announcements,
    required this.content,
  });

  factory AppSettings.fromJson(Json json) => AppSettings(
    apiVersion: json.integer('api_version'),
    maintenance: Maintenance.fromJson(json.obj('maintenance')),
    update: UpdateInfo.fromJson(json.obj('update')),
    signupEnabled: json['signup_enabled'] != false,
    features: Features.fromJson(json.obj('features')),
    currencies: [for (final c in json.list('currencies')) Currency.fromJson(c)],
    defaultCurrency: json.str('default_currency', 'EGP'),
    suggestedCurrency: json.str('suggested_currency', json.str('default_currency', 'EGP')),
    limits: Limits.fromJson(json.obj('limits')),
    announcements: [for (final a in json.list('announcements')) Announcement.fromJson(a)],
    content: json.strings('content'),
  );

  final int apiVersion;
  final Maintenance maintenance;
  final UpdateInfo update;
  final bool signupEnabled;
  final Features features;
  final List<Currency> currencies;
  final String defaultCurrency;

  /// From the phone's country when that currency is allowed, otherwise the default.
  final String suggestedCurrency;
  final Limits limits;
  final List<Announcement> announcements;

  /// Content pages that exist: onboarding, faq, terms, privacy, help.
  final List<String> content;

  Currency? currency(String code) {
    for (final c in currencies) {
      if (c.code == code) return c;
    }
    return null;
  }
}

class Maintenance {
  const Maintenance({this.active = false, this.message, this.until});
  factory Maintenance.fromJson(Json json) =>
      Maintenance(active: json.flag('active'), message: json.strOrNull('message'), until: json.strOrNull('until'));

  final bool active;
  final String? message;

  /// Free text set by staff ("10:00 PM Cairo time").
  final String? until;
}

class UpdateInfo {
  const UpdateInfo({
    this.required = false,
    this.available = false,
    this.latestVersion,
    this.latestBuild,
    this.notes,
    this.requiredFrom,
    this.storeUrl,
  });

  factory UpdateInfo.fromJson(Json json) => UpdateInfo(
    required: json.flag('required'),
    available: json.flag('available'),
    latestVersion: json.strOrNull('latest_version'),
    latestBuild: json.intOrNull('latest_build'),
    notes: json.strOrNull('notes'),
    requiredFrom: json.date('required_from'),
    storeUrl: json.strOrNull('store_url'),
  );

  /// This build is blocked until the person updates.
  final bool required;

  /// A newer build exists (optional update).
  final bool available;
  final String? latestVersion;
  final int? latestBuild;
  final String? notes;

  /// A newer build becomes mandatory at this time (grace period).
  final DateTime? requiredFrom;
  final String? storeUrl;
}

class Features {
  const Features({
    this.invitations = true,
    this.importHistory = true,
    this.multiShares = true,
    this.turnOrder = true,
  });

  factory Features.fromJson(Json json) => Features(
    invitations: json['invitations'] != false,
    importHistory: json['import_history'] != false,
    multiShares: json['multi_shares'] != false,
    turnOrder: json['turn_order'] != false,
  );

  final bool invitations;
  final bool importHistory;
  final bool multiShares;
  final bool turnOrder;
}

class Currency {
  const Currency({required this.code, required this.decimals, this.symbol = ''});
  factory Currency.fromJson(Json json) =>
      Currency(code: json.str('code'), decimals: json.integer('decimals', 2), symbol: json.str('symbol'));

  final String code;
  final int decimals;
  final String symbol;
}

class Limits {
  const Limits({
    this.maxMembers = 60,
    this.maxShares = 20,
    this.maxTotalShares = 120,
    this.minPassword = 8,
    this.inviteHours = 72,
  });

  factory Limits.fromJson(Json json) => Limits(
    maxMembers: json.integer('max_members', 60),
    maxShares: json.integer('max_shares', 20),
    maxTotalShares: json.integer('max_total_shares', 120),
    minPassword: json.integer('min_password', 8),
    inviteHours: json.integer('invite_hours', 72),
  );

  final int maxMembers;
  final int maxShares;
  final int maxTotalShares;
  final int minPassword;
  final int inviteHours;
}

class Announcement {
  const Announcement({required this.id, required this.title, this.body, this.warning = false, this.dismissible = true});
  factory Announcement.fromJson(Json json) => Announcement(
    id: json.integer('id'),
    title: json.str('title'),
    body: json.strOrNull('body'),
    warning: json.str('level') == 'warning',
    dismissible: json['dismissible'] != false,
  );

  final int id;
  final String title;
  final String? body;
  final bool warning;
  final bool dismissible;
}

/// GET /app/content/{slug}
class ContentPage {
  const ContentPage({required this.slug, required this.items, this.updatedAt});
  factory ContentPage.fromJson(Json json) => ContentPage(
    slug: json.str('slug'),
    items: [for (final i in json.list('items')) ContentItem(i.str('title'), i.str('body'))],
    updatedAt: json.date('updated_at'),
  );

  final String slug;
  final List<ContentItem> items;
  final DateTime? updatedAt;
}

class ContentItem {
  const ContentItem(this.title, this.body);
  final String title;
  final String body;
}
