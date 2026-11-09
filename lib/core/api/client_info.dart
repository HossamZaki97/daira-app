import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:package_info_plus/package_info_plus.dart';

/// Describes this install to the server (X-Platform, X-App-Version, X-Device,
/// X-Country). The server uses it for update rules, currencies and the session list.
class ClientInfo {
  const ClientInfo({
    required this.platform,
    required this.version,
    required this.build,
    this.device = '',
    this.country = '',
  });

  /// android | ios | other
  final String platform;

  /// e.g. 2.0.0
  final String version;

  /// Store build number, e.g. 21.
  final int build;
  final String device;

  /// ISO country of the phone region, e.g. EG. Used only to suggest a currency.
  final String country;

  /// What the server parses: "2.0.0+21".
  String get versionHeader => '$version+$build';

  static Future<ClientInfo> load() async {
    var version = '0.0.0';
    var build = 0;
    try {
      final package = await PackageInfo.fromPlatform();
      version = package.version;
      build = int.tryParse(package.buildNumber) ?? 0;
    } catch (_) {
      // Tests and unsupported platforms: the server treats the build as unknown.
    }
    final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other');
    final region = PlatformDispatcher.instance.locale.countryCode ?? '';
    return ClientInfo(
      platform: platform,
      version: version,
      build: build,
      device: Platform.operatingSystemVersion.replaceAll(RegExp(r'[^\x20-\x7E]'), ''),
      country: region.length == 2 ? region.toUpperCase() : '',
    );
  }

  Map<String, String> get headers => {
    'X-Platform': platform,
    'X-App-Version': versionHeader,
    if (device.isNotEmpty) 'X-Device': device.length > 80 ? device.substring(0, 80) : device,
    if (country.isNotEmpty) 'X-Country': country,
  };
}
