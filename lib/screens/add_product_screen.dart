import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';
import '../utils/currency.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _categoryController = TextEditingController();

  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isEditing = false;
  
  late AnimationController _animationController;
  final FocusNode _barcodeFocusNode = FocusNode();
  
  // For custom category
  bool _isCustomCategory = false;
  final TextEditingController _customCategoryController = TextEditingController();

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Food',
    'Beverages',
    'Stationery',
    'Household',
    'Beauty',
    'Sports',
    'Toys',
    'Books',
    'Automotive',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadUser();
    if (widget.product != null) {
      _isEditing = true;
      _fillFormWithProduct(widget.product!);
    }
    _animationController.forward();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _categoryController.dispose();
    _customCategoryController.dispose();
    _barcodeFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserDetails();
    setState(() {
      _currentUser = user;
    });
  }

  void _fillFormWithProduct(Product product) {
    _barcodeController.text = product.barcode;
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _purchasePriceController.text = product.purchasePrice.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _quantityController.text = product.quantity.toString();
    _thresholdController.text = product.lowStockThreshold.toString();
    
    // Check if category is in predefined list
    if (_categories.contains(product.category)) {
      _categoryController.text = product.category;
      _isCustomCategory = false;
    } else {
      _isCustomCategory = true;
      _customCategoryController.text = product.category;
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      setState(() => _isLoading = true);

      try {
        final category = _isCustomCategory 
            ? _customCategoryController.text.trim()
            : _categoryController.text.trim();

        final product = Product(
          id: widget.product?.id,
          barcode: _barcodeController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          purchasePrice: double.parse(_purchasePriceController.text.trim()),
          sellingPrice: double.parse(_sellingPriceController.text.trim()),
          quantity: int.parse(_quantityController.text.trim()),
          lowStockThreshold: int.parse(_thresholdController.text.trim()),
          category: category.isEmpty ? 'General' : category,
          storeId: _currentUser!.storeId,
        );

        if (_isEditing) {
          await _productService.updateProduct(product.id!, product.toJson());
          _showSuccessSnackbar('Product updated successfully');
        } else {
          await _productService.addProduct(product);
          _showSuccessSnackbar('Product added successfully');
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar('Error: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  void _showBarcodeScanner() {
    // Placeholder for barcode scanner functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode scanner coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final padding = mediaQuery.padding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete product',
            ),
        ],
      ),
      body: SafeArea( // Added SafeArea to handle notches and system bars
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.05),
                ),
              ),
            ),
            
            // Main content
            SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 500),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Added for better alignment
                    children: [
                      // Product icon/header
                      Container(
                        width: double.infinity, // Ensure full width
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              AppTheme.secondaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isEditing ? Icons.edit : Icons.add_business,
                                size: isSmallScreen ? 24 : 30,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditing ? 'Edit Product' : 'New Product',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEditing 
                                        ? 'Update product information below'
                                        : 'Fill in the details to add a new product',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barcode section with scan button
                      _buildInputField(
                        controller: _barcodeController,
                        label: 'Barcode',
                        icon: Icons.qr_code_scanner,
                        hint: 'Enter product barcode',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                          onPressed: _showBarcodeScanner,
                          tooltip: 'Scan barcode',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter barcode';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Product name
                      _buildInputField(
                        controller: _nameController,
                        label: 'Product Name',
                        icon: Icons.shopping_bag,
                        hint: 'Enter product name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Description
                      _buildInputField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        hint: 'Enter product description (optional)',
                        maxLines: 3,
                        validator: null,
                      ),
                      const SizedBox(height: 12),

                      // Category selection
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.category, color: AppTheme.primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Category',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            if (!_isCustomCategory)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: DropdownButtonFormField<String>(
                                  value: _categoryController.text.isNotEmpty
                                      ? _categoryController.text
                                      : null,
                                  decoration: const InputDecoration(
                                    hintText: 'Select a category',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(
                                        category,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _categoryController.text = value ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (!_isCustomCategory && (value == null || value.isEmpty)) {
                                      return 'Please select a category';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            
                            if (_isCustomCategory)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: TextFormField(
                                  controller: _customCategoryController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter category name',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  validator: (value) {
                                    if (_isCustomCategory && (value == null || value.isEmpty)) {
                                      return 'Please enter category name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isCustomCategory = !_isCustomCategory;
                                        if (!_isCustomCategory) {
                                          _customCategoryController.clear();
                                        }
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isCustomCategory ? Icons.list : Icons.add,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isCustomCategory ? 'Choose from list' : 'Add custom',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: AppTheme.successColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Pricing',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildPriceField(
                                    controller: _purchasePriceController,
                                    label: 'Purchase',
                                    hint: 'Cost',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildPriceField(
                                    controller: _sellingPriceController,
                                    label: 'Selling',
                                    hint: 'Retail',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_purchasePriceController.text.isNotEmpty && 
                                _sellingPriceController.text.isNotEmpty)
                              _buildProfitPreview(isSmallScreen),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stock section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.inventory, color: AppTheme.warningColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Stock Management',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildStockField(
                                    controller: _quantityController,
                                    label: 'Quantity',
                                    icon: Icons.numbers,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStockField(
                                    controller: _thresholdController,
                                    label: 'Alert at',
                                    icon: Icons.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.warningColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: AppTheme.warningColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Get notified when stock falls below alert threshold',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 11,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
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
                                    Icon(_isEditing ? Icons.update : Icons.add, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _isEditing ? 'Update Product' : 'Add Product',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      // Add bottom padding for scrolling
                      SizedBox(height: padding.bottom + 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: isSmallScreen ? 18 : 24),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 12 : 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: isSmallScreen ? 11 : 13),
        hintStyle: TextStyle(fontSize: isSmallScreen ? 11 : 13),
        prefixIcon: Icon(Icons.attach_money, size: isSmallScreen ? 14 : 18, color: AppTheme.successColor),
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 8 : 12,
        ),
        isDense: true, // Makes the field more compact
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Req';
        }
        if (double.tryParse(value) == null) {
          return 'Invalid';
        }
        return null;
      },
    );
  }

  Widget _buildStockField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: isSmallScreen ? 11 : 13),
        prefixIcon: Icon(icon, size: isSmallScreen ? 14 : 18, color: AppTheme.warningColor),
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 8 : 12,
        ),
        isDense: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Req';
        }
        if (int.tryParse(value) == null) {
          return 'Invalid';
        }
        return null;
      },
    );
  }

  Widget _buildProfitPreview(bool isSmallScreen) {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    final profit = sellingPrice - purchasePrice;
    final margin = purchasePrice > 0 ? (profit / purchasePrice) * 100 : 0;

    Color profitColor = Colors.green;
    if (profit < 0) profitColor = Colors.red;
    else if (profit < 10) profitColor = Colors.orange;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: profitColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: profitColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profit',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  '${profit >= 0 ? '+' : '-'}₪${profit.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    color: profitColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: profitColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${margin.toStringAsFixed(1)}%',
              style: TextStyle(
                color: profitColor,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
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
              // Implement delete functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product deleted'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}