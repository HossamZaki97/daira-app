import 'dart:io';

// Keep this fork independent from the installed Supabase edition.
const appLinkScheme = 'daira-odoo';

String? invitationCodeFromUri(Uri uri) {
  if (uri.scheme != appLinkScheme ||
      uri.host != 'join' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.hasFragment ||
      uri.queryParametersAll.length != 1 ||
      uri.queryParametersAll['invite']?.length != 1) {
    return null;
  }
  final code = uri.queryParameters['invite'];
  return code != null &&
          RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{12}$').hasMatch(code)
      ? code
      : null;
}

class AppConfig {
  const AppConfig(this.baseUrl, {this.allowLocalHttp = false});
  factory AppConfig.environment() => const AppConfig(
    String.fromEnvironment('ODOO_URL', defaultValue: 'http://10.0.2.2:8019'),
    allowLocalHttp: bool.fromEnvironment(
      'ALLOW_LOCAL_HTTP',
      defaultValue: !bool.fromEnvironment('dart.vm.product'),
    ),
  );
  final String baseUrl;
  final bool allowLocalHttp;
  String get scope => Uri.parse(baseUrl).origin;
  Uri endpoint(String action) {
    final root = Uri.parse(baseUrl);
    final host = root.host;
    final ip = InternetAddress.tryParse(host);
    final bytes = ip?.rawAddress;
    final local =
        host == 'localhost' ||
        ip?.isLoopback == true ||
        bytes != null &&
            bytes.length == 4 &&
            (bytes[0] == 10 ||
                bytes[0] == 192 && bytes[1] == 168 ||
                bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31);
    if (!RegExp(r'^[a-z_]+$').hasMatch(action) ||
        root.userInfo.isNotEmpty ||
        root.hasQuery ||
        root.hasFragment ||
        root.path.isNotEmpty && root.path != '/' ||
        (root.scheme != 'https' &&
            !(allowLocalHttp && local && root.scheme == 'http'))) {
      throw ArgumentError(
        'Odoo requires HTTPS, or explicitly enabled private local HTTP.',
      );
    }
    return root.resolve('/daira/api/v1/$action');
  }
}
