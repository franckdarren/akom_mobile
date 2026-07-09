import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env/env.dart';
import 'core/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.load();

  if (Env.supabaseUrl.isEmpty ||
      Env.supabaseAnonKey.isEmpty ||
      Env.apiBaseUrl.isEmpty) {
    throw StateError(
      'Variables d\'environnement manquantes (SUPABASE_URL / SUPABASE_ANON_KEY / '
      'API_BASE_URL). Vérifiez le contenu de .env.development / .env.production.',
    );
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AkomApp(),
    ),
  );
}
