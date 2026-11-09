import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/preview/preview_screen.dart';
import '../features/startup/gate_screens.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const maintenance = '/maintenance';
  static const update = '/update';
  static const offline = '/offline';
  static const signIn = '/sign-in';
  static const home = '/';

  static const gates = {splash, maintenance, update, offline};
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
  if (!signedIn) return location == Routes.signIn ? null : Routes.signIn;
  if (location == Routes.signIn || Routes.gates.contains(location)) return Routes.home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(startupProvider.select((s) => s.status), (_, _) => refresh.value++);
  ref.listen(sessionProvider.select((s) => s != null), (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      status: ref.read(startupProvider).status,
      signedIn: ref.read(sessionProvider) != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.maintenance, builder: (_, _) => const MaintenanceScreen()),
      GoRoute(path: Routes.update, builder: (_, _) => const UpdateRequiredScreen()),
      GoRoute(path: Routes.offline, builder: (_, _) => const OfflineScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const PreviewScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
