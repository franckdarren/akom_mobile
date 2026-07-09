import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:akom_scanner/core/errors/app_exception.dart';
import 'package:akom_scanner/features/auth/data/auth_provider.dart';
import 'package:akom_scanner/features/auth/data/auth_repository.dart';
import 'package:akom_scanner/features/auth/presentation/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _wrap({AuthRepository? authRepo}) => ProviderScope(
      overrides: [
        if (authRepo != null)
          authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );

void main() {
  group('LoginScreen — rendu', () {
    testWidgets('affiche le champ email et le champ mot de passe', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('affiche le logo Akôm Scanner', (tester) async {
      await tester.pumpWidget(_wrap());
      expect(find.text('Akôm Scanner'), findsOneWidget);
    });
  });

  group('LoginScreen — validation formulaire', () {
    testWidgets('email vide déclenche le validateur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      expect(find.text('Veuillez saisir votre email'), findsOneWidget);
    });

    testWidgets('email sans @ déclenche le validateur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.enterText(find.byType(TextFormField).first, 'invalide');
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('mot de passe vide déclenche le validateur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.enterText(find.byType(TextFormField).first, 'test@email.com');
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      expect(find.text('Veuillez saisir votre mot de passe'), findsOneWidget);
    });

    testWidgets('mot de passe trop court déclenche le validateur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.enterText(find.byType(TextFormField).first, 'test@email.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Se connecter'));
      await tester.pump();
      expect(find.text('Mot de passe trop court'), findsOneWidget);
    });
  });

  group('LoginScreen — erreurs auth', () {
    testWidgets('affiche le message d erreur en cas d AuthException', (tester) async {
      final mock = MockAuthRepository();
      when(
        () => mock.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Email ou mot de passe incorrect.'));

      await tester.pumpWidget(_wrap(authRepo: mock));
      await tester.enterText(find.byType(TextFormField).first, 'test@email.com');
      await tester.enterText(find.byType(TextFormField).last, 'motdepasse');
      await tester.tap(find.text('Se connecter'));
      await tester.pump(); // lance le Future
      await tester.pump(); // rebuild après setState

      expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    });
  });
}
