import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/stock_item_model.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(dio: ref.watch(dioClientProvider));
});

class InventoryRepository {
  InventoryRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<StockItem>> getStock() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/stock');
      final items = (response.data!['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(StockItem.fromJson)
          .toList();
      return items;
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de charger le stock.');
    }
  }

  Future<void> updateStock(
    String productId,
    int quantity, {
    String? note,
  }) async {
    try {
      final body = <String, dynamic>{'quantity': quantity};
      if (note != null) body['note'] = note;
      await _dio.patch<void>('/stock/$productId', data: body);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de mettre à jour le stock.');
    }
  }
}
