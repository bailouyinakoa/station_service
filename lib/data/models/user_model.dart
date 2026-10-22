import 'package:station_service_app/domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.username,
    required super.name,
    required super.role,
  });

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['username'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'username': username, 'name': name, 'role': role};
  }
}
