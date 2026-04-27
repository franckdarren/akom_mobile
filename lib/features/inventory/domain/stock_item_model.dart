class StockItem {
  StockItem({
    required this.productId,
    required this.productName,
    this.barcode,
    this.imageUrl,
    this.categoryId,
    required this.quantity,
    this.alertThreshold,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        barcode: json['barcode'] as String?,
        imageUrl: json['imageUrl'] as String?,
        categoryId: json['categoryId'] as String?,
        quantity: (json['quantity'] as num).toInt(),
        alertThreshold: (json['alertThreshold'] as num?)?.toInt(),
      );

  final String productId;
  final String productName;
  final String? barcode;
  final String? imageUrl;
  final String? categoryId;
  final int quantity;
  final int? alertThreshold;
}

class InventoryEntry {
  InventoryEntry({
    required this.stock,
    required this.countedQuantity,
    required this.countedAt,
  });

  final StockItem stock;
  final int countedQuantity;
  final DateTime countedAt;

  int get gap => countedQuantity - stock.quantity;

  InventoryEntry copyWith({int? countedQuantity}) => InventoryEntry(
        stock: stock,
        countedQuantity: countedQuantity ?? this.countedQuantity,
        countedAt: DateTime.now(),
      );
}
