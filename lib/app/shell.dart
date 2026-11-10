import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import '../core/providers.dart';
import '../core/push.dart';
import '../design/design.dart';
import '../features/state.dart';
import '../l10n/messages.dart';
import 'router.dart';

/// Signed-in frame: four tabs, the unread badge, links that opened the app,
/// and a refresh whenever the app comes back to the foreground.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;
  late final PushController _push;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () {
      refreshLists(ref.invalidate);
      ref.read(startupProvider.notifier).load(quiet: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLink(ref.read(pendingLinkProvider)));
    _push = PushController(
      ref,
      onOpenCircle: (id) {
        if (mounted) context.push(Routes.circle(id));
      },
      onForeground: (title) {
        refreshLists(ref.invalidate);
        if (mounted && title != null) showToast(context, title);
      },
    );
    _push.start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _push.dispose();
    super.dispose();
  }

  void _openLink(DeepLink? link) {
    if (link == null || !mounted) return;
    ref.read(pendingLinkProvider.notifier).state = null;
    if (link is InviteLink) context.push(Routes.join(link.code));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingLinkProvider, (_, next) => _openLink(next));
    ref.listen(localeProvider, (_, _) => _push.languageChanged());
    final t = context.l10n;
    final unread = ref.watch(unreadProvider).valueOrNull ?? 0;
    final badge = unread > 99 ? '99+' : '$unread';
    final shell = widget.shell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colors.line))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            NavigationDestination(icon: const Icon(AppIcons.home), selectedIcon: const Icon(AppIcons.homeActive), label: t.tabHome),
            NavigationDestination(
              icon: const Icon(AppIcons.circles),
              selectedIcon: const Icon(AppIcons.circlesActive),
              label: t.tabCircles,
            ),
            NavigationDestination(
              icon: Badge(isLabelVisible: unread > 0, label: Text(badge), child: const Icon(AppIcons.notifications)),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text(badge),
                child: const Icon(AppIcons.notificationsActive),
              ),
              label: t.tabNotifications,
            ),
            NavigationDestination(
              icon: const Icon(AppIcons.account),
              selectedIcon: const Icon(AppIcons.accountActive),
              label: t.tabAccount,
            ),
          ],
        ),
      ),
    );
  }
}
