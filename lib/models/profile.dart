enum UserRole { common, admin }

class Profile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? photoUrl;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.photoUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.common,
      phone: json['phone'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role == UserRole.admin ? 'admin' : 'common',
      'phone': phone,
      'photo_url': photoUrl,
    };
  }
}
