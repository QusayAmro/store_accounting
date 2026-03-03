// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../utils/currency.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin { // Changed from SingleTickerProviderStateMixin
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  late TabController _tabController;
  late AnimationController _animationController; // Add this
  
  Map<String, dynamic>? _dailyReport;
  Map<String, dynamic>? _monthlyReport;
  Map<String, dynamic>? _inventoryReport;
  List<Map<String, dynamic>>? _topProducts;

  final List<String> _reportTypes = ['Daily', 'Monthly', 'Inventory', 'Products'];
  
  DateTime _selectedDate = DateTime.now();
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize animation controller with TickerProviderStateMixin
    _animationController = AnimationController(
      vsync: this, // Now this works with TickerProviderStateMixin
      duration: const Duration(milliseconds: 800),
    );
    
    _loadUserAndReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose(); // Don't forget to dispose
    super.dispose();
  }

  Future<void> _loadUserAndReports() async {
    final user = await _authService.getCurrentUserDetails();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      await _loadAllReports();
      _animationController.forward();
    }
  }

  Future<void> _loadAllReports() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Use try-catch for each report to isolate errors
      Map<String, dynamic>? daily;
      Map<String, dynamic>? monthly;
      Map<String, dynamic>? inventory;
      List<Map<String, dynamic>>? topProducts;

      try {
        daily = await _reportService.getDailyReport(
          _currentUser!.storeId,
          _selectedDate,
        );
      } catch (e) {
        print('Error loading daily report: $e');
      }
      
      try {
        monthly = await _reportService.getMonthlyReport(
          _currentUser!.storeId,
          _selectedYear,
          _selectedMonth,
        );
      } catch (e) {
        print('Error loading monthly report: $e');
      }
      
      try {
        inventory = await _reportService.getInventoryReport(
          _currentUser!.storeId,
        );
      } catch (e) {
        print('Error loading inventory report: $e');
      }
      
      try {
        topProducts = await _reportService.getTopProducts(
          _currentUser!.storeId,
          limit: 10,
        );
      } catch (e) {
        print('Error loading top products: $e');
      }

      if (mounted) {
        setState(() {
          _dailyReport = daily;
          _monthlyReport = monthly;
          _inventoryReport = inventory;
          _topProducts = topProducts ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR LOADING REPORTS: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAllReports();
    }
  }

  Future<void> _selectMonth() async {
    // Simple implementation without dialog for now
    setState(() {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
    });
    _loadAllReports();
  }

  String _formatCurrency(double amount) {
    return Currency.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Daily'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Monthly'),
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.star), text: 'Top Products'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyReport(),
                _buildMonthlyReport(),
                _buildInventoryReport(),
                _buildTopProducts(),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading reports...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReport() {
    if (_dailyReport == null) {
      return const Center(
        child: Text('No daily data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              trailing: const Icon(Icons.edit),
              onTap: _selectDate,
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSummaryCard(
                'Total Sales',
                _formatCurrency(_dailyReport!['total_sales'] ?? 0),
                Icons.attach_money,
                Colors.green,
              ),
              _buildSummaryCard(
                'Profit',
                _formatCurrency(_dailyReport!['total_profit'] ?? 0),
                Icons.trending_up,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Transactions',
                (_dailyReport!['transactions'] ?? 0).toString(),
                Icons.receipt,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Items Sold',
                (_dailyReport!['total_items'] ?? 0).toString(),
                Icons.shopping_cart,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    if (_monthlyReport == null) {
      return const Center(
        child: Text('No monthly data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text('${DateFormat('MMMM').format(DateTime(2000, _selectedMonth))} $_selectedYear'),
              trailing: const Icon(Icons.edit),
              onTap: _selectMonth,
            ),
          ),
          const SizedBox(height: 16),

          // Summary cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSummaryCard(
                'Total Sales',
                _formatCurrency(_monthlyReport!['total_sales'] ?? 0),
                Icons.attach_money,
                Colors.green,
              ),
              _buildSummaryCard(
                'Profit',
                _formatCurrency(_monthlyReport!['total_profit'] ?? 0),
                Icons.trending_up,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Transactions',
                (_monthlyReport!['transactions'] ?? 0).toString(),
                Icons.receipt,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Avg/Day',
                _formatCurrency(_monthlyReport!['average_per_day'] ?? 0),
                Icons.calendar_view_day,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryReport() {
    if (_inventoryReport == null) {
      return const Center(
        child: Text('No inventory data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSummaryCard(
                'Total Products',
                (_inventoryReport!['total_products'] ?? 0).toString(),
                Icons.inventory,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Low Stock',
                (_inventoryReport!['low_stock_count'] ?? 0).toString(),
                Icons.warning,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Out of Stock',
                (_inventoryReport!['out_of_stock_count'] ?? 0).toString(),
                Icons.block,
                Colors.red,
              ),
              _buildSummaryCard(
                'Inventory Value',
                _formatCurrency(_inventoryReport!['total_inventory_value'] ?? 0),
                Icons.attach_money,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    if (_topProducts == null || _topProducts!.isEmpty) {
      return const Center(
        child: Text('No sales data yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topProducts!.length,
      itemBuilder: (context, index) {
        final product = _topProducts![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text('${index + 1}'),
            ),
            title: Text(
              product['product_name']?.toString() ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Quantity sold: ${product['quantity'] ?? 0}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency((product['total'] as num?)?.toDouble() ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}