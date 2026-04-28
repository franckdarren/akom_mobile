import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akom_scanner/features/catalog/domain/product_model.dart';
import 'package:akom_scanner/features/pos/data/pos_providers.dart';

ProductModel _product({
  String id = '1',
  String name = 'Produit Test',
  int price = 1000,
}) =>
    ProductModel(id: id, name: name, price: price);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  group('CartNotifier', () {
    test('starts empty', () {
      expect(container.read(cartProvider), isEmpty);
    });

    test('addItem adds a new product', () {
      container.read(cartProvider.notifier).addItem(_product());
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.productId, '1');
      expect(cart.first.quantity, 1);
    });

    test('addItem increments quantity for existing product', () {
      container.read(cartProvider.notifier).addItem(_product());
      container.read(cartProvider.notifier).addItem(_product());
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 2);
    });

    test('addItem keeps multiple distinct products', () {
      container.read(cartProvider.notifier).addItem(_product(id: 'A'));
      container.read(cartProvider.notifier).addItem(_product(id: 'B'));
      expect(container.read(cartProvider).length, 2);
    });

    test('removeItem removes the product', () {
      container.read(cartProvider.notifier).addItem(_product());
      container.read(cartProvider.notifier).removeItem('1');
      expect(container.read(cartProvider), isEmpty);
    });

    test('removeItem on absent id is a no-op', () {
      container.read(cartProvider.notifier).addItem(_product());
      container.read(cartProvider.notifier).removeItem('inexistant');
      expect(container.read(cartProvider).length, 1);
    });

    test('increment increases quantity', () {
      container.read(cartProvider.notifier).addItem(_product());
      container.read(cartProvider.notifier).increment('1');
      expect(container.read(cartProvider).first.quantity, 2);
    });

    test('decrement decreases quantity', () {
      container.read(cartProvider.notifier).addItem(_product());
      container.read(cartProvider.notifier).addItem(_product());
      container.read(cartProvider.notifier).decrement('1');
      expect(container.read(cartProvider).first.quantity, 1);
    });

    test('decrement to 0 removes the item', () {
      container.read(cartProvider.notifier).addItem(_product());
      container.read(cartProvider.notifier).decrement('1');
      expect(container.read(cartProvider), isEmpty);
    });

    test('clearCart empties everything', () {
      container.read(cartProvider.notifier).addItem(_product(id: 'A'));
      container.read(cartProvider.notifier).addItem(_product(id: 'B'));
      container.read(cartProvider.notifier).clearCart();
      expect(container.read(cartProvider), isEmpty);
    });

    test('cartTotalProvider is sum of subtotals', () {
      container.read(cartProvider.notifier).addItem(_product(id: 'A', price: 1000));
      container.read(cartProvider.notifier).addItem(_product(id: 'A', price: 1000)); // qty=2 → 2000
      container.read(cartProvider.notifier).addItem(_product(id: 'B', price: 500));  // qty=1 → 500
      expect(container.read(cartTotalProvider), 2500);
    });

    test('CartItem.subtotal equals price times quantity', () {
      container.read(cartProvider.notifier).addItem(_product(price: 3000));
      container.read(cartProvider.notifier).addItem(_product(price: 3000));
      expect(container.read(cartProvider).first.subtotal, 6000);
    });
  });
}
