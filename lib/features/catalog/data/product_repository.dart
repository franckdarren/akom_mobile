import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/product_draft.dart';
import '../domain/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    dio: ref.watch(dioClientProvider),
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(localStorageProvider),
  );
});

typedef ProductsPage = ({
  List<ProductModel> products,
  String? nextCursor,
  bool hasMore,
});

class ProductRepository {
  ProductRepository({
    required Dio dio,
    required AppDatabase db,
    required LocalStorage storage,
  })  : _dio = dio,
        _db = db,
        _storage = storage;

  final Dio _dio;
  final AppDatabase _db;
  final LocalStorage _storage;

  // ── Lecture ──────────────────────────────────────────────────────────────

  Future<ProductsPage> getProducts({String? cursor, int limit = 50}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      final data = response.data!;
      final list = (data['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_parseProduct)
          .toList();
      final nextCursor = data['nextCursor'] as String?;

      await _cacheProducts(list);

      return (products: list, nextCursor: nextCursor, hasMore: nextCursor != null);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is OfflineException || appEx is NetworkException) {
        final cached = await _loadFromCache();
        return (products: cached, nextCursor: null, hasMore: false);
      }
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de charger les produits.');
    }
  }

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products/barcode/$barcode',
      );
      final p = response.data!['product'] as Map<String, dynamic>?;
      if (p == null) return null;
      final product = _parseProduct(p);
      await _db.productDao.upsertProduct(_toCompanion(product));
      return product;
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is OfflineException || appEx is NetworkException) {
        return _db.productDao.getByBarcode(barcode).then(_rowToModel);
      }
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Erreur lors de la recherche par code-barres.');
    }
  }

  // ── Création ─────────────────────────────────────────────────────────────

  Future<ProductModel> createProduct(ProductDraft draft) async {
    final restaurantId = _storage.restaurantId ?? '';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/products',
        data: draft.toApiJson(),
      );
      final product = _parseProduct(
        response.data!['product'] as Map<String, dynamic>,
      );
      await _db.productDao.upsertProduct(_toCompanion(product));
      return product;
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is OfflineException) {
        return _createOffline(draft, restaurantId);
      }
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de créer le produit.');
    }
  }

  // ── Mise à jour ───────────────────────────────────────────────────────────

  Future<ProductModel> updateProduct(String id, ProductDraft draft) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/products/$id',
        data: draft.toApiJson(),
      );
      final product = _parseProduct(
        response.data!['product'] as Map<String, dynamic>,
      );
      await _db.productDao.upsertProduct(_toCompanion(product));
      return product;
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de mettre à jour le produit.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ProductModel _parseProduct(Map<String, dynamic> json) {
    final stockData = json['stock'];
    int stock = 0;
    if (stockData is num) {
      stock = stockData.toInt();
    } else if (stockData is Map) {
      stock = (stockData['quantity'] as num?)?.toInt() ?? 0;
    }
    return ProductModel.fromJson({...json, 'stock': stock});
  }

  Future<ProductModel> _createOffline(
    ProductDraft draft,
    String restaurantId,
  ) async {
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    await _db.pendingProductDao.insert(
      PendingProductsCompanion.insert(
        id: tempId,
        restaurantId: restaurantId,
        name: draft.name.trim(),
        price: draft.price,
        description: Value(
          draft.description.trim().isEmpty ? null : draft.description.trim(),
        ),
        categoryId: Value(draft.categoryId),
        barcode: Value(draft.barcode?.isEmpty == true ? null : draft.barcode),
        imageUrl: Value(draft.imageUrl?.isEmpty == true ? null : draft.imageUrl),
        createdAt: DateTime.now(),
      ),
    );
    final optimistic = ProductModel(
      id: tempId,
      name: draft.name.trim(),
      description: draft.description.trim().isEmpty ? null : draft.description.trim(),
      price: draft.price,
      categoryId: draft.categoryId,
      barcode: draft.barcode,
      imageUrl: draft.imageUrl,
    );
    await _db.productDao.upsertProduct(_toCompanion(optimistic));
    return optimistic;
  }

  Future<void> _cacheProducts(List<ProductModel> products) async {
    await _db.productDao
        .upsertProducts(products.map(_toCompanion).toList());
  }

  Future<List<ProductModel>> _loadFromCache() async {
    final restaurantId = _storage.restaurantId ?? '';
    final rows = await _db.productDao.getAllForRestaurant(restaurantId);
    return rows.map(_rowToModelNonNull).toList();
  }

  LocalProductsCompanion _toCompanion(ProductModel p) =>
      LocalProductsCompanion.insert(
        id: p.id,
        restaurantId: _storage.restaurantId ?? '',
        name: p.name,
        price: p.price,
        description: Value(p.description),
        categoryId: Value(p.categoryId),
        barcode: Value(p.barcode),
        imageUrl: Value(p.imageUrl),
        stock: Value(p.stock),
        updatedAt: DateTime.now(),
      );

  ProductModel? _rowToModel(LocalProduct? row) =>
      row == null ? null : _rowToModelNonNull(row);

  ProductModel _rowToModelNonNull(LocalProduct row) => ProductModel(
        id: row.id,
        name: row.name,
        description: row.description,
        price: row.price,
        categoryId: row.categoryId,
        barcode: row.barcode,
        imageUrl: row.imageUrl,
        stock: row.stock,
      );
}
