import 'package:freezed_annotation/freezed_annotation.dart';

import 'product_model.dart';

part 'product_draft.freezed.dart';

@freezed
abstract class ProductDraft with _$ProductDraft {
  const ProductDraft._();

  const factory ProductDraft({
    @Default('') String name,
    @Default('') String description,
    @Default(0) int price,
    String? categoryId,
    String? barcode,
    String? imageUrl,
    String? localImagePath,
  }) = _ProductDraft;

  bool get isValid => name.trim().isNotEmpty && price > 0;

  Map<String, dynamic> toApiJson() => {
        'name': name.trim(),
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'price': price,
        if (categoryId != null) 'categoryId': categoryId,
        if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      };
}

extension ProductModelToDraft on ProductModel {
  ProductDraft toDraft() => ProductDraft(
        name: name,
        description: description ?? '',
        price: price,
        categoryId: categoryId,
        barcode: barcode,
        imageUrl: imageUrl,
      );
}
