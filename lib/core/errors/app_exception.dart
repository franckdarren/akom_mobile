sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  final int? statusCode;
  const NetworkException(super.message, {this.statusCode});
}

final class AuthException extends AppException {
  const AuthException(super.message);
}

final class ServerException extends AppException {
  final int statusCode;
  const ServerException(super.message, {required this.statusCode});
}

final class OfflineException extends AppException {
  const OfflineException([
    super.message =
        'Pas de connexion internet. Les modifications seront synchronisées au retour en ligne.',
  ]);
}

final class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  const ValidationException(super.message, {this.fieldErrors});
}
