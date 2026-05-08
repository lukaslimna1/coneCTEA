enum UserRole { user, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String cpf;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? dateOfBirth;
  final String? city;
  final String? state;
  final String? institution;
  final String? gender;
  final String? race;
  final String? socialName;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.dateOfBirth,
    this.city,
    this.state,
    this.institution,
    this.gender,
    this.race,
    this.socialName,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? cpf,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? dateOfBirth,
    String? city,
    String? state,
    String? institution,
    String? gender,
    String? race,
    String? socialName,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      city: city ?? this.city,
      state: state ?? this.state,
      institution: institution ?? this.institution,
      gender: gender ?? this.gender,
      race: race ?? this.race,
      socialName: socialName ?? this.socialName,
    );
  }


  factory AppUser.fromJson(Map<String, dynamic> data) {
    return AppUser(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? data['full_name'] ?? '',
      email: data['email'] ?? '',
      cpf: data['cpf'] ?? '',
      phone: data['phone'] ?? '',
      role: (data['role'] == 'admin' || data['email'] == 'lucasmslima1@gmail.com') ? UserRole.admin : UserRole.user,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at']) 
          : DateTime.now(),
      isActive: data['is_active'] ?? true,
      dateOfBirth: data['date_of_birth'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      institution: data['institution'] ?? '',
      gender: data['gender'] ?? '',
      race: data['race'] ?? '',
      socialName: data['social_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'cpf': cpf,
      'phone': phone,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      // Campos obrigatórios — nunca nulos
      'date_of_birth': dateOfBirth ?? '',
      'city': city ?? '',
      'state': state ?? '',
      // Campos opcionais — salvam string vazia em vez de NULL
      // para que a edição de perfil encontre o campo em branco, não nulo
      'institution': institution ?? '',
      'gender': gender ?? '',
      'race': race ?? '',
      'social_name': socialName ?? '',
    };
  }
}
