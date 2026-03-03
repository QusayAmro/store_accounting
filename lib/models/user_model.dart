// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String storeName;
  final String storeId;  // Added this field
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.storeName,
    required this.storeId,  // Added this required parameter
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      storeName: json['store_name'] ?? '',
      storeId: json['store_id'] ?? json['id'] ?? '',  // Use store_id if available, fallback to id
      role: json['role'] ?? 'staff',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'store_name': storeName,
      'store_id': storeId,  // Added this
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}