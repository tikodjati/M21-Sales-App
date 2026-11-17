class UserModel {
  final int id;
  final String username;
  final String name;
  final String role; // 'admin' or 'sales'
  final String status; // 'active' or 'inactive'

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.status,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isSales => role.toLowerCase() == 'sales';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'sales',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'status': status,
    };
  }
}
