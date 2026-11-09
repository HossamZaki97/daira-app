import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/account/account_screen.dart';
import '../features/account/content_screen.dart';
import '../features/account/password_screen.dart';
import '../features/account/sessions_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/auth/welcome_screen.dart';
import '../features/circles/circle_screen.dart';
import '../features/circles/circles_screen.dart';
import '../features/circles/activity_screen.dart';
import '../features/create/create_circle_screen.dart';
import '../features/home/home_screen.dart';
import '../features/invitations/join_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/startup/gate_screens.dart';
import 'shell.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const maintenance = '/maintenance';
  static const update = '/update';
  static const offline = '/offline';

  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const verify = '/verify';
  static const forgot = '/forgot';

  static const home = '/';
  static const circles = '/circles';
  static const notifications = '/notifications';
  static const account = '/account';

  static const newCircle = '/circles/new';
  static String circle(String id) => '/circles/$id';
  static String editDraft(String id) => '/circles/$id/edit';
  static String activity(String id) => '/circles/$id/activity';
  static String join([String? code]) => code == null ? '/join' : '/join?code=${Uri.encodeQueryComponent(code)}';
  static const sessions = '/account/sessions';
  static const password = '/account/password';
  static String content(String slug) => '/content/$slug';

  static const gates = {splash, maintenance, update, offline};

  /// Screens for signed-out people.
  static const auth = {welcome, signIn, signUp, verify, forgot};

  static bool isContent(String location) => location.startsWith('/content/');
}

/// Where the app must be, given the backend gates and the session. Pure, so it is unit-tested.
String? redirectFor({required StartupStatus status, required bool signedIn, required String location}) {
  final gate = switch (status) {
    StartupStatus.loading => Routes.splash,
    StartupStatus.offline || StartupStatus.unavailable => Routes.offline,
    StartupStatus.maintenance => Routes.maintenance,
    StartupStatus.updateRequired => Routes.update,
    StartupStatus.ready => null,
  };
  if (gate != null) return location == gate ? null : gate;
  if (Routes.isContent(location)) return null; // terms and privacy are readable by anyone
  if (!signedIn) return Routes.auth.contains(location) ? null : Routes.welcome;
  if (Routes.auth.contains(location) || Routes.gates.contains(location)) return Routes.home;
  return null;
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(startupProvider.select((s) => s.status), (_, _) => refresh.value++);
  ref.listen(sessionProvider.select((s) => s != null), (_, _) => refresh.value++);

  GoRoute page(String path, Widget Function(GoRouterState state) build) =>
      GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (_, state) => build(state));

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      status: ref.read(startupProvider).status,
      signedIn: ref.read(sessionProvider) != null,
      location: state.matchedLocation,
    ),
    routes: [
      page(Routes.splash, (_) => const SplashScreen()),
      page(Routes.maintenance, (_) => const MaintenanceScreen()),
      page(Routes.update, (_) => const UpdateRequiredScreen()),
      page(Routes.offline, (_) => const OfflineScreen()),
      page(Routes.welcome, (_) => const WelcomeScreen()),
      page(Routes.signIn, (s) => SignInScreen(email: s.uri.queryParameters['email'])),
      page(Routes.signUp, (_) => const SignUpScreen()),
      page(Routes.verify, (s) => VerifyEmailScreen(email: s.uri.queryParameters['email'] ?? '')),
      page(Routes.forgot, (s) => ForgotPasswordScreen(email: s.uri.queryParameters['email'])),
      page('/content/:slug', (s) => ContentScreen(slug: s.pathParameters['slug']!)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.circles, builder: (_, _) => const CirclesScreen())]),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen())],
          ),
          StatefulShellBranch(routes: [GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen())]),
        ],
      ),
      page(Routes.newCircle, (_) => const CreateCircleScreen()),
      page('/circles/:id', (s) => CircleScreen(id: s.pathParameters['id']!)),
      page('/circles/:id/edit', (s) => CreateCircleScreen(draftId: s.pathParameters['id'])),
      page('/circles/:id/activity', (s) => ActivityScreen(circleId: s.pathParameters['id']!)),
      page('/join', (s) => JoinScreen(code: s.uri.queryParameters['code'])),
      page(Routes.sessions, (_) => const SessionsScreen()),
      page(Routes.password, (_) => const PasswordScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
