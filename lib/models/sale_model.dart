// lib/models/sale_model.dart
class Sale {
  final String? id;
  final String invoiceNumber;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod;
  final String? customerName;
  final String storeId;
  final String userId;
  final DateTime createdAt;
  final List<SaleItem> items;

  Sale({
    this.id,
    required this.invoiceNumber,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.customerName,
    required this.storeId,
    required this.userId,
    required this.createdAt,
    required this.items,
  });

  double get profit {
    return items.fold(0, (sum, item) => 
        sum + ((item.sellingPrice - item.purchasePrice) * item.quantity));
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    var itemsJson = json['sale_items'] as List? ?? [];
    List<SaleItem> items = itemsJson.map((i) => SaleItem.fromJson(i)).toList();

    return Sale(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      customerName: json['customer_name'],
      storeId: json['store_id'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'customer_name': customerName,
      'store_id': storeId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'sale_items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class SaleItem {
  final String? id;
  final String productId;
  final String productName;
  int quantity;
  final double purchasePrice;
  final double sellingPrice;
  double discount;
  double subtotal;

  SaleItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.discount,
    required this.subtotal,
  });

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
    subtotal = quantity * sellingPrice;
  }

  void updateDiscount(double newDiscount) {
    discount = newDiscount;
  }

  void recalculateSubtotal() {
    subtotal = quantity * sellingPrice;
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'discount': discount,
      'subtotal': subtotal,
    };
  }
}