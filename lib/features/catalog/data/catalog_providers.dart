import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category_model.dart';
import '../domain/product_draft.dart';
import '../domain/product_model.dart';
import 'category_repository.dart';
import 'product_repository.dart';

// ── Re-export des providers des repositories ──────────────────────────────
export 'category_repository.dart' show categoryRepositoryProvider;
export 'open_food_facts_service.dart' show openFoodFactsServiceProvider;
export 'product_repository.dart' show productRepositoryProvider;

// ── Catégories ────────────────────────────────────────────────────────────

final categoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  return ref.read(categoryRepositoryProvider).getCategories();
});

// ── Produits (liste paginée) ───────────────────────────────────────────────

class ProductsData {
  const ProductsData({
    required this.products,
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<ProductModel> products;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  ProductsData copyWith({
    List<ProductModel>? products,
    String? Function()? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      ProductsData(
        products: products ?? this.products,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class ProductsNotifier extends AsyncNotifier<ProductsData> {
  @override
  Future<ProductsData> build() => _loadFirstPage();

  Future<ProductsData> _loadFirstPage() async {
    final page = await ref.read(productRepositoryProvider).getProducts();
    return ProductsData(
      products: page.products,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await ref
          .read(productRepositoryProvider)
          .getProducts(cursor: current.nextCursor);

      state = AsyncData(ProductsData(
        products: [...current.products, ...page.products],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      ));
    } catch (e, st) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      // ignore: avoid_print
      print('loadMore error: $e\n$st');
    }
  }

  void prepend(ProductModel product) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(products: [product, ...current.products]),
    );
  }

  void replace(ProductModel updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        products: current.products
            .map((p) => p.id == updated.id ? updated : p)
            .toList(),
      ),
    );
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, ProductsData>(
  ProductsNotifier.new,
);

// ── Formulaire produit ────────────────────────────────────────────────────

class ProductFormNotifier extends StateNotifier<ProductDraft> {
  ProductFormNotifier(ProductDraft initial) : super(initial);

  void update(ProductDraft draft) => state = draft;
  void setName(String v) => state = state.copyWith(name: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setPrice(int v) => state = state.copyWith(price: v);
  void setCategoryId(String? v) => state = state.copyWith(categoryId: v);
  void setBarcode(String? v) => state = state.copyWith(barcode: v);
  void setImageUrl(String? v) => state = state.copyWith(imageUrl: v);
  void setLocalImagePath(String? v) =>
      state = state.copyWith(localImagePath: v);
}

final productFormProvider = StateNotifierProvider.autoDispose
    .family<ProductFormNotifier, ProductDraft, ProductDraft>(
  (ref, initial) => ProductFormNotifier(initial),
);
