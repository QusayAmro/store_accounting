// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Replace these with your actual Supabase credentials
  static const String supabaseUrl = 'https://zxmtoyyarjwynbleecjn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4bXRveXlhcmp3eW5ibGVlY2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0Nzg3NjQsImV4cCI6MjA4ODA1NDc2NH0.mLxhp4FLl4nl9Yo-eqoXNnXHgMrm6XpRZ3VhCsOnRxI';


  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Helper method to handle errors
  dynamic handleError(dynamic error) {
    print('Supabase error: $error');
    return error;
  }

  // Check if connection is available
  Future<bool> checkConnection() async {
    try {
      await client.from('users').select('count').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get realtime subscription for a table
 RealtimeChannel subscribeToTableSimple(
    String table, 
    Function(Map<String, dynamic>) onUpdate
  ) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            onUpdate(payload.newRecord as Map<String, dynamic>);
          },
        )
        .subscribe();
  }
}