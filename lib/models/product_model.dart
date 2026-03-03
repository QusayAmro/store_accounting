class Product {
  final String? id;
  final String barcode;
  final String name;
  final String? description;
  final double purchasePrice;
  final double sellingPrice;
  final int quantity;
  final int lowStockThreshold;
  final String category;
  final String storeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    this.description,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockThreshold,
    required this.category,
    required this.storeId,
    this.createdAt,
    this.updatedAt,
  });

  double get profit => (sellingPrice - purchasePrice) * quantity;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 5,
      category: json['category'] ?? 'General',
      storeId: json['store_id'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'description': description,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      'category': category,
      'store_id': storeId,
    };
  }

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? description,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    int? lowStockThreshold,
    String? category,
    String? storeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}