class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  final String productId;
  final String name;
  final int price;
  final int quantity;
  final String? imageUrl;

  int get subtotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl,
      );
}
