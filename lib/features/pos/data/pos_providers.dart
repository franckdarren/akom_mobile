import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cart_item_model.dart';
import '../../../features/catalog/domain/product_model.dart';

export 'order_repository.dart' show orderRepositoryProvider;

// ── Panier ────────────────────────────────────────────────────────────────

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(ProductModel product) {
    final idx = state.indexWhere((i) => i.productId == product.id);
    if (idx == -1) {
      state = [
        ...state,
        CartItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          imageUrl: product.imageUrl,
        ),
      ];
    } else {
      _setQuantity(product.id, state[idx].quantity + 1);
    }
  }

  void removeItem(String productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  void increment(String productId) {
    final idx = state.indexWhere((i) => i.productId == productId);
    if (idx == -1) return;
    _setQuantity(productId, state[idx].quantity + 1);
  }

  void decrement(String productId) {
    final idx = state.indexWhere((i) => i.productId == productId);
    if (idx == -1) return;
    final newQty = state[idx].quantity - 1;
    if (newQty <= 0) {
      removeItem(productId);
    } else {
      _setQuantity(productId, newQty);
    }
  }

  void clearCart() => state = [];

  int get total => state.fold(0, (sum, i) => sum + i.subtotal);

  void _setQuantity(String productId, int qty) {
    state = state
        .map((i) => i.productId == productId ? i.copyWith(quantity: qty) : i)
        .toList();
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartTotalProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.notifier).total;
});
