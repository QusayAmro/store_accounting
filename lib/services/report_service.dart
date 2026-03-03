// lib/services/report_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'supabase_service.dart';

class ReportService {
  final SupabaseClient _supabase = SupabaseService().client;

  // Get daily sales report
  Future<Map<String, dynamic>> getDailyReport(String storeId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sales = await _supabase
        .from('sales')
        .select('''
          *,
          sale_items (*)
        ''')
        .eq('store_id', storeId)
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());

    double totalSales = 0;
    double totalProfit = 0;
    int totalItems = 0;
    Map<String, double> paymentMethods = {};

    for (var sale in sales) {
      totalSales += (sale['total'] as num).toDouble();
      
      // Calculate profit
      final saleItems = sale['sale_items'] as List;
      for (var item in saleItems) {
        totalProfit += ((item['selling_price'] as num) - (item['purchase_price'] as num)) * 
                      (item['quantity'] as num);
        totalItems += item['quantity'] as int;
      }

      // Count payment methods
      final method = sale['payment_method'] as String;
      paymentMethods[method] = (paymentMethods[method] ?? 0) + 1;
    }

    return {
      'date': date,
      'total_sales': totalSales,
      'total_profit': totalProfit,
      'total_items': totalItems,
      'transactions': sales.length,
      'payment_methods': paymentMethods,
    };
  }

  // Get monthly report
  Future<Map<String, dynamic>> getMonthlyReport(String storeId, int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final sales = await _supabase
        .from('sales')
        .select('''
          *,
          sale_items (*)
        ''')
        .eq('store_id', storeId)
        .gte('created_at', startOfMonth.toIso8601String())
        .lt('created_at', endOfMonth.toIso8601String());

    double totalSales = 0;
    double totalProfit = 0;
    Map<String, double> dailySales = {};

    for (var sale in sales) {
      final day = DateTime.parse(sale['created_at']).day.toString();
      final saleTotal = (sale['total'] as num).toDouble();
      
      totalSales += saleTotal;
      dailySales[day] = (dailySales[day] ?? 0) + saleTotal;

      // Calculate profit
      final saleItems = sale['sale_items'] as List;
      for (var item in saleItems) {
        totalProfit += ((item['selling_price'] as num) - (item['purchase_price'] as num)) * 
                      (item['quantity'] as num);
      }
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    return {
      'year': year,
      'month': month,
      'total_sales': totalSales,
      'total_profit': totalProfit,
      'transactions': sales.length,
      'daily_sales': dailySales,
      'average_per_day': sales.isEmpty ? 0 : totalSales / daysInMonth,
    };
  }

  // Get yearly report
  Future<Map<String, dynamic>> getYearlyReport(String storeId, int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final sales = await _supabase
        .from('sales')
        .select('total, created_at')
        .eq('store_id', storeId)
        .gte('created_at', startOfYear.toIso8601String())
        .lt('created_at', endOfYear.toIso8601String());

    double totalSales = 0;
    Map<String, double> monthlySales = {};

    for (var sale in sales) {
      final month = DateFormat('MMM').format(DateTime.parse(sale['created_at']));
      final saleTotal = (sale['total'] as num).toDouble();
      
      totalSales += saleTotal;
      monthlySales[month] = (monthlySales[month] ?? 0) + saleTotal;
    }

    return {
      'year': year,
      'total_sales': totalSales,
      'transactions': sales.length,
      'monthly_sales': monthlySales,
    };
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopProducts(String storeId, {int limit = 10}) async {
    final response = await _supabase
        .from('sale_items')
        .select('''
          product_id,
          product_name,
          quantity,
          subtotal
        ''')
        .eq('store_id', storeId)
        .order('quantity', ascending: false)
        .limit(limit);

    // Aggregate by product
    final Map<String, Map<String, dynamic>> aggregated = {};
    
    for (var item in response) {
      final productId = item['product_id'] as String;
      final productName = item['product_name'] as String;
      final quantity = item['quantity'] as int;
      final subtotal = (item['subtotal'] as num).toDouble();
      
      if (!aggregated.containsKey(productId)) {
        aggregated[productId] = {
          'product_id': productId,
          'product_name': productName,
          'quantity': 0,
          'total': 0.0,
        };
      }
      
      aggregated[productId]!['quantity'] = (aggregated[productId]!['quantity'] as int) + quantity;
      aggregated[productId]!['total'] = (aggregated[productId]!['total'] as double) + subtotal;
    }

    // Convert to list and sort
    var result = aggregated.values.toList();
    result.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    
    return result.take(limit).toList();
  }

  // Get profit report by date range
  Future<Map<String, dynamic>> getProfitReport(
    String storeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sales = await _supabase
        .from('sales')
        .select('''
          *,
          sale_items (*)
        ''')
        .eq('store_id', storeId)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());

    double totalRevenue = 0;
    double totalCost = 0;

    for (var sale in sales) {
      totalRevenue += (sale['total'] as num).toDouble();
      
      final saleItems = sale['sale_items'] as List;
      for (var item in saleItems) {
        totalCost += ((item['purchase_price'] as num) * (item['quantity'] as num));
      }
    }

    double totalProfit = totalRevenue - totalCost;
    double profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

    return {
      'start_date': startDate,
      'end_date': endDate,
      'total_revenue': totalRevenue,
      'total_cost': totalCost,
      'total_profit': totalProfit,
      'profit_margin': profitMargin,
      'transactions': sales.length,
    };
  }

  // Get inventory report
  Future<Map<String, dynamic>> getInventoryReport(String storeId) async {
    final products = await _supabase
        .from('products')
        .select()
        .eq('store_id', storeId);

    int totalProducts = products.length;
    int lowStockCount = 0;
    int outOfStockCount = 0;
    double totalInventoryValue = 0;
    double totalPotentialRevenue = 0;

    for (var product in products) {
      final quantity = product['quantity'] as int;
      final purchasePrice = (product['purchase_price'] as num).toDouble();
      final sellingPrice = (product['selling_price'] as num).toDouble();

      if (quantity == 0) {
        outOfStockCount++;
      } else if (quantity <= (product['low_stock_threshold'] ?? 5)) {
        lowStockCount++;
      }

      totalInventoryValue += quantity * purchasePrice;
      totalPotentialRevenue += quantity * sellingPrice;
    }

    return {
      'total_products': totalProducts,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'total_inventory_value': totalInventoryValue,
      'total_potential_revenue': totalPotentialRevenue,
      'potential_profit': totalPotentialRevenue - totalInventoryValue,
    };
  }
}