import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _secretCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureSecretCode = true;
  
  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 6;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _secretCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          storeName: _storeNameController.text.trim(),
          secretCode: _secretCodeController.text.trim(),
        );

        if (user != null && mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        String errorMessage = 'Registration failed';
        if (e.toString().contains('secret code')) {
          errorMessage = 'Invalid secret code';
        } else if (e.toString().contains('email')) {
          errorMessage = 'Invalid email format';
        } else if (e.toString().contains('rate limit')) {
          errorMessage = 'Too many attempts. Please try again later.';
        } else {
          errorMessage = 'Email might already be in use';
        }
        
        if (mounted) {
          _showErrorSnackbar(errorMessage);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome Aboard!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Account created successfully for ${_fullNameController.text}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In Now'),
            ),
          ),
        ],
      ),
    );
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
                maxLines: 2,
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final isMediumScreen = mediaQuery.size.width < 600;
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final padding = mediaQuery.padding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: isSmallScreen ? 18 : 20,
          ),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isSmallScreen ? 16 : 24,
            right: isSmallScreen ? 16 : 24,
            top: isSmallScreen ? 12 : 16,
            bottom: keyboardOpen ? 20 : padding.bottom + 20,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header illustration - hide when keyboard is open on very small screens
                if (!(isSmallScreen && keyboardOpen))
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: isSmallScreen ? 70 : 80,
                          height: isSmallScreen ? 70 : 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.secondaryColor,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.storefront,
                            color: Colors.white,
                            size: isSmallScreen ? 30 : 35,
                          ),
                        ),
                      );
                    },
                  ),
                
                if (!(isSmallScreen && keyboardOpen))
                  SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Welcome text
                Text(
                  'Start Your Journey',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an account to manage your store',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name
                      _buildAnimatedField(
                        index: 0,
                        isSmallScreen: isSmallScreen,
                        child: TextFormField(
                          controller: _fullNameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            hintStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppTheme.primaryColor,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Store Name
                      _buildAnimatedField(
                        index: 1,
                        isSmallScreen: isSmallScreen,
                        child: TextFormField(
                          controller: _storeNameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Store Name',
                            hintText: 'Enter your store name',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            hintStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            prefixIcon: Icon(
                              Icons.store_outlined,
                              color: AppTheme.primaryColor,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Email
                      _buildAnimatedField(
                        index: 2,
                        isSmallScreen: isSmallScreen,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            hintStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppTheme.primaryColor,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Secret Code
                      _buildAnimatedField(
                        index: 3,
                        isSmallScreen: isSmallScreen,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.05),
                                AppTheme.secondaryColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: TextFormField(
                            controller: _secretCodeController,
                            obscureText: _obscureSecretCode,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Secret Code',
                              hintText: 'Enter registration code',
                              labelStyle: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                              hintStyle: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.primaryColor,
                                size: isSmallScreen ? 16 : 18,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureSecretCode ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade600,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureSecretCode = !_obscureSecretCode;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              helperText: 'Required for registration',
                              helperStyle: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: isSmallScreen ? 9 : 10,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 10 : 12,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Password with strength indicator
                      _buildAnimatedField(
                        index: 4,
                        isSmallScreen: isSmallScreen,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Create a password',
                                labelStyle: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                ),
                                hintStyle: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.primaryColor,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey.shade600,
                                    size: isSmallScreen ? 16 : 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 10 : 12,
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                isDense: true,
                              ),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (value.length < 6) {
                                  return 'Min 6 chars';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Password strength indicators
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _buildStrengthChip('6+ chars', _hasMinLength, isSmallScreen),
                                _buildStrengthChip('Uppercase', _hasUpperCase, isSmallScreen),
                                _buildStrengthChip('Lowercase', _hasLowerCase, isSmallScreen),
                                _buildStrengthChip('Number', _hasNumber, isSmallScreen),
                                _buildStrengthChip('Special', _hasSpecialChar, isSmallScreen),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Confirm Password
                      _buildAnimatedField(
                        index: 5,
                        isSmallScreen: isSmallScreen,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signUp(),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            labelStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            hintStyle: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: AppTheme.primaryColor,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade600,
                                size: isSmallScreen ? 16 : 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords don\'t match';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 44 : 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                    Icon(
                                      Icons.person_add,
                                      size: isSmallScreen ? 16 : 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Terms and conditions
                      Text(
                        'By creating an account, you agree to our',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 10,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' and ',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildAnimatedField({
    required int index,
    required bool isSmallScreen,
    required Widget child,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildStrengthChip(String label, bool isMet, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 4 : 6,
        vertical: isSmallScreen ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: isMet ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMet ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: isSmallScreen ? 8 : 10,
            color: isMet ? Colors.green : Colors.grey.shade500,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 7 : 8,
              color: isMet ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}