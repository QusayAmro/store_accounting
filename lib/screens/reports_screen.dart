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

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  late TabController _tabController;
  late AnimationController _animationController;
  
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
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _loadUserAndReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
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
    // Show month picker dialog
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
      _loadAllReports();
    }
  }

  String _formatCurrency(double amount) {
    return Currency.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final padding = mediaQuery.padding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Reports & Analytics',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: isSmallScreen, // Make scrollable on small screens
          tabs: [
            Tab(
              icon: Icon(Icons.today, size: isSmallScreen ? 18 : 20),
              child: isSmallScreen ? null : const Text('Daily'),
            ),
            Tab(
              icon: Icon(Icons.calendar_month, size: isSmallScreen ? 18 : 20),
              child: isSmallScreen ? null : const Text('Monthly'),
            ),
            Tab(
              icon: Icon(Icons.inventory, size: isSmallScreen ? 18 : 20),
              child: isSmallScreen ? null : const Text('Inventory'),
            ),
            Tab(
              icon: Icon(Icons.star, size: isSmallScreen ? 18 : 20),
              child: isSmallScreen ? null : const Text('Top'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isSmallScreen)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyReport(isSmallScreen),
                  _buildMonthlyReport(isSmallScreen),
                  _buildInventoryReport(isSmallScreen),
                  _buildTopProducts(isSmallScreen),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isSmallScreen ? 40 : 50,
            height: isSmallScreen ? 40 : 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading reports...',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReport(bool isSmallScreen) {
    if (_dailyReport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.today,
              size: isSmallScreen ? 40 : 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No daily data available',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: AppTheme.primaryColor,
                size: isSmallScreen ? 18 : 20,
              ),
              title: Text(
                DateFormat('yyyy-MM-dd').format(_selectedDate),
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
              trailing: Icon(
                Icons.edit,
                size: isSmallScreen ? 18 : 20,
              ),
              onTap: _selectDate,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Summary cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: isSmallScreen ? 8 : 10,
            mainAxisSpacing: isSmallScreen ? 8 : 10,
            childAspectRatio: isSmallScreen ? 1.3 : 1.4,
            children: [
              _buildSummaryCard(
                'Total Sales',
                _formatCurrency((_dailyReport!['total_sales'] as num?)?.toDouble() ?? 0),
                Icons.attach_money,
                Colors.green,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Profit',
                _formatCurrency((_dailyReport!['total_profit'] as num?)?.toDouble() ?? 0),
                Icons.trending_up,
                Colors.blue,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Transactions',
                (_dailyReport!['transactions'] ?? 0).toString(),
                Icons.receipt,
                Colors.orange,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Items Sold',
                (_dailyReport!['total_items'] ?? 0).toString(),
                Icons.shopping_cart,
                Colors.purple,
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport(bool isSmallScreen) {
    if (_monthlyReport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              size: isSmallScreen ? 40 : 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No monthly data available',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: AppTheme.primaryColor,
                size: isSmallScreen ? 18 : 20,
              ),
              title: Text(
                '${DateFormat('MMMM').format(DateTime(2000, _selectedMonth))} $_selectedYear',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
              trailing: Icon(
                Icons.edit,
                size: isSmallScreen ? 18 : 20,
              ),
              onTap: _selectMonth,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Summary cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: isSmallScreen ? 8 : 10,
            mainAxisSpacing: isSmallScreen ? 8 : 10,
            childAspectRatio: isSmallScreen ? 1.3 : 1.4,
            children: [
              _buildSummaryCard(
                'Total Sales',
                _formatCurrency((_monthlyReport!['total_sales'] as num?)?.toDouble() ?? 0),
                Icons.attach_money,
                Colors.green,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Profit',
                _formatCurrency((_monthlyReport!['total_profit'] as num?)?.toDouble() ?? 0),
                Icons.trending_up,
                Colors.blue,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Transactions',
                (_monthlyReport!['transactions'] ?? 0).toString(),
                Icons.receipt,
                Colors.orange,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Avg/Day',
                _formatCurrency((_monthlyReport!['average_per_day'] as num?)?.toDouble() ?? 0),
                Icons.calendar_view_day,
                Colors.purple,
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryReport(bool isSmallScreen) {
    if (_inventoryReport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              size: isSmallScreen ? 40 : 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No inventory data available',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: isSmallScreen ? 8 : 10,
            mainAxisSpacing: isSmallScreen ? 8 : 10,
            childAspectRatio: isSmallScreen ? 1.3 : 1.4,
            children: [
              _buildSummaryCard(
                'Total Products',
                (_inventoryReport!['total_products'] ?? 0).toString(),
                Icons.inventory,
                Colors.blue,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Low Stock',
                (_inventoryReport!['low_stock_count'] ?? 0).toString(),
                Icons.warning,
                Colors.orange,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Out of Stock',
                (_inventoryReport!['out_of_stock_count'] ?? 0).toString(),
                Icons.block,
                Colors.red,
                isSmallScreen,
              ),
              _buildSummaryCard(
                'Inventory Value',
                _formatCurrency((_inventoryReport!['total_inventory_value'] as num?)?.toDouble() ?? 0),
                Icons.attach_money,
                Colors.green,
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(bool isSmallScreen) {
    if (_topProducts == null || _topProducts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: isSmallScreen ? 40 : 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No sales data yet',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      itemCount: _topProducts!.length,
      itemBuilder: (context, index) {
        final product = _topProducts![index];
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                radius: isSmallScreen ? 16 : 18,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              title: Text(
                product['product_name']?.toString() ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Quantity sold: ${product['quantity'] ?? 0}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency((product['total'] as num?)?.toDouble() ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
              ),
              child: Icon(
                icon,
                color: color,
                size: isSmallScreen ? 16 : 18,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}