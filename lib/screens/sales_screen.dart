import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sale_service.dart';
import '../services/auth_service.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../utils/currency.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with TickerProviderStateMixin {
  final SaleService _saleService = SaleService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  List<Sale> _sales = [];
  bool _isLoading = true;
  String _selectedFilter = 'Today';
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;

  final List<String> _filters = ['Today', 'Yesterday', 'This Week', 'This Month', 'Custom'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadUserAndSales();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndSales() async {
    final user = await _authService.getCurrentUserDetails();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
      });
      await _loadSales();
      _animationController.forward();
    }
  }

  Future<void> _loadSales() async {
    if (_currentUser == null) return;

    DateTime? startDate;
    DateTime? endDate;
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'Yesterday':
        startDate = DateTime(now.year, now.month, now.day - 1);
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'Custom':
        // Will be handled separately
        break;
    }

    setState(() => _isLoading = true);
    
    try {
      final sales = await _saleService.getSales(
        _currentUser!.storeId,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (mounted) {
        setState(() {
          _sales = sales;
          _isLoading = false;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      print('Error in _loadSales: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Error loading sales');
      }
    }
  }

  Future<void> _selectCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadSales();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
          'Sales History',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: isSmallScreen ? 18 : 20),
            onPressed: _loadSales,
            tooltip: 'Refresh',
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, size: isSmallScreen ? 18 : 20),
            onPressed: _showFilterOptions,
            tooltip: 'Filter',
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isSmallScreen)
            : Column(
                children: [
                  _buildFilterBar(isSmallScreen),
                  if (_selectedFilter == 'Custom') _buildCustomDateBar(isSmallScreen),
                  if (_sales.isNotEmpty) _buildSummaryCard(isSmallScreen),
                  Expanded(
                    child: _sales.isEmpty
                        ? _buildEmptyState(isSmallScreen)
                        : _buildSalesList(isSmallScreen),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-sale'),
        icon: Icon(Icons.add, size: isSmallScreen ? 16 : 18),
        label: Text(
          'New Sale',
          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
        ),
        backgroundColor: AppTheme.accentColor,
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
            'Loading sales...',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) async {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      if (filter == 'Custom') {
                        await _selectCustomDate();
                      } else {
                        await _loadSales();
                      }
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10 : 12,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: isSelected ? 2 : 0,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateBar(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: _selectCustomDate,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: isSmallScreen ? 16 : 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 9 : 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isSmallScreen) {
    final totalSales = _sales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalProfit = _sales.fold(0.0, (sum, sale) => sum + sale.profit);
    final avgSale = _sales.isEmpty ? 0.0 : (totalSales / _sales.length).toDouble();

    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailedSummary(isSmallScreen),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedFilter,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 9 : 10,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Transactions',
                      _sales.length.toString(),
                      Icons.receipt,
                      Colors.white,
                      isSmallScreen,
                    ),
                    _buildSummaryItem(
                      'Total Sales',
                      _formatCurrency(totalSales),
                      Icons.attach_money,
                      Colors.white,
                      isSmallScreen,
                    ),
                    _buildSummaryItem(
                      'Profit',
                      _formatCurrency(totalProfit),
                      Icons.trending_up,
                      Colors.white,
                      isSmallScreen,
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Average Sale',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 10 : 11,
                        ),
                      ),
                      Text(
                        _formatCurrency(avgSale),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color, bool isSmallScreen) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: isSmallScreen ? 14 : 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 8 : 9,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: isSmallScreen ? 80 : 100,
                    height: isSmallScreen ? 80 : 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: isSmallScreen ? 35 : 45,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'No sales found',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Start by creating your first sale',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create-sale'),
              icon: Icon(Icons.add, size: isSmallScreen ? 14 : 16),
              label: Text(
                'Create New Sale',
                style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      itemCount: _sales.length,
      itemBuilder: (context, index) {
        final sale = _sales[index];
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildSaleCard(sale, index, isSmallScreen),
        );
      },
    );
  }

  Widget _buildSaleCard(Sale sale, int index, bool isSmallScreen) {
    final paymentMethodColor = _getPaymentMethodColor(sale.paymentMethod);
    final profit = sale.profit;
    final profitPercentage = sale.total > 0 ? (profit / sale.total) * 100 : 0;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
        child: InkWell(
          onTap: () => _showSaleDetails(sale, isSmallScreen),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Invoice icon with gradient
                    Container(
                      width: isSmallScreen ? 45 : 50,
                      height: isSmallScreen ? 45 : 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            paymentMethodColor.withOpacity(0.2),
                            paymentMethodColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt,
                              size: isSmallScreen ? 16 : 18,
                              color: paymentMethodColor,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${sale.invoiceNumber.split('-').last}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 9,
                                fontWeight: FontWeight.bold,
                                color: paymentMethodColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sale details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sale.customerName ?? 'Guest',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 4 : 6,
                                  vertical: isSmallScreen ? 2 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: paymentMethodColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getPaymentMethodIcon(sale.paymentMethod),
                                      size: isSmallScreen ? 8 : 10,
                                      color: paymentMethodColor,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      sale.paymentMethod,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 7 : 8,
                                        color: paymentMethodColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Date and time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: isSmallScreen ? 8 : 10,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(sale.createdAt),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 7 : 8,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Items count
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                size: isSmallScreen ? 8 : 10,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${sale.items.length} items',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 7 : 8,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: isSmallScreen ? 12 : 16),
                
                // Financial summary
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _formatCurrency(sale.total),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Profit',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _formatCurrency(profit),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              fontWeight: FontWeight.bold,
                              color: profit >= 0 ? Colors.green.shade700 : Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Margin',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 4 : 6,
                              vertical: isSmallScreen ? 1 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: profitPercentage >= 20
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${profitPercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 9,
                                fontWeight: FontWeight.bold,
                                color: profitPercentage >= 20
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              ListTile(
                leading: Icon(Icons.payment, color: AppTheme.primaryColor, size: isSmallScreen ? 18 : 20),
                title: Text(
                  'Filter by Payment Method',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                trailing: Icon(Icons.chevron_right, size: isSmallScreen ? 18 : 20),
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentMethodFilter(isSmallScreen);
                },
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 8,
                ),
              ),
              ListTile(
                leading: Icon(Icons.attach_money, color: AppTheme.successColor, size: isSmallScreen ? 18 : 20),
                title: Text(
                  'Filter by Amount',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                trailing: Icon(Icons.chevron_right, size: isSmallScreen ? 18 : 20),
                onTap: () {
                  Navigator.pop(context);
                  // Implement amount filter
                },
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 8,
                ),
              ),
              ListTile(
                leading: Icon(Icons.person, color: AppTheme.accentColor, size: isSmallScreen ? 18 : 20),
                title: Text(
                  'Filter by Customer',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                trailing: Icon(Icons.chevron_right, size: isSmallScreen ? 18 : 20),
                onTap: () {
                  Navigator.pop(context);
                  // Implement customer filter
                },
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodFilter(bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payment Method',
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.money, color: Colors.green, size: isSmallScreen ? 18 : 20),
              title: Text(
                'Cash',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
              onTap: () {
                Navigator.pop(context);
                // Apply cash filter
              },
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 8,
              ),
            ),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blue, size: isSmallScreen ? 18 : 20),
              title: Text(
                'Card',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
              onTap: () {
                Navigator.pop(context);
                // Apply card filter
              },
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 8,
              ),
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz, color: Colors.purple, size: isSmallScreen ? 18 : 20),
              title: Text(
                'Transfer',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
              onTap: () {
                Navigator.pop(context);
                // Apply transfer filter
              },
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 8,
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        buttonPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 4 : 8,
        ),
      ),
    );
  }

  void _showDetailedSummary(bool isSmallScreen) {
    final totalSales = _sales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalProfit = _sales.fold(0.0, (sum, sale) => sum + sale.profit);
    final avgSale = _sales.isEmpty ? 0.0 : (totalSales / _sales.length).toDouble();
    
    Map<String, double> paymentMethodTotals = {};
    for (var sale in _sales) {
      paymentMethodTotals[sale.paymentMethod] = 
          (paymentMethodTotals[sale.paymentMethod] ?? 0) + sale.total;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Detailed Summary',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            // Stats
            _buildSummaryDetailRow('Total Transactions', _sales.length.toString(), isSmallScreen),
            _buildSummaryDetailRow('Total Sales', _formatCurrency(totalSales), isSmallScreen),
            _buildSummaryDetailRow('Total Profit', _formatCurrency(totalProfit), isSmallScreen),
            _buildSummaryDetailRow('Average Sale', _formatCurrency(avgSale), isSmallScreen),
            _buildSummaryDetailRow('Profit Margin', 
                '${totalSales > 0 ? ((totalProfit / totalSales) * 100).toStringAsFixed(1) : '0'}%', 
                isSmallScreen),
            
            Divider(height: isSmallScreen ? 20 : 24),
            
            // Payment method breakdown
            Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            ...paymentMethodTotals.entries.map((entry) {
              final percentage = (entry.value / totalSales) * 100;
              return Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
                child: Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 6 : 8,
                      height: isSmallScreen ? 6 : 8,
                      decoration: BoxDecoration(
                        color: _getPaymentMethodColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                      ),
                    ),
                    Text(
                      _formatCurrency(entry.value),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4 : 6,
                        vertical: isSmallScreen ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 9,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            SizedBox(height: isSmallScreen ? 12 : 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryDetailRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 11 : 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'transfer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.payment;
    }
  }

  Future<void> _showSaleDetails(Sale sale, bool isSmallScreen) async {
    final fullSale = await _saleService.getSaleDetails(sale.id!);
    if (!mounted || fullSale == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice ${fullSale.invoiceNumber}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(fullSale.createdAt),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPaymentMethodColor(fullSale.paymentMethod).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getPaymentMethodIcon(fullSale.paymentMethod),
                            size: isSmallScreen ? 10 : 12,
                            color: _getPaymentMethodColor(fullSale.paymentMethod),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            fullSale.paymentMethod,
                            style: TextStyle(
                              color: _getPaymentMethodColor(fullSale.paymentMethod),
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 8 : 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (fullSale.customerName != null && fullSale.customerName!.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 8 : 10),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: AppTheme.primaryColor, size: isSmallScreen ? 16 : 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                fullSale.customerName!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                Divider(height: isSmallScreen ? 20 : 24),
                
                // Items
                Text(
                  'Items',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: fullSale.items.length,
                    itemBuilder: (context, index) {
                      final item = fullSale.items[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: isSmallScreen ? 30 : 35,
                              height: isSmallScreen ? 30 : 35,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}x',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: isSmallScreen ? 9 : 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@ ${_formatCurrency(item.sellingPrice)} each',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 8 : 9,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCurrency(item.subtotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 10 : 11,
                                  ),
                                ),
                                if (item.discount > 0)
                                  Text(
                                    '-${_formatCurrency(item.discount)}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 7 : 8,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                Divider(height: isSmallScreen ? 12 : 16),
                
                // Totals
                Container(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
                  child: Column(
                    children: [
                      _buildTotalRow('Subtotal', fullSale.subtotal, isSmallScreen),
                      if (fullSale.tax > 0)
                        _buildTotalRow('Tax (15%)', fullSale.tax, isSmallScreen),
                      if (fullSale.discount > 0)
                        _buildTotalRow('Discount', -fullSale.discount, isSmallScreen, isNegative: true),
                      Divider(height: isSmallScreen ? 10 : 12),
                      _buildTotalRow('Total', fullSale.total, isSmallScreen, isBold: true),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      _buildTotalRow('Profit', fullSale.profit, isSmallScreen,
                          color: fullSale.profit >= 0 ? Colors.green : Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isSmallScreen,
      {bool isBold = false, bool isNegative = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? (isBold ? 12 : 10) : (isBold ? 14 : 12),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}${_formatCurrency(amount.abs())}',
            style: TextStyle(
              fontSize: isSmallScreen ? (isBold ? 14 : 12) : (isBold ? 16 : 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isBold ? Colors.green.shade700 : Colors.black87),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}