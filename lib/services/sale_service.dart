// lib/services/sale_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';
import 'supabase_service.dart';

class SaleService {
  final SupabaseClient _supabase = SupabaseService().client;

  // Create new sale
Future<Map<String, dynamic>> createSale(Sale sale) async {
  try {
    print('Creating sale: ${sale.invoiceNumber}');
    
    // First insert the sale
    final saleResponse = await _supabase
        .from('sales')
        .insert({
          'invoice_number': sale.invoiceNumber,
          'subtotal': sale.subtotal,
          'tax': sale.tax,
          'discount': sale.discount,
          'total': sale.total,
          'payment_method': sale.paymentMethod,
          'customer_name': sale.customerName,
          'store_id': sale.storeId,
          'user_id': sale.userId,
          'created_at': sale.createdAt.toIso8601String(),
        })
        .select()
        .single();

    print('Sale created with ID: ${saleResponse['id']}');
    final saleId = saleResponse['id'];

    // Insert sale items and update stock
    for (var item in sale.items) {
      print('Inserting sale item: ${item.productName}');
      
      // IMPORTANT: Include store_id here!
      await _supabase.from('sale_items').insert({
        'sale_id': saleId,
        'product_id': item.productId,
        'product_name': item.productName,
        'quantity': item.quantity,
        'purchase_price': item.purchasePrice,
        'selling_price': item.sellingPrice,
        'discount': item.discount,
        'subtotal': item.subtotal,
        'store_id': sale.storeId, // THIS IS CRITICAL - DON'T FORGET
      });

      // Update product quantity
      final currentProduct = await _supabase
          .from('products')
          .select('quantity')
          .eq('id', item.productId)
          .single();
      
      final currentQuantity = currentProduct['quantity'] as int;
      final newQuantity = currentQuantity - item.quantity;
      
      await _supabase
          .from('products')
          .update({'quantity': newQuantity})
          .eq('id', item.productId);
      
      print('Updated product ${item.productId} quantity to $newQuantity');
    }

    return {'sale_id': saleId};
  } catch (e) {
    print('Error creating sale: $e');
    rethrow;
  }
}

  // SIMPLE METHOD: Get all sales and filter in Dart
  Future<List<Sale>> getSales(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // First, get ALL sales for this store
      final response = await _supabase
          .from('sales')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      // Convert to Sale objects
      List<Sale> allSales = [];
      for (var json in response) {
        try {
          allSales.add(Sale.fromJson({
            ...json,
            'sale_items': [],
          }));
        } catch (e) {
          print('Error parsing sale: $e');
        }
      }

      // Apply date filters manually in Dart
      List<Sale> filteredSales = List.from(allSales);
      
      if (startDate != null) {
        filteredSales = filteredSales.where((sale) {
          return sale.createdAt.isAfter(startDate) || 
                 sale.createdAt.isAtSameMomentAs(startDate);
        }).toList();
      }
      
      if (endDate != null) {
        filteredSales = filteredSales.where((sale) {
          return sale.createdAt.isBefore(endDate);
        }).toList();
      }

      return filteredSales;
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  // Get sale details with items
  Future<Sale?> getSaleDetails(String saleId) async {
    try {
      final response = await _supabase
          .from('sales')
          .select()
          .eq('id', saleId)
          .single();
      
      // Get sale items separately
      final itemsResponse = await _supabase
          .from('sale_items')
          .select()
          .eq('sale_id', saleId);
      
      // Combine sale with items
      final saleJson = Map<String, dynamic>.from(response);
      saleJson['sale_items'] = itemsResponse;
      
      return Sale.fromJson(saleJson);
    } catch (e) {
      print('Error getting sale details: $e');
      return null;
    }
  }

  // Generate invoice number
  Future<String> generateInvoiceNumber(String storeId) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      
      // Get all sales
      final response = await _supabase
          .from('sales')
          .select('created_at')
          .eq('store_id', storeId);

      // Count today's sales manually
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      int saleCount = 0;
      for (var sale in response) {
        final createdAt = DateTime.parse(sale['created_at']);
        if (createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay)) {
          saleCount++;
        }
      }
      
      return 'INV-$dateStr-${(saleCount + 1).toString().padLeft(4, '0')}';
    } catch (e) {
      print('Error generating invoice number: $e');
      return 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Get today's sales total
  Future<double> getTodaySalesTotal(String storeId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('sales')
          .select('total, created_at')
          .eq('store_id', storeId);

      double total = 0;
      for (var sale in response) {
        final createdAt = DateTime.parse(sale['created_at']);
        if (createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay)) {
          total += (sale['total'] as num).toDouble();
        }
      }
      return total;
    } catch (e) {
      print('Error getting today sales total: $e');
      return 0.0;
    }
  }

  // Get sales statistics
  Future<Map<String, dynamic>> getSalesStats(String storeId) async {
    try {
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);
      final startOfYear = DateTime(today.year, 1, 1);

      final response = await _supabase
          .from('sales')
          .select('total, created_at')
          .eq('store_id', storeId);

      double todaySales = 0;
      double monthSales = 0;
      double yearSales = 0;

      for (var sale in response) {
        final amount = (sale['total'] as num).toDouble();
        final createdAt = DateTime.parse(sale['created_at']);
        
        // Check if in current month
        if (createdAt.isAfter(startOfMonth) || 
            createdAt.isAtSameMomentAs(startOfMonth)) {
          monthSales += amount;
        }
        
        // Check if in current year
        if (createdAt.isAfter(startOfYear) || 
            createdAt.isAtSameMomentAs(startOfYear)) {
          yearSales += amount;
        }
        
        // Check if today
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        if (createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay)) {
          todaySales += amount;
        }
      }

      return {
        'today_sales': todaySales,
        'month_sales': monthSales,
        'year_sales': yearSales,
        'total_transactions': response.length,
      };
    } catch (e) {
      print('Error getting sales stats: $e');
      return {
        'today_sales': 0.0,
        'month_sales': 0.0,
        'year_sales': 0.0,
        'total_transactions': 0,
      };
    }
  }

  // Stream version (if needed)
  Stream<List<Sale>> getSalesStream(String storeId) {
    try {
      return _supabase
          .from('sales')
          .stream(primaryKey: ['id'])
          .map((data) {
            // Filter by storeId manually
            final filtered = data.where((sale) => sale['store_id'] == storeId).toList();
            
            // Convert to Sale objects
            return filtered.map((json) {
              try {
                return Sale.fromJson({
                  ...json,
                  'sale_items': [],
                });
              } catch (e) {
                print('Error parsing sale in stream: $e');
                return null;
              }
            }).whereType<Sale>().toList();
          });
    } catch (e) {
      print('Error creating sales stream: $e');
      return Stream.value([]);
    }
  }
}