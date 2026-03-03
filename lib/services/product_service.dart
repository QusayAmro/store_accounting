import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';

class ProductService {
  final SupabaseClient _supabase = SupabaseService().client;

  // Get all products for a store
  Stream<List<Product>> getProducts(String storeId) {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('store_id', storeId)
        .order('name')
        .map((data) => data.map((json) => Product.fromJson(json)).toList());
  }

  // Add new product
  Future<Product> addProduct(Product product) async {
    final response = await _supabase
        .from('products')
        .insert(product.toJson())
        .select()
        .single();

    return Product.fromJson(response);
  }

  // Update product
  Future<Product> updateProduct(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('products')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Product.fromJson(response);
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  // Get single product
  Future<Product?> getProduct(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query, String storeId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('store_id', storeId)
        .ilike('name', '%$query%')
        .order('name');

    return response.map((json) => Product.fromJson(json)).toList();
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts(String storeId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('store_id', storeId)
        .lt('quantity', 10) // You can make this dynamic
        .order('quantity');

    return response.map((json) => Product.fromJson(json)).toList();
  }

  // Update stock quantity
  Future<Product> updateStock(String productId, int newQuantity) async {
    return updateProduct(productId, {'quantity': newQuantity});
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category, String storeId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('store_id', storeId)
        .eq('category', category)
        .order('name');

    return response.map((json) => Product.fromJson(json)).toList();
  }

  // Get all categories
  Future<List<String>> getCategories(String storeId) async {
    final response = await _supabase
        .from('products')
        .select('category')
        .eq('store_id', storeId)
        .order('category');

    // Extract unique categories
    final categories = response.map<String>((json) => json['category'] as String).toSet().toList();
    return categories;
  }
}