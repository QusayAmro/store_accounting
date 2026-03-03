import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/sale_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../utils/currency.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<SaleItem> _cartItems = [];
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _taxPercentageController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  
  String _paymentMethod = 'Cash';
  bool _applyTax = false;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _selectedCategory = 'All';
  
  late AnimationController _animationController;
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _paymentMethods = ['Cash', 'Card', 'Transfer'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadUserAndProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _discountController.dispose();
    _taxPercentageController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
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
          _products = products.where((p) => p.quantity > 0).toList();
          _applyFilters();
          _isLoading = false;
        });
        _animationController.forward();
      }
    });
  }

  List<String> _getCategories() {
    final categories = _products.map((p) => p.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  void _applyFilters() {
    var filtered = List<Product>.from(_products);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) =>
        product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        product.barcode.contains(_searchController.text)
      ).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) =>
        product.category == _selectedCategory
      ).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _searchProducts(String query) {
    _applyFilters();
  }

  void _addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      final existingItem = _cartItems[existingIndex];
      if (existingItem.quantity + 1 <= product.quantity) {
        setState(() {
          existingItem.updateQuantity(existingItem.quantity + 1);
        });
        _showQuickSnackbar('Added another ${product.name}', Icons.add_shopping_cart, Colors.green);
      } else {
        _showQuickSnackbar('Only ${product.quantity} items available', Icons.warning, Colors.orange);
      }
    } else {
      setState(() {
        _cartItems.add(SaleItem(
          productId: product.id!,
          productName: product.name,
          quantity: 1,
          purchasePrice: product.purchasePrice,
          sellingPrice: product.sellingPrice,
          discount: 0,
          subtotal: product.sellingPrice,
        ));
      });
      _showQuickSnackbar('Added ${product.name} to cart', Icons.add_shopping_cart, Colors.green);
    }
  }

  void _showQuickSnackbar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(int index) {
    final item = _cartItems[index];
    setState(() {
      _cartItems.removeAt(index);
    });
    _showQuickSnackbar('Removed ${item.productName} from cart', Icons.remove_shopping_cart, Colors.red);
  }

  void _updateQuantity(int index, int newQuantity) {
    final item = _cartItems[index];
    final product = _products.firstWhere((p) => p.id == item.productId);

    if (newQuantity <= product.quantity) {
      setState(() {
        item.updateQuantity(newQuantity);
      });
    } else {
      _showQuickSnackbar('Only ${product.quantity} items available', Icons.warning, Colors.orange);
    }
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items from cart?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cartItems.clear();
              });
              Navigator.pop(context);
              _showQuickSnackbar('Cart cleared', Icons.delete_sweep, Colors.orange);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  double get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get _discount {
    return double.tryParse(_discountController.text) ?? 0;
  }

  double get _tax {
    if (!_applyTax) return 0.0;
    final taxPercentage = double.tryParse(_taxPercentageController.text) ?? 0;
    return _subtotal * (taxPercentage / 100);
  }

  double get _total {
    return _subtotal + _tax - _discount;
  }

  Future<void> _completeSale() async {
    // Validate customer name
    if (_customerNameController.text.isEmpty) {
      _showQuickSnackbar('Please enter customer name', Icons.person, Colors.orange);
      return;
    }

    if (_cartItems.isEmpty) {
      _showQuickSnackbar('Cart is empty', Icons.shopping_cart, Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final invoiceNumber = await _saleService.generateInvoiceNumber(_currentUser!.storeId);

      final sale = Sale(
        invoiceNumber: invoiceNumber,
        subtotal: _subtotal,
        tax: _tax,
        discount: _discount,
        total: _total,
        paymentMethod: _paymentMethod,
        customerName: _customerNameController.text.trim(),
        storeId: _currentUser!.storeId,
        userId: _currentUser!.id,
        createdAt: DateTime.now(),
        items: List.from(_cartItems),
      );

      await _saleService.createSale(sale);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            content: SingleChildScrollView( // Added scroll for small screens
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sale Completed!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReceiptItem('Invoice', invoiceNumber),
                  _buildReceiptItem('Customer', _customerNameController.text),
                  _buildReceiptItem('Total', Currency.format(_total)),
                  _buildReceiptItem('Payment', _paymentMethod),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showQuickSnackbar('Error: $e', Icons.error, Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildReceiptItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Flexible( // Added Flexible to prevent overflow
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('New Sale'),
        elevation: 0,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCart,
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SafeArea( // Added SafeArea
              child: isSmallScreen && isPortrait
                  ? _buildMobileLayout() // Mobile layout (stacked)
                  : _buildTabletLayout(), // Tablet layout (side by side)
            ),
    );
  }

  // Tablet layout - side by side
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Products panel (left side)
        Expanded(
          flex: 2,
          child: _buildProductsPanel(),
        ),
        // Cart panel (right side)
        Container(
          width: 380, // Slightly reduced from 400
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  // Mobile layout - stacked with tab navigation
  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.inventory), text: 'Products'),
                Tab(icon: Icon(Icons.shopping_cart), text: 'Cart'),
              ],
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
            ),
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              children: [
                _buildProductsPanel(),
                _buildCartPanel(),
              ],
            ),
          ),
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
            'Loading products...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsPanel() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(12), // Reduced padding
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
              // Search field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: isSmallScreen ? 'Search...' : 'Search products by name or barcode...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
              ),
              const SizedBox(height: 8),
              
              // Category filters
              if (_products.isNotEmpty)
                SizedBox(
                  height: 40,
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
                              _applyFilters();
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontSize: isSmallScreen ? 11 : 13,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: 8,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Products grid/stats
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildNoProductsFound()
              : Column(
                  children: [
                    // Stats bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      child: Row(
                        children: [
                          Icon(Icons.inventory, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '${_filteredProducts.length} products',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Products grid
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isSmallScreen ? 2 : 3,
                          childAspectRatio: isSmallScreen ? 0.8 : 0.75,
                          crossAxisSpacing: isSmallScreen ? 8 : 12,
                          mainAxisSpacing: isSmallScreen ? 8 : 12,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product, index, isSmallScreen);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, int index, bool isSmallScreen) {
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
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          onTap: () => _addToCart(product),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isLowStock
                  ? Border.all(color: AppTheme.warningColor.withOpacity(0.3))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLowStock ? AppTheme.warningColor.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLowStock ? Icons.warning_amber : Icons.check_circle,
                            size: 10,
                            color: isLowStock ? AppTheme.warningColor : Colors.green,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${product.quantity}',
                            style: TextStyle(
                              fontSize: 9,
                              color: isLowStock ? AppTheme.warningColor : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.add_shopping_cart,
                      size: 14,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Product icon
                Center(
                  child: Container(
                    width: isSmallScreen ? 40 : 50,
                    height: isSmallScreen ? 40 : 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          Colors.blue.shade50,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: isSmallScreen ? 20 : 25,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Product name
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                
                // Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
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
                
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 7 : 8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        Currency.format(product.sellingPrice),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildNoProductsFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try a different search term'
                  : 'No products available in this category',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Column(
      children: [
        // Cart header with total
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: Colors.white, size: isSmallScreen ? 18 : 24),
                  const SizedBox(width: 8),
                  Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cartItems.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      Currency.format(_total),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cart items
        Expanded(
          child: _cartItems.isEmpty
              ? _buildEmptyCart(isSmallScreen)
              : ListView.builder(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return _buildCartItem(item, index, isSmallScreen);
                  },
                ),
        ),

        // Checkout section
        _buildCheckoutSection(isSmallScreen),
      ],
    );
  }

  Widget _buildEmptyCart(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: isSmallScreen ? 60 : 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap on products to add them',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(SaleItem item, int index, bool isSmallScreen) {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product icon
                  Container(
                    width: isSmallScreen ? 32 : 36,
                    height: isSmallScreen ? 32 : 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: isSmallScreen ? 16 : 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Currency.format(item.sellingPrice)} each',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Remove button
                  IconButton(
                    icon: Icon(Icons.close, size: isSmallScreen ? 14 : 16),
                    onPressed: () => _removeFromCart(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Quantity controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: AppTheme.primaryColor,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        onPressed: () {
                          if (item.quantity > 1) {
                            _updateQuantity(index, item.quantity - 1);
                          } else {
                            _removeFromCart(index);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        width: isSmallScreen ? 30 : 35,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.primaryColor,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        onPressed: () => _updateQuantity(index, item.quantity + 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      Currency.format(item.subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildCheckoutSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Customer name
          TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: 'Customer Name *',
              hintText: 'Enter name',
              labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13),
              hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13),
              prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor, size: isSmallScreen ? 18 : 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 8 : 12,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Tax and payment row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment',
                    labelStyle: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                    prefixIcon: Icon(Icons.payment, color: AppTheme.primaryColor, size: isSmallScreen ? 16 : 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                    isDense: true,
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            _getPaymentIcon(method),
                            size: isSmallScreen ? 12 : 14,
                            color: _getPaymentColor(method),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            method,
                            style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _paymentMethod = value!),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: CheckboxListTile(
                        title: Text(
                          'Tax',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                        ),
                        value: _applyTax,
                        onChanged: (value) => setState(() => _applyTax = value ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    if (_applyTax)
                      Flexible(
                        child: TextFormField(
                          controller: _taxPercentageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: '%',
                            labelStyle: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: isSmallScreen ? 6 : 8,
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Discount
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Discount',
              hintText: 'Optional',
              labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13),
              hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 13),
              prefixIcon: Icon(Icons.discount, color: AppTheme.warningColor, size: isSmallScreen ? 18 : 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixText: '₪ ',
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 8 : 12,
              ),
              isDense: true,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Summary
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal:', Currency.format(_subtotal), isSmallScreen),
                const SizedBox(height: 2),
                if (_applyTax) ...[
                  _buildSummaryRow(
                    'Tax (${_taxPercentageController.text.isEmpty ? '0' : _taxPercentageController.text}%):',
                    Currency.format(_tax),
                    isSmallScreen,
                  ),
                  const SizedBox(height: 2),
                ],
                if (_discount > 0) ...[
                  _buildSummaryRow('Discount:', '-${Currency.format(_discount)}', isSmallScreen, isDiscount: true),
                  const SizedBox(height: 2),
                ],
                const Divider(height: 12),
                _buildSummaryRow('Total:', Currency.format(_total), isSmallScreen, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Complete button
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 44 : 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _completeSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: isSmallScreen ? 18 : 20),
                        const SizedBox(width: 6),
                        Text(
                          'Complete Sale',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isSmallScreen, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal 
                ? (isSmallScreen ? 14 : 15) 
                : (isSmallScreen ? 11 : 12),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTotal 
                ? (isSmallScreen ? 16 : 18) 
                : (isSmallScreen ? 12 : 13),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? Colors.red : (isTotal ? Colors.green.shade700 : Colors.black87),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'Card':
        return Icons.credit_card;
      case 'Transfer':
        return Icons.swap_horiz;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method) {
      case 'Cash':
        return Colors.green;
      case 'Card':
        return Colors.blue;
      case 'Transfer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}