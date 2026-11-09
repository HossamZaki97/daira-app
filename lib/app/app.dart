import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/providers.dart';
import '../design/theme.dart';
import '../l10n/messages.dart';
import 'router.dart';

class DairaApp extends ConsumerStatefulWidget {
  const DairaApp({super.key});

  @override
  ConsumerState<DairaApp> createState() => _DairaAppState();
}

class _DairaAppState extends ConsumerState<DairaApp> {
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    // Links are parsed here (not by the router) so a link never opens a screen
    // the person is not allowed to see; screens pick it up from pendingLinkProvider.
    final links = AppLinks();
    _links = links.uriLinkStream.listen(_onLink, onError: (Object _) {});
  }

  void _onLink(Uri uri) {
    final link = DeepLink.parse(uri);
    if (link != null && mounted) ref.read(pendingLinkProvider.notifier).state = link;
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A different account must never see the previous account's pending link.
    ref.listen(sessionProvider.select((s) => s?.profile.id), (previous, next) {
      if (previous != next) ref.read(pendingLinkProvider.notifier).state = null;
    });
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      theme: DairaTheme.light,
      darkTheme: DairaTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Large system text stays readable without breaking layouts.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.4)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
