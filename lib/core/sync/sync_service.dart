import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../errors/app_exception.dart';
import '../network/dio_client.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    dio: ref.watch(dioClientProvider),
  );
});

class SyncService {
  SyncService({required this.db, required this.dio});

  final AppDatabase db;
  final Dio dio;

  bool _syncing = false;

  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _syncPendingProducts();
      await _syncPendingStock();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncPendingProducts() async {
    final pending = await db.pendingProductDao.getPending();
    for (final product in pending) {
      try {
        await db.pendingProductDao.updateStatus(product.id, 'syncing');
        final response = await dio.post<Map<String, dynamic>>(
          '/products',
          data: {
            'name': product.name,
            if (product.description != null) 'description': product.description,
            'price': product.price,
            if (product.categoryId != null) 'categoryId': product.categoryId,
            if (product.barcode != null) 'barcode': product.barcode,
            if (product.imageUrl != null) 'imageUrl': product.imageUrl,
          },
        );
        await db.pendingProductDao.deleteById(product.id);
        final p = (response.data?['product'] as Map<String, dynamic>?);
        if (p != null) {
          await db.productDao.upsertProduct(
            LocalProductsCompanion.insert(
              id: p['id'] as String,
              restaurantId: product.restaurantId,
              name: p['name'] as String,
              price: (p['price'] as num).toInt(),
              description: Value(p['description'] as String?),
              categoryId: Value(p['categoryId'] as String?),
              barcode: Value(p['barcode'] as String?),
              imageUrl: Value(p['imageUrl'] as String?),
              stock: Value((p['stock'] as num?)?.toInt() ?? 0),
              updatedAt: DateTime.now(),
            ),
          );
        }
        await db.syncLogDao.log(
          type: 'product',
          entityId: product.id,
          success: true,
        );
      } catch (e) {
        final msg = _errorMessage(e);
        await db.pendingProductDao.updateStatus(
          product.id,
          'error',
          errorMessage: msg,
        );
        await db.syncLogDao.log(
          type: 'product',
          entityId: product.id,
          success: false,
          message: msg,
        );
      }
    }
  }

  Future<void> _syncPendingStock() async {
    final pending = await db.stockDao.getPending();
    for (final entry in pending) {
      try {
        await db.stockDao.updateStatus(entry.id, 'syncing');
        await dio.patch<void>(
          '/stock/${entry.productId}',
          data: {'quantity': entry.quantity},
        );
        await db.stockDao.deleteById(entry.id);
        await db.syncLogDao.log(
          type: 'stock',
          entityId: entry.productId,
          success: true,
        );
      } catch (e) {
        final msg = _errorMessage(e);
        await db.stockDao.updateStatus(entry.id, 'error', errorMessage: msg);
        await db.syncLogDao.log(
          type: 'stock',
          entityId: entry.productId,
          success: false,
          message: msg,
        );
      }
    }
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.error is AppException) {
      return (e.error as AppException).message;
    }
    return e.toString();
  }
}
