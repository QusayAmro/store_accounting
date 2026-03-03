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
  int _totalProducts = 0;
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
          _totalProducts = allProducts.length;
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
            behavior: SnackBarBehavior.floating,
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
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final isMediumScreen = mediaQuery.size.width < 600;
    final padding = mediaQuery.padding;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser?.storeName ?? 'Dashboard',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          // Notifications
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications').then((_) {
                    _loadNotificationCount();
                  });
                },
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                constraints: const BoxConstraints(),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: isSmallScreen ? 4 : 8,
                  top: isSmallScreen ? 4 : 8,
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
                      _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
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
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      Text(
                        'Welcome back, ${_currentUser?.fullName?.split(' ').first ?? 'Storekeeper'}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 18 : 22,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s what\'s happening in your store today',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),

                      // Stats Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isSmallScreen ? 2 : 2,
                          crossAxisSpacing: isSmallScreen ? 8 : 12,
                          mainAxisSpacing: isSmallScreen ? 8 : 12,
                          childAspectRatio: isSmallScreen ? 1.3 : 1.4,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return _buildStatCard(
                                'Today\'s Sales',
                                '\$${_todaySales.toStringAsFixed(2)}',
                                Icons.today,
                                Colors.blue,
                                () => Navigator.pushNamed(context, '/sales'),
                                isSmallScreen,
                              );
                            case 1:
                              return _buildStatCard(
                                'Low Stock',
                                _lowStockCount.toString(),
                                Icons.warning,
                                Colors.orange,
                                () => Navigator.pushNamed(context, '/products'),
                                isSmallScreen,
                              );
                            case 2:
                              return _buildStatCard(
                                'Products',
                                _totalProducts.toString(),
                                Icons.inventory,
                                Colors.green,
                                () => Navigator.pushNamed(context, '/products'),
                                isSmallScreen,
                              );
                            case 3:
                              return _buildStatCard(
                                'Profit',
                                '\$0.00',
                                Icons.trending_up,
                                Colors.purple,
                                () => Navigator.pushNamed(context, '/reports'),
                                isSmallScreen,
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 16 : 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Quick Actions Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: isSmallScreen ? 8 : 12,
                        mainAxisSpacing: isSmallScreen ? 8 : 12,
                        childAspectRatio: isSmallScreen ? 1.2 : 1.3,
                        children: [
                          _buildActionButton(
                            'New Sale',
                            Icons.shopping_cart,
                            Colors.green,
                            () => Navigator.pushNamed(context, '/create-sale'),
                            isSmallScreen,
                          ),
                          _buildActionButton(
                            'Add Product',
                            Icons.add_box,
                            Colors.blue,
                            () => Navigator.pushNamed(context, '/add-product'),
                            isSmallScreen,
                          ),
                          _buildActionButton(
                            'Products',
                            Icons.inventory,
                            Colors.orange,
                            () => Navigator.pushNamed(context, '/products'),
                            isSmallScreen,
                          ),
                          _buildActionButton(
                            'Reports',
                            Icons.bar_chart,
                            Colors.purple,
                            () => Navigator.pushNamed(context, '/reports'),
                            isSmallScreen,
                          ),
                        ],
                      ),
                      
                      // Add bottom padding for scrolling
                      SizedBox(height: padding.bottom + 10),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  // Optional small indicator
                  Container(
                    width: isSmallScreen ? 6 : 8,
                    height: isSmallScreen ? 6 : 8,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Value
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              // Title
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
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: isSmallScreen ? 22 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 11 : 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}