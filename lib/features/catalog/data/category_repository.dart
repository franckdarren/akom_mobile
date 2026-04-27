import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/category_model.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(dio: ref.watch(dioClientProvider));
});

class CategoryRepository {
  CategoryRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/categories');
      final list = response.data!['categories'] as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw const NetworkException('Impossible de charger les catégories.');
    }
  }
}
