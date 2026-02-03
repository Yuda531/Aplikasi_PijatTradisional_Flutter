import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums/user_role.dart';

/// User model representing a user in the application.
class UserModel {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? occupation;
  final String? address;
  final UserRole role;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.occupation,
    this.address,
    required this.role,
    required this.createdAt,
  });

  /// Create a new user with default role (customer).
  factory UserModel.newUser({
    required String id,
    required String email,
    required String name,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
  }

  /// Create UserModel from Firestore document.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      age: data['age'],
      occupation: data['occupation'],
      address: data['address'],
      role: UserRole.fromString(data['role'] ?? 'customer'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'occupation': occupation,
      'address': address,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? occupation,
    String? address,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: ${role.name})';
  }
}
