import '../api/api_client.dart';
import '../models/account.dart';
import '../models/activity.dart';
import '../models/app_settings.dart';
import '../models/circle.dart';
import '../models/json.dart';

/// Start-up configuration and content pages (no sign-in needed).
class AppRepository {
  const AppRepository(this._api);
  final ApiClient _api;

  Future<AppSettings> config() async => AppSettings.fromJson(await _api.get('/app/config', auth: false));

  Future<ContentPage> content(String slug) async =>
      ContentPage.fromJson(await _api.get('/app/content/$slug', auth: false));
}

/// Sign-up, sign-in and email flows.
class AuthRepository {
  const AuthRepository(this._api);
  final ApiClient _api;

  Future<Session> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {'email': email, 'password': password}, auth: false);
    return _api.startSession(data);
  }

  /// Always answers "confirmation required" — the email decides what happens next.
  Future<void> signup({required String name, required String email, required String password, required String lang}) =>
      _api.post('/auth/signup', body: {'name': name, 'email': email, 'password': password, 'lang': lang}, auth: false);

  /// Confirms the email with the 8-digit code. Does not sign in.
  Future<void> verifyCode(String email, String code) =>
      _api.post('/auth/email/verify', body: {'email': email, 'code': code}, auth: false);

  Future<void> resendConfirmation(String email) =>
      _api.post('/auth/email/resend', body: {'email': email}, auth: false);

  Future<void> forgotPassword(String email) => _api.post('/auth/password/forgot', body: {'email': email}, auth: false);

  Future<void> logout() => _api.logout();
}

/// The signed-in account.
class AccountRepository {
  const AccountRepository(this._api);
  final ApiClient _api;

  Future<Profile> me() async {
    final profile = Profile.fromJson(await _api.get('/me'));
    await _api.updateProfile(profile);
    return profile;
  }

  Future<Profile> update({String? name, String? lang}) async {
    final profile = Profile.fromJson(
      await _api.patch('/me', body: {if (name != null) 'name': name, if (lang != null) 'lang': lang}),
    );
    await _api.updateProfile(profile);
    return profile;
  }

  Future<void> changePassword(String current, String next) =>
      _api.post('/me/password', body: {'current_password': current, 'new_password': next});

  /// Blocked by the server while the person is in an active circle (`active_membership`).
  Future<void> deleteAccount(String password) async {
    await _api.delete('/me', body: {'password': password});
    await _api.endSession();
  }

  Future<List<DeviceSession>> sessions() async =>
      [for (final s in (await _api.get('/me/sessions')).list('sessions')) DeviceSession.fromJson(s)];

  /// [id] = a session id, or `others` for every session except this one.
  Future<int> endSession(String id) async => (await _api.delete('/me/sessions/$id')).integer('ended');

  Future<String> registerDevice({required String token, required String platform, required String lang}) async =>
      (await _api.post('/me/devices', body: {'token': token, 'platform': platform, 'lang': lang})).str('id');

  Future<void> forgetDevice(String id) => _api.delete('/me/devices/$id');

  Future<HomeData> home() async => HomeData.fromJson(await _api.get('/home'));
}

enum CircleFilter { active, draft, completed }

/// Circles, payments and invitations. Every money command takes a [commandId]
/// (see [newCommandId]) — reuse it when retrying the same action.
class CirclesRepository {
  const CirclesRepository(this._api);
  final ApiClient _api;

  Future<List<CircleSummary>> list([CircleFilter? filter]) async {
    final data = await _api.get('/circles', query: filter == null ? null : {'status': filter.name});
    return [for (final c in data.list('circles')) CircleSummary.fromJson(c)];
  }

  Future<Circle> get(String id) async => Circle.fromJson(await _api.get('/circles/$id'));

  /// Saves a plan as draft, or activates it right away with `activate: true` in [plan].
  Future<Circle> create(Json plan, String commandId) async =>
      Circle.fromJson(await _api.post('/circles', body: plan, idempotencyKey: commandId));

  Future<Circle> updateDraft(String id, Json plan, String commandId) async =>
      Circle.fromJson(await _api.patch('/circles/$id', body: plan, idempotencyKey: commandId));

