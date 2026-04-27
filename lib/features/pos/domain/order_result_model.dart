class OrderResult {
  OrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) => OrderResult(
        orderId: json['orderId'] as String,
        orderNumber: json['orderNumber'] as String,
        totalAmount: (json['totalAmount'] as num).toInt(),
      );

  final String orderId;
  final String orderNumber;
  final int totalAmount;
}
