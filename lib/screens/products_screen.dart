import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import 'add_product_screen.dart';
import '../utils/theme.dart';
import '../utils/currency.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isGridView = false;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserAndProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndProducts() async {
    final user = await _authService.getCurrentUserDetails();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      _loadProducts();
    }
  }

  void _loadProducts() {
    if (_currentUser == null) return;

    _productService.getProducts(_currentUser!.storeId).listen((products) {
      if (mounted) {
        setState(() {
          _products = products;
          _filterProducts();
          _isLoading = false;
        });
      }
    });
  }

  void _filterProducts() {
    var filtered = List<Product>.from(_products);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.barcode.contains(_searchQuery)
      ).toList();
    }

    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) =>
        product.category == _selectedCategory
      ).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  List<String> _getCategories() {
    final categories = _products.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Product deleted successfully',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error deleting product',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final padding = mediaQuery.padding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                key: ValueKey(_isGridView),
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List view' : 'Grid view',
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          ),
          IconButton(
            icon: Icon(Icons.add, size: isSmallScreen ? 20 : 24),
            onPressed: () => Navigator.pushNamed(context, '/add-product'),
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isSmallScreen)
            : Column(
                children: [
                  _buildSearchAndFilterBar(isSmallScreen),
                  if (_filteredProducts.isNotEmpty)
                    _buildStatsBar(isSmallScreen),
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? _buildEmptyState(isSmallScreen)
                        : _isGridView
                            ? _buildGridView(isSmallScreen)
                            : _buildListView(isSmallScreen),
                  ),
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
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isSmallScreen ? 'Search...' : 'Search by name or barcode...',
                hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.primaryColor,
                  size: isSmallScreen ? 18 : 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: isSmallScreen ? 16 : 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _filterProducts();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 10 : 14,
                ),
                isDense: true,
              ),
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterProducts();
                });
              },
            ),
          ),
          
          if (_products.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: isSmallScreen ? 36 : 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _getCategories().length,
                itemBuilder: (context, index) {
                  final category = _getCategories()[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterProducts();
                        });
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
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 4 : 8,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: isSelected ? 2 : 0,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isSmallScreen) {
    final lowStockCount = _products.where((p) => p.quantity <= p.lowStockThreshold).length;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 12,
      ),
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Row(
        children: [
          Icon(
            Icons.inventory,
            size: isSmallScreen ? 16 : 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${_filteredProducts.length} products found',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10,
              vertical: isSmallScreen ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: isSmallScreen ? 12 : 14,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$lowStockCount low stock',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                      _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory,
                      size: isSmallScreen ? 35 : 45,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No products found'
                  : 'No products yet',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different keywords'
                  : 'Start by adding your first product',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/add-product'),
                icon: Icon(Icons.add, size: isSmallScreen ? 16 : 18),
                label: Text(
                  'Add Product',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListView(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isLowStock = product.quantity <= product.lowStockThreshold;
        
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isLowStock 
                      ? AppTheme.warningColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProductScreen(product: product),
                    ),
                  );
                },
                onLongPress: () => _deleteProduct(product.id!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isLowStock
                        ? Border.all(color: AppTheme.warningColor.withOpacity(0.3), width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isSmallScreen ? 50 : 60,
                        height: isSmallScreen ? 50 : 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isLowStock
                                ? [AppTheme.warningColor.withOpacity(0.2), Colors.orange.shade50]
                                : [AppTheme.primaryColor.withOpacity(0.1), Colors.blue.shade50],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.quantity.toString(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? AppTheme.warningColor : AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'stock',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 8 : 9,
                                  color: isLowStock ? AppTheme.warningColor : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isLowStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          size: isSmallScreen ? 8 : 10,
                                          color: AppTheme.warningColor,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Low',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 7 : 8,
                                            color: AppTheme.warningColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.barcode,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 8 : 9,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 8 : 9,
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selling',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 8 : 9,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        Currency.format(product.sellingPrice),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successColor,
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
                                        'Purchase',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 8 : 9,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        Currency.format(product.purchasePrice),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 11,
                                          color: Colors.grey.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(bool isSmallScreen) {
    return GridView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 2,
        childAspectRatio: isSmallScreen ? 0.7 : 0.75,
        crossAxisSpacing: isSmallScreen ? 6 : 8,
        mainAxisSpacing: isSmallScreen ? 6 : 8,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isLowStock = product.quantity <= product.lowStockThreshold;
        
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            shadowColor: isLowStock ? AppTheme.warningColor.withOpacity(0.3) : null,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(product: product),
                  ),
                );
              },
              onLongPress: () => _deleteProduct(product.id!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isLowStock
                      ? Border.all(color: AppTheme.warningColor.withOpacity(0.5), width: 1.5)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: isSmallScreen ? 70 : 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isLowStock
                              ? [AppTheme.warningColor.withOpacity(0.3), Colors.orange.shade50]
                              : [AppTheme.primaryColor.withOpacity(0.1), Colors.blue.shade50],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: isSmallScreen ? 20 : 24,
                                  color: isLowStock ? AppTheme.warningColor : AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.quantity} in stock',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 8 : 9,
                                    color: isLowStock ? AppTheme.warningColor : AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isLowStock)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning,
                                  size: isSmallScreen ? 8 : 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 7 : 8,
                          color: AppTheme.secondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sell',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 6 : 7,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              Currency.format(product.sellingPrice),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Cost',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 6 : 7,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              Currency.format(product.purchasePrice),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 9,
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          product.barcode,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 6 : 7,
                            color: Colors.grey.shade700,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}