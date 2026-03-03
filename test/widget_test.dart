// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_accounting/main.dart'; // Change this to match your project name

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts with a login screen
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Sign in to manage your store'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email and password fields
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}