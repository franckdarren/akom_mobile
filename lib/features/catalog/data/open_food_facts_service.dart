import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/product_draft.dart';

final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>(
  (_) => OpenFoodFactsService(),
);

class OpenFoodFactsService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://world.openfoodfacts.org',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Retourne un ProductDraft pré-rempli, ou null si inconnu / erreur.
  Future<ProductDraft?> lookupBarcode(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v0/product/$barcode.json',
      );
      final data = response.data;
      if (data == null || data['status'] != 1) return null;

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final name = (product['product_name_fr'] as String?)?.trim() ??
          (product['product_name'] as String?)?.trim() ??
          '';

      if (name.isEmpty) return null;

      final description = _extractDescription(product);
      final imageUrl = product['image_front_url'] as String? ??
          product['image_url'] as String?;

      return ProductDraft(
        name: name,
        description: description,
        barcode: barcode,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  String _extractDescription(Map<String, dynamic> product) {
    final categories = product['categories_tags'] as List<dynamic>?;
    if (categories == null || categories.isEmpty) return '';
    final tag = categories.first as String;
    // "en:beverages" → "Beverages"
    return tag
        .replaceFirst(RegExp(r'^[a-z]{2}:'), '')
        .replaceAll('-', ' ')
        .trim();
  }
}
