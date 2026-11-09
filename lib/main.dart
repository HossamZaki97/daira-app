import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/providers.dart';
import 'core/config.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_system_ui.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(
          (_) => Locale(preferences.getString('language') ?? 'ar'),
        ),
        themeProvider.overrideWith(
          (_) => preferences.getBool('dark') == true
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      ],
      child: const DairaApp(),
    ),
  );
}

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
    final links = AppLinks();
    _links = links.uriLinkStream.listen(_link, onError: (Object _) {});
    links
        .getInitialLink()
        .then((uri) {
          if (uri != null) _link(uri);
        })
        .catchError((Object _) {});
  }

  void _link(Uri uri) {
    if (!mounted) return;
    final code = invitationCodeFromUri(uri);
    if (code != null) {
      ref.read(pendingInviteProvider.notifier).state = code;
    }
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {
      if (previous?.profile != null &&
          next.profile?['id'] != previous?.profile?['id']) {
        ref.read(pendingInviteProvider.notifier).state = null;
      }
    });
    return MaterialApp(
      key: ValueKey(auth.profile?['id'] ?? 'signed-out'),
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: auth.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.profile == null
          ? const AuthScreen()
          : const HomeScreen(),
      builder: (context, child) => DairaSystemUi(child: child!),
    );
  }
}
