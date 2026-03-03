import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import '../models/sale_model.dart';

class NotificationService {
  final SupabaseClient _supabase = SupabaseService().client;

  // Get unread notifications
 Stream<List<Sale>> getSalesStream(String storeId) {
  return _supabase
      .from('sales')
      .stream(primaryKey: ['id'])
      .eq('store_id', storeId)  // This should actually work - let's check
      .order('created_at', ascending: false)
      .map((data) {
        return data.map((json) => Sale.fromJson({
          ...json,
          'sale_items': [],
        })).toList();
      });
}

  // Get all notifications
  Stream<List<Map<String, dynamic>>> getAllNotifications(String storeId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String storeId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('store_id', storeId)
        .eq('read', false);
  }

  // Get unread count
  Future<int> getUnreadCount(String storeId) async {
    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('store_id', storeId)
        .eq('read', false);

    return response.length;
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String storeId) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('store_id', storeId);
  }
}