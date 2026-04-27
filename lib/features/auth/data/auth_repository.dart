import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/restaurant_model.dart';

class AuthRepository {
  AuthRepository({required Dio dio, required LocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final LocalStorage _storage;

  sb.Session? get currentSession =>
      sb.Supabase.instance.client.auth.currentSession;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await sb.Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final session = response.session;
      if (session == null) {
        throw const AuthException('Connexion échouée. Réessayez.');
      }

      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_mapSupabaseError(e.message));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const NetworkException(
          'Erreur réseau. Vérifiez votre connexion internet.');
    }
  }

  Future<void> signOut() async {
    try {
      await sb.Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Erreur de déconnexion ignorée — on nettoie quand même le stockage local
    }
    await _storage.clearAll();
  }

  Future<List<RestaurantModel>> getRestaurantsForUser() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/restaurants');
      final list = response.data!['restaurants'] as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(RestaurantModel.fromJson)
          .toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de charger les restaurants.');
    }
  }

  static String _mapSupabaseError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('email not confirmed')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (lower.contains('email') && lower.contains('not found')) {
      return 'Aucun compte trouvé avec cet email.';
    }
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    return 'Connexion échouée. Réessayez.';
  }
}
