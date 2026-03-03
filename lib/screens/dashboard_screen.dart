// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  UserModel? _currentUser;
  int _unreadNotifications = 0;
  double _todaySales = 0;
  int _lowStockCount = 0;
  int _totalProducts = 0;  // Added this variable
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUserDetails();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
      });
      await _loadDashboardData();
      await _loadNotificationCount();
    }
  }

  Future<void> _loadDashboardData() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Get today's sales
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final sales = await _saleService.getSales(
        _currentUser!.storeId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      double total = 0;
      for (var sale in sales) {
        total += sale.total;
      }

      // Get all products to count total and low stock
      final allProducts = await _productService.getProducts(_currentUser!.storeId).first;
      
      // Count low stock products
      int lowStock = 0;
      for (var product in allProducts) {
        if (product.quantity <= product.lowStockThreshold) {
          lowStock++;
        }
      }

      if (mounted) {
        setState(() {
          _todaySales = total;
          _lowStockCount = lowStock;
          _totalProducts = allProducts.length;  // Set total products count
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    if (_currentUser == null) return;

    try {
      final count = await _notificationService.getUnreadCount(_currentUser!.storeId);
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser?.storeName ?? 'Dashboard'),
        actions: [
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications').then((_) {
                    _loadNotificationCount();
                  });
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome back, ${_currentUser?.fullName ?? 'Storekeeper'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s what\'s happening in your store today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid - Now all cards are clickable
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12, // Reduced from 16
                      mainAxisSpacing: 12, // Reduced from 16
                      childAspectRatio:
                          1.4, // Added to control card proportions (wider than tall)
                      children: [
                        _buildStatCard(
                          'Today\'s Sales',
                          '\$${_todaySales.toStringAsFixed(2)}',
                          Icons.today,
                          Colors.blue,
                          () => Navigator.pushNamed(context, '/sales'),
                        ),
                        _buildStatCard(
                          'Low Stock',
                          _lowStockCount.toString(),
                          Icons.warning,
                          Colors.orange,
                          () => Navigator.pushNamed(context, '/products'),
                        ),
                        _buildStatCard(
                          'Products',
                          _totalProducts.toString(),
                          Icons.inventory,
                          Colors.green,
                          () => Navigator.pushNamed(context, '/products'),
                        ),
                        _buildStatCard(
                          'Profit',
                          '\$0.00',
                          Icons.trending_up,
                          Colors.purple,
                          () => Navigator.pushNamed(context, '/reports'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'New Sale',
                            Icons.shopping_cart,
                            Colors.green,
                            () => Navigator.pushNamed(context, '/create-sale'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Add Product',
                            Icons.add_box,
                            Colors.blue,
                            () => Navigator.pushNamed(context, '/add-product'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'View Products',
                            Icons.inventory,
                            Colors.orange,
                            () => Navigator.pushNamed(context, '/products'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Reports',
                            Icons.bar_chart,
                            Colors.purple,
                            () => Navigator.pushNamed(context, '/reports'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Calculate total profit (you can enhance this later)
  double _calculateProfit() {
    // For now, return a placeholder or calculate from sales
    return _todaySales * 0.2; // Example: 20% profit margin
  }

  // Updated stat card with onTap parameter
   Widget _buildStatCard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced from 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // Reduced from 8
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6), // Reduced from 8
                    ),
                    child:
                        Icon(icon, color: color, size: 16), // Reduced from 20
                  ),
                  // Optional small indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced from 12
              // Value
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18, // Reduced from 20
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2), // Reduced from 4
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 11, // Reduced from 12
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action button widget
  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}