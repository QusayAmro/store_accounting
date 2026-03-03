// lib/utils/currency.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Currency {
  // Default currency settings (ILS - Israeli Shekel)
  static String _symbol = '₪';
  static String _code = 'ILS';
  static bool _symbolOnLeft = false; // ILS symbol goes on the right (e.g., 100₪)
  static int _decimalPlaces = 2;
  static String _decimalSeparator = '.';
  static String _thousandSeparator = ',';

  // Initialize currency settings from shared preferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _symbol = prefs.getString('currency_symbol') ?? '₪';
    _code = prefs.getString('currency_code') ?? 'ILS';
    _symbolOnLeft = prefs.getBool('currency_symbol_on_left') ?? false;
    _decimalPlaces = prefs.getInt('currency_decimal_places') ?? 2;
    _decimalSeparator = prefs.getString('currency_decimal_separator') ?? '.';
    _thousandSeparator = prefs.getString('currency_thousand_separator') ?? ',';
  }

  // Get current currency symbol
  static String get symbol => _symbol;

  // Get current currency code
  static String get code => _code;

  // Check if symbol should be on left
  static bool get symbolOnLeft => _symbolOnLeft;

  // Format amount with currency symbol
  static String format(double amount, {bool showSymbol = true, bool showCode = false}) {
    String formattedNumber = _formatNumber(amount);
    
    if (!showSymbol && !showCode) return formattedNumber;
    
    String symbolPart = showSymbol ? _symbol : '';
    String codePart = showCode ? ' $_code' : '';
    
    if (_symbolOnLeft) {
      return '$symbolPart$formattedNumber$codePart';
    } else {
      return '$formattedNumber$symbolPart$codePart';
    }
  }

  // Format amount without currency symbol
  static String formatNumber(double amount) {
    return _formatNumber(amount);
  }

  // Parse currency string to double
  static double? parse(String currencyString) {
    try {
      // Remove currency symbol and any spaces
      String cleaned = currencyString.replaceAll(_symbol, '').replaceAll(' ', '');
      
      // Handle thousand separators
      cleaned = cleaned.replaceAll(_thousandSeparator, '');
      
      // Handle decimal separator
      if (_decimalSeparator != '.') {
        cleaned = cleaned.replaceAll(_decimalSeparator, '.');
      }
      
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  // Format amount with color based on value (positive/negative)
  static Text formattedText(double amount, {
    bool showSymbol = true,
    bool colorize = true,
    TextStyle? style,
  }) {
    Color textColor = Colors.black;
    if (colorize) {
      if (amount > 0) textColor = Colors.green.shade700;
      if (amount < 0) textColor = Colors.red.shade700;
    }
    
    return Text(
      format(amount, showSymbol: showSymbol),
      style: (style ?? const TextStyle()).copyWith(color: textColor),
    );
  }

  // Change currency settings (can be called from settings screen)
  static Future<void> setCurrency({
    required String symbol,
    required String code,
    required bool symbolOnLeft,
    int decimalPlaces = 2,
    String decimalSeparator = '.',
    String thousandSeparator = ',',
  }) async {
    _symbol = symbol;
    _code = code;
    _symbolOnLeft = symbolOnLeft;
    _decimalPlaces = decimalPlaces;
    _decimalSeparator = decimalSeparator;
    _thousandSeparator = thousandSeparator;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
    await prefs.setString('currency_code', code);
    await prefs.setBool('currency_symbol_on_left', symbolOnLeft);
    await prefs.setInt('currency_decimal_places', decimalPlaces);
    await prefs.setString('currency_decimal_separator', decimalSeparator);
    await prefs.setString('currency_thousand_separator', thousandSeparator);
  }

  // Helper method to format number with thousand separators
  static String _formatNumber(double amount) {
    // Handle negative numbers
    bool isNegative = amount < 0;
    double absoluteAmount = amount.abs();
    
    // Split into integer and decimal parts
    String amountStr = absoluteAmount.toStringAsFixed(_decimalPlaces);
    List<String> parts = amountStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Add thousand separators
    StringBuffer formattedInteger = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formattedInteger.write(_thousandSeparator);
      }
      formattedInteger.write(integerPart[i]);
      count++;
    }
    
    String result = formattedInteger.toString().split('').reversed.join();
    
    // Add decimal part
    if (_decimalPlaces > 0) {
      result += _decimalSeparator + decimalPart.padRight(_decimalPlaces, '0');
    }
    
    return (isNegative ? '-' : '') + result;
  }

  // Pre-defined currency presets
  static final Map<String, Map<String, dynamic>> currencies = {
    'ILS': {
      'symbol': '₪',
      'code': 'ILS',
      'symbolOnLeft': false,
      'decimalPlaces': 2,
      'name': 'Israeli Shekel',
    },
    'USD': {
      'symbol': '\$',
      'code': 'USD',
      'symbolOnLeft': true,
      'decimalPlaces': 2,
      'name': 'US Dollar',
    },
    'EUR': {
      'symbol': '€',
      'code': 'EUR',
      'symbolOnLeft': false,
      'decimalPlaces': 2,
      'name': 'Euro',
    },
    'GBP': {
      'symbol': '£',
      'code': 'GBP',
      'symbolOnLeft': true,
      'decimalPlaces': 2,
      'name': 'British Pound',
    },
    'JPY': {
      'symbol': '¥',
      'code': 'JPY',
      'symbolOnLeft': true,
      'decimalPlaces': 0,
      'name': 'Japanese Yen',
    },
    'CAD': {
      'symbol': 'C\$',
      'code': 'CAD',
      'symbolOnLeft': true,
      'decimalPlaces': 2,
      'name': 'Canadian Dollar',
    },
    'AUD': {
      'symbol': 'A\$',
      'code': 'AUD',
      'symbolOnLeft': true,
      'decimalPlaces': 2,
      'name': 'Australian Dollar',
    },
    'CHF': {
      'symbol': 'CHF',
      'code': 'CHF',
      'symbolOnLeft': false,
      'decimalPlaces': 2,
      'name': 'Swiss Franc',
    },
    'CNY': {
      'symbol': '¥',
      'code': 'CNY',
      'symbolOnLeft': true,
      'decimalPlaces': 2,
      'name': 'Chinese Yuan',
    },
    'RUB': {
      'symbol': '₽',
      'code': 'RUB',
      'symbolOnLeft': false,
      'decimalPlaces': 2,
      'name': 'Russian Ruble',
    },
  };

  // Get list of available currencies for dropdown
  static List<DropdownMenuItem<String>> getCurrencyDropdownItems() {
    return currencies.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text('${entry.value['name']} (${entry.value['symbol']})'),
      );
    }).toList();
  }

  // Apply a preset currency
  static Future<void> applyPreset(String currencyCode) async {
    if (currencies.containsKey(currencyCode)) {
      final preset = currencies[currencyCode]!;
      await setCurrency(
        symbol: preset['symbol'],
        code: preset['code'],
        symbolOnLeft: preset['symbolOnLeft'],
        decimalPlaces: preset['decimalPlaces'],
      );
    }
  }
}

// Extension for easy currency formatting on double
extension CurrencyExtension on double {
  String toCurrency({bool showSymbol = true, bool showCode = false}) {
    return Currency.format(this, showSymbol: showSymbol, showCode: showCode);
  }
  
  Text toCurrencyText({bool showSymbol = true, bool colorize = true, TextStyle? style}) {
    return Currency.formattedText(this, showSymbol: showSymbol, colorize: colorize, style: style);
  }
}

// Extension for easy currency formatting on int
extension CurrencyExtensionInt on int {
  String toCurrency({bool showSymbol = true, bool showCode = false}) {
    return Currency.format(toDouble(), showSymbol: showSymbol, showCode: showCode);
  }
  
  Text toCurrencyText({bool showSymbol = true, bool colorize = true, TextStyle? style}) {
    return Currency.formattedText(toDouble(), showSymbol: showSymbol, colorize: colorize, style: style);
  }
}