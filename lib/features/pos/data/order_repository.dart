import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/cart_item_model.dart';
import '../domain/order_result_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(dio: ref.watch(dioClientProvider));
});

class OrderRepository {
  OrderRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<OrderResult> createOrder({
    required List<CartItem> items,
    required int totalAmount,
    required String paymentMethod,
    String? customerName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'items': items
              .map((i) => {
                    'productId': i.productId,
                    'quantity': i.quantity,
                    'unitPrice': i.price,
                  })
              .toList(),
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod,
          if (customerName != null && customerName.isNotEmpty)
            'customerName': customerName,
        },
      );
      return OrderResult.fromJson(response.data!);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de créer la commande.');
    }
  }
}
