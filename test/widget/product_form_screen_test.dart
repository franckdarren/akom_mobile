import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:akom_scanner/features/catalog/data/catalog_providers.dart';
import 'package:akom_scanner/features/catalog/domain/category_model.dart';
import 'package:akom_scanner/features/catalog/presentation/product_form_screen.dart';

final _testCategories = [
  CategoryModel(id: 'cat-1', name: 'Boissons', position: 1),
  CategoryModel(id: 'cat-2', name: 'Alimentaire', position: 2),
];

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ProductFormScreen()),
        GoRoute(path: '/catalog/product/:id/qr', builder: (_, _) => const Scaffold(body: Text('QR Label'))),
      ],
    );

Widget _wrap() => ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((_) => Future.value(_testCategories)),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    );

void main() {
  group('ProductFormScreen — rendu (mode création)', () {
    testWidgets('affiche le titre Nouveau produit', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Nouveau produit'), findsOneWidget);
    });

    testWidgets('affiche les champs Nom et Prix', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Nom du produit *'), findsOneWidget);
      expect(find.text('Prix (FCFA) *'), findsOneWidget);
    });

    testWidgets('affiche le bouton Créer le produit (après scroll)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Créer le produit'));
      expect(find.text('Créer le produit'), findsOneWidget);
    });

    testWidgets('affiche le dropdown Catégorie après résolution async', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(); // attendre le Future<List<CategoryModel>>
      // Scrolle jusqu'au DropdownButtonFormField
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });

  group('ProductFormScreen — validation', () {
    testWidgets('nom vide bloque la soumission', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Créer le produit'));
      await tester.tap(find.text('Créer le produit'));
      await tester.pump();
      expect(find.text('Le nom est obligatoire'), findsOneWidget);
    });

    testWidgets('prix vide bloque la soumission', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex: Eau minérale 1.5L'),
        'Café',
      );
      await tester.ensureVisible(find.text('Créer le produit'));
      await tester.tap(find.text('Créer le produit'));
      await tester.pump();
      expect(find.text('Le prix est obligatoire'), findsOneWidget);
    });

    testWidgets('prix à zéro est invalide', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex: Eau minérale 1.5L'),
        'Café',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex: 500'),
        '0',
      );
      await tester.ensureVisible(find.text('Créer le produit'));
      await tester.tap(find.text('Créer le produit'));
      await tester.pump();
      expect(find.text('Prix invalide'), findsOneWidget);
    });
  });
}
