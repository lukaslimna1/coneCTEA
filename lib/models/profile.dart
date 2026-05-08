enum UserRole {
  user,
  admin,
  adminMaster,
  adminDev;

  static UserRole fromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'admin_master':
        return UserRole.adminMaster;
      case 'admin_dev':
        return UserRole.adminDev;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.adminMaster:
        return 'admin_master';
      case UserRole.adminDev:
        return 'admin_dev';
      case UserRole.user:
      default:
        return 'user';
    }
  }
}

class Profile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? cpf;
  final String? photoUrl;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.cpf,
    this.photoUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: UserRole.fromString(json['role']),
      phone: json['phone'],
      cpf: json['cpf'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.toDbString(),
      'phone': phone,
      'cpf': cpf,
      'photo_url': photoUrl,
    };
  }
}
