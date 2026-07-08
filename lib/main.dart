import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env/env.dart';
import 'core/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.supabaseUrl.isEmpty ||
      Env.supabaseAnonKey.isEmpty ||
      Env.apiBaseUrl.isEmpty) {
    throw StateError(
      'Variables d\'environnement manquantes (SUPABASE_URL / SUPABASE_ANON_KEY / '
      'API_BASE_URL). Lancez avec --dart-define-from-file=.env.development.',
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
