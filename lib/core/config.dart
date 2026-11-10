import 'dart:io';

/// Deep-link scheme of this build: daira:// (prod) or daira-dev:// (dev), set
/// with --dart-define=APP_SCHEME and matching the Android flavor.
const appLinkScheme = String.fromEnvironment('APP_SCHEME', defaultValue: 'daira');

final _inviteCode = RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{12}$');

/// A link that opened the app.
sealed class DeepLink {
  const DeepLink();

  /// daira://join?invite=CODE   -> [InviteLink]
  /// daira://auth-callback      -> [AuthCallbackLink] (email confirmed or password reset in the browser)
  static DeepLink? parse(Uri uri) {
    if (uri.scheme != appLinkScheme ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return null;
    }
    if (uri.host == 'auth-callback') return const AuthCallbackLink();
    if (uri.host != 'join') return null;
    final values = uri.queryParametersAll;
    if (values.length != 1 || values['invite']?.length != 1) return null;
    final code = normalizeInviteCode(values['invite']!.single);
    return code == null ? null : InviteLink(code);
  }
}

class InviteLink extends DeepLink {
  const InviteLink(this.code);
  final String code;
}

class AuthCallbackLink extends DeepLink {
  const AuthCallbackLink();
}

/// Accepts what people paste ("abcd-efgh 2345") and returns the 12-character code.
String? normalizeInviteCode(String input) {
  final code = input.replaceAll(RegExp(r'[\s\-‐-―]'), '').toUpperCase();
  return _inviteCode.hasMatch(code) ? code : null;
}

/// Where the Odoo backend lives. Set with --dart-define=ODOO_URL=https://…
class AppConfig {
  const AppConfig(this.baseUrl, {this.allowLocalHttp = false});

  factory AppConfig.environment() => const AppConfig(
    String.fromEnvironment('ODOO_URL', defaultValue: 'http://10.0.2.2:8019'),
    allowLocalHttp: bool.fromEnvironment(
      'ALLOW_LOCAL_HTTP',
      defaultValue: !bool.fromEnvironment('dart.vm.product'),
    ),
  );

  static const apiPrefix = '/daira/api/v1';

  final String baseUrl;
  final bool allowLocalHttp;

  /// Separates stored sessions per server.
  String get scope => Uri.parse(baseUrl).origin;

  /// Builds `<server>/daira/api/v1/<path>`; refuses plain HTTP except to a
  /// private address in debug builds.
  Uri endpoint(String path, [Map<String, String>? query]) {
    final root = Uri.parse(baseUrl);
    if (!RegExp(r'^/[A-Za-z0-9_\-/]+$').hasMatch(path) ||
        path.contains('//') ||
        root.userInfo.isNotEmpty ||
        root.hasQuery ||
        root.hasFragment ||
        (root.path.isNotEmpty && root.path != '/') ||
        (root.scheme != 'https' &&
            !(allowLocalHttp && root.scheme == 'http' && _isPrivate(root.host)))) {
      throw ArgumentError('The server must use HTTPS (plain HTTP only for a local server in debug).');
    }
    return root.replace(
      path: '$apiPrefix$path',
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  static bool _isPrivate(String host) {
    if (host == 'localhost') return true;
    final ip = InternetAddress.tryParse(host);
    if (ip == null) return false;
    if (ip.isLoopback) return true;
    final b = ip.rawAddress;
    return b.length == 4 &&
        (b[0] == 10 || (b[0] == 192 && b[1] == 168) || (b[0] == 172 && b[1] >= 16 && b[1] <= 31));
  }
}
