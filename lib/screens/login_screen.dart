// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null && mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _showError('Invalid email or password');
        }
      } catch (e) {
        _showError('An error occurred. Please try again.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
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
    final isVerySmallScreen = mediaQuery.size.width < 320;
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final padding = mediaQuery.padding;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animated container - hide when keyboard is open on very small screens
                  if (!(isVerySmallScreen && keyboardOpen))
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween<double>(begin: 0, end: 1),
                      curve: Curves.easeOutBack,
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: isSmallScreen ? 80 : 100,
                            height: isSmallScreen ? 80 : 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.storefront,
                              size: isSmallScreen ? 40 : 50,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  
                  // Add spacing only if logo is shown
                  if (!(isVerySmallScreen && keyboardOpen))
                    SizedBox(height: isSmallScreen ? 20 : 30),
                  
                  // Welcome text
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to manage your store',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Form card
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 400, // Prevents card from getting too wide on tablets
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email required';
                              }
                              if (!value.contains('@')) {
                                return 'Invalid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password required';
                              }
                              if (value.length < 6) {
                                return 'Min 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 44 : 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
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
                                  : Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Register link
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: Size(50, isSmallScreen ? 30 : 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Add bottom padding for very small screens
                  if (isVerySmallScreen)
                    SizedBox(height: padding.bottom + 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}