  Future<Circle> activate(String id, int version, String commandId) async => Circle.fromJson(
    await _api.post('/circles/$id/activate', body: {'version': version}, idempotencyKey: commandId),
  );

  Future<Paged<CircleEvent>> events(String id, {String? cursor, int limit = 30}) async {
    final data = await _api.get(
      '/circles/$id/events',
      query: {'limit': '$limit', if (cursor != null) 'cursor': cursor},
    );
    return Paged([for (final e in data.list('events')) CircleEvent.fromJson(e)], nextCursor: data.strOrNull('next_cursor'));
  }

  /// Member: «دفعت القسط».
  Future<Circle> reportPayment(String circleId, Obligation o, String commandId) =>
      _obligation(circleId, o, 'report', commandId);

  /// Organizer: «وصلني».
  Future<Circle> approvePayment(String circleId, Obligation o, String commandId) =>
      _obligation(circleId, o, 'approve', commandId);

  /// Organizer: «لم يصلني» — [reason] is required.
  Future<Circle> rejectPayment(String circleId, Obligation o, String reason, String commandId) =>
      _obligation(circleId, o, 'reject', commandId, reason: reason);

  /// Organizer: «سلّمت المبلغ».
  Future<Circle> reportPayout(String circleId, int round, String commandId, {String? note}) async => Circle.fromJson(
    await _api.post(
      '/circles/$circleId/rounds/$round/payout',
      body: {if (note != null && note.isNotEmpty) 'note': note},
      idempotencyKey: commandId,
    ),
  );

  /// Recipient: «استلمت» — closes the round.
  Future<Circle> confirmReceipt(String circleId, int round, String commandId) async => Circle.fromJson(
    await _api.post('/circles/$circleId/rounds/$round/receipt', idempotencyKey: commandId),
  );

  Future<Circle> _obligation(String circleId, Obligation o, String action, String commandId, {String? reason}) async =>
      Circle.fromJson(
        await _api.post(
          '/circles/$circleId/obligations/${o.id}/$action',
          body: {'version': o.version, if (reason != null) 'reason': reason},
          idempotencyKey: commandId,
        ),
      );

  // ------------------------------------------------------------ invitations
  Future<List<Invitation>> invitations(String circleId) async =>
      [for (final i in (await _api.get('/circles/$circleId/invitations')).list('invitations')) Invitation.fromJson(i)];

  /// The returned [Invitation.code] is shown only now; the server keeps a hash.
  Future<Invitation> invite(String circleId, String memberId) async =>
      Invitation.fromJson(await _api.post('/circles/$circleId/members/$memberId/invitation'));

  Future<void> revokeInvitation(String invitationId) => _api.delete('/invitations/$invitationId');

  Future<InvitationPreview> previewInvitation(String code) async =>
      InvitationPreview.fromJson(await _api.post('/invitations/preview', body: {'code': code}));

  /// Returns the joined circle id.
  Future<String> acceptInvitation(String code, String invitationId, String commandId) async => (await _api.post(
    '/invitations/accept',
    body: {'code': code, 'invitation_id': invitationId},
    idempotencyKey: commandId,
  )).str('circle_id');
}

class NotificationsRepository {
  const NotificationsRepository(this._api);
  final ApiClient _api;

  Future<Paged<AppNotification>> page({String? cursor, int limit = 30}) async {
    final data = await _api.get('/notifications', query: {'limit': '$limit', if (cursor != null) 'cursor': cursor});
    return Paged(
      [for (final n in data.list('notifications')) AppNotification.fromJson(n)],
      nextCursor: data.strOrNull('next_cursor'),
      unread: data.integer('unread'),
    );
  }

  Future<int> unreadCount() async => (await _api.get('/notifications/unread-count')).integer('unread');

  /// Marks [ids] read, or everything when [ids] is null. Returns the unread count.
  Future<int> markRead([List<String>? ids]) async => (await _api.post(
    '/notifications/read',
    body: ids == null ? {'all': true} : {'ids': ids},
  )).integer('unread');
}
