import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide LocalStorage, AuthException;

import '../env/env.dart';
import '../errors/app_exception.dart';
import '../storage/local_storage.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(localStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: '${Env.apiBaseUrl}/api/mobile',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.addAll([
    _AuthInterceptor(dio, storage),
    _ErrorInterceptor(),
  ]);
  return dio;
});

// Gère l'injection du token + restaurant_id, et le retry automatique sur 401.
// QueuedInterceptor évite les rafales de refresh simultanés.
class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._dio, this._storage);

  final Dio _dio;
  final LocalStorage _storage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    final restaurantId = _storage.restaurantId;
    if (restaurantId != null) {
      options.headers['x-restaurant-id'] = restaurantId;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final isRetry = err.requestOptions.headers.containsKey('X-Retry');

    if (is401 && !isRetry) {
      try {
        await Supabase.instance.client.auth.refreshSession();
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          err.requestOptions.headers['Authorization'] =
              'Bearer ${session.accessToken}';
          err.requestOptions.headers['X-Retry'] = '1';
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh échoué — l'erreur 401 originale est propagée
      }
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        stackTrace: err.stackTrace,
        error: _toAppException(err),
        message: _toAppException(err).message,
      ),
    );
  }

  AppException _toAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Délai de connexion dépassé. Vérifiez votre réseau.',
        );
      case DioExceptionType.connectionError:
        return const OfflineException();
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        if (code == 401) {
          return const AuthException('Session expirée. Veuillez vous reconnecter.');
        }
        if (code == 403) {
          return const AuthException('Accès refusé.');
        }
        if (code >= 500) {
          return ServerException('Erreur serveur. Réessayez plus tard.', statusCode: code);
        }
        final msg = (err.response?.data as Map<String, dynamic>?)?['error']
            as String?;
        return NetworkException(msg ?? 'Erreur réseau.', statusCode: code);
      default:
        return const NetworkException('Une erreur réseau est survenue.');
    }
  }
}
