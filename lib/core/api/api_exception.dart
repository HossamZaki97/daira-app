/// A failed API call. [code] is the server error code (see api/openapi.json)
/// or one of the client codes: `offline`, `unavailable`.
class ApiException implements Exception {
  const ApiException(this.code, {this.status = 0, this.field});

  final String code;
  final int status;

  /// The input field the server rejected, when it says so.
  final String? field;

  bool get isOffline => code == 'offline';

  /// The data changed on the server; reload before trying again.
  bool get isConflict => code == 'conflict' || code == 'invalid_transition';

  /// Ends the session on this device.
  bool get endsSession => code == 'session_expired' || code == 'account_suspended';

  @override
  String toString() => 'ApiException($code${field == null ? '' : ', $field'})';
}

/// App-wide signals raised by any call, handled once by the router.
enum ApiSignal { signedOut, suspended, updateRequired, maintenance }
