import 'package:flutter_test/flutter_test.dart';

import 'package:akom_scanner/core/errors/app_exception.dart';

void main() {
  group('AppException hierarchy', () {
    test('NetworkException stores message and optional statusCode', () {
      const e = NetworkException('Erreur réseau', statusCode: 503);
      expect(e.message, 'Erreur réseau');
      expect(e.statusCode, 503);
      expect(e.toString(), 'Erreur réseau');
      expect(e, isA<AppException>());
    });

    test('NetworkException without statusCode', () {
      const e = NetworkException('Pas de réseau');
      expect(e.statusCode, isNull);
    });

    test('AuthException', () {
      const e = AuthException('Session expirée');
      expect(e.message, 'Session expirée');
      expect(e.toString(), 'Session expirée');
      expect(e, isA<AppException>());
    });

    test('ServerException stores statusCode', () {
      const e = ServerException('Erreur interne', statusCode: 500);
      expect(e.statusCode, 500);
      expect(e, isA<AppException>());
    });

    test('OfflineException has default French message', () {
      const e = OfflineException();
      expect(e.message, contains('connexion internet'));
      expect(e, isA<AppException>());
    });

    test('OfflineException accepts custom message', () {
      const e = OfflineException('Mode hors ligne activé.');
      expect(e.message, 'Mode hors ligne activé.');
    });

    test('ValidationException stores fieldErrors', () {
      const e = ValidationException(
        'Formulaire invalide',
        fieldErrors: {'name': 'Champ obligatoire', 'price': 'Doit être > 0'},
      );
      expect(e.fieldErrors!['name'], 'Champ obligatoire');
      expect(e.fieldErrors!['price'], 'Doit être > 0');
      expect(e, isA<AppException>());
    });

    test('ValidationException without fieldErrors', () {
      const e = ValidationException('Données invalides');
      expect(e.fieldErrors, isNull);
    });

    test('all exceptions implement Exception', () {
      expect(const NetworkException('x'), isA<Exception>());
      expect(const AuthException('x'), isA<Exception>());
      expect(const ServerException('x', statusCode: 400), isA<Exception>());
      expect(const OfflineException(), isA<Exception>());
      expect(const ValidationException('x'), isA<Exception>());
    });
  });
}
