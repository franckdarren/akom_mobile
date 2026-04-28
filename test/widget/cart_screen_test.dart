import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:akom_scanner/features/pos/data/pos_providers.dart';
import 'package:akom_scanner/features/pos/domain/cart_item_model.dart';
import 'package:akom_scanner/features/pos/presentation/cart_screen.dart';

// CartNotifier pré-rempli pour les tests
class _PrefilledCartNotifier extends CartNotifier {
  _PrefilledCartNotifier(this._initial);
  final List<CartItem> _initial;

  @override
  List<CartItem> build() => List.of(_initial);
}

CartItem _item({
  String id = 'p1',
  String name = 'Café',
  int price = 500,
  int quantity = 1,
}) =>
    CartItem(productId: id, name: name, price: price, quantity: quantity);

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CartScreen()),
        GoRoute(path: '/pos/payment', builder: (_, _) => const Scaffold(body: Text('Paiement'))),
      ],
    );

Widget _wrap(List<CartItem> items) => ProviderScope(
      overrides: [
        cartProvider.overrideWith(() => _PrefilledCartNotifier(items)),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    );

// Normalise les espaces insécables (fr_FR) en espaces ordinaires
String _n(String s) => s
    .replaceAll(String.fromCharCode(0x00A0), ' ')
    .replaceAll(String.fromCharCode(0x202F), ' ');

void main() {
  group('CartScreen — rendu', () {
    testWidgets('affiche le nom du produit', (tester) async {
      await tester.pumpWidget(_wrap([_item(name: 'Café', price: 500)]));
      await tester.pumpAndSettle();
      expect(find.text('Café'), findsOneWidget);
    });

    testWidgets('affiche le total normalisé', (tester) async {
      await tester.pumpWidget(_wrap([
        _item(id: 'p1', price: 1000, quantity: 2),
        _item(id: 'p2', name: 'Eau', price: 200, quantity: 1),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsOneWidget);
      // total = 1000*2 + 200 = 2 200 FCFA (séparateur insécable fr_FR)
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && _n(w.data ?? '').contains('2 200'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('affiche le bouton Valider la vente', (tester) async {
      await tester.pumpWidget(_wrap([_item()]));
      await tester.pumpAndSettle();
      expect(find.text('Valider la vente'), findsOneWidget);
    });

    testWidgets('affiche les boutons + et - pour chaque article', (tester) async {
      await tester.pumpWidget(_wrap([_item()]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });
  });

  group('CartScreen — interactions', () {
    testWidgets('incrémenter augmente la quantité affichée', (tester) async {
      await tester.pumpWidget(_wrap([_item(quantity: 1)]));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('décrémenter de 2 à 1 met à jour la quantité', (tester) async {
      await tester.pumpWidget(_wrap([_item(quantity: 2)]));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('deux articles distincts sont affichés', (tester) async {
      await tester.pumpWidget(_wrap([
        _item(id: 'p1', name: 'Café', price: 500),
        _item(id: 'p2', name: 'Eau', price: 200),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Eau'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });
}
