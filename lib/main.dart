import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/api/client_info.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'core/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.environment();
  final firebase = await initFirebase();
  final preferences = await SharedPreferences.getInstance();
  final info = await ClientInfo.load();
  final api = ApiClient(config, SecureSessionVault(config.scope), info);
  await api.restore();
  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        clientInfoProvider.overrideWithValue(info),
        apiProvider.overrideWithValue(api),
        firebaseReadyProvider.overrideWithValue(firebase),
      ],
      child: const DairaApp(),
    ),
  );
}
