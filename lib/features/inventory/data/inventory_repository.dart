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

  Future<InventoryCloseResult> closeInventory({
    String? label,
    required List<InventoryEntry> entries,
  }) async {
    try {
      final body = <String, dynamic>{
        if (label != null && label.isNotEmpty) 'label': label,
        'entries': entries
            .map((e) => {
                  'productId': e.stock.productId,
                  'countedQty': e.countedQuantity,
                })
            .toList(),
      };
      final response =
          await _dio.post<Map<String, dynamic>>('/inventory', data: body);
      return InventoryCloseResult.fromJson(response.data!);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de clôturer l\'inventaire.');
    }
  }
}
