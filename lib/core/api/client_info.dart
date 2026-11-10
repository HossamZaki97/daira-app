import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';

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

  /// ISO country where the phone is, e.g. EG. Used only to suggest a currency.
  /// Android: mobile network, then SIM (the phone language region is often
  /// "United States" and says nothing about the country). iOS: region setting.
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
    final region = await _country(platform);
    return ClientInfo(
      platform: platform,
      version: version,
      build: build,
      device: Platform.operatingSystemVersion.replaceAll(RegExp(r'[^\x20-\x7E]'), ''),
      country: region.length == 2 ? region.toUpperCase() : '',
    );
  }

  static const _device = MethodChannel('daira/device');

  static Future<String> _country(String platform) async {
    if (platform == 'android') {
      try {
        return await _device.invokeMethod<String>('country') ?? '';
      } catch (_) {
        return '';
      }
    }
    if (platform == 'ios') return PlatformDispatcher.instance.locale.countryCode ?? '';
    return '';
  }

  Map<String, String> get headers => {
    'X-Platform': platform,
    'X-App-Version': versionHeader,
    if (device.isNotEmpty) 'X-Device': device.length > 80 ? device.substring(0, 80) : device,
    if (country.isNotEmpty) 'X-Country': country,
  };
}
