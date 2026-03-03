
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/create_sale_screen.dart';
import 'utils/theme.dart';
import 'utils/currency.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Currency.initialize();
  try {
    await Supabase.initialize(
     url: 'https://zxmtoyyarjwynbleecjn.supabase.co', // Replace with your actual URL
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4bXRveXlhcmp3eW5ibGVlY2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0Nzg3NjQsImV4cCI6MjA4ODA1NDc2NH0.mLxhp4FLl4nl9Yo-eqoXNnXHgMrm6XpRZ3VhCsOnRxI', // Replace with your actual anon key
    );
  } catch (e) {
    print('Error initializing Supabase: $e');
  }
  
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store Accounting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/products': (context) => const ProductsScreen(),
        '/add-product': (context) => const AddProductScreen(),
        '/sales': (context) => const SalesScreen(),
        '/create-sale': (context) => const CreateSaleScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}