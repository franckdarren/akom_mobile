import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Variables d'environnement embarquées dans l'app via `flutter_dotenv`.
/// Le fichier `.env` correspondant est déclaré comme asset (`pubspec.yaml`)
/// et donc inclus dans l'APK — aucun flag `--dart-define` n'est nécessaire
/// au lancement, y compris pour un APK partagé.
class Env {
  static Future<void> load() {
    return dotenv.load(
      fileName: kReleaseMode ? '.env.production' : '.env.development',
    );
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
}
