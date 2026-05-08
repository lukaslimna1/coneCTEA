enum UserRole { 
  user, 
  admin,        // ADM Padrão
  adminMaster,  // ADM Master (Gerecia ADMs)
  adminDev      // ADM DEV (Acesso total e manutenção)
}

extension UserRoleExtension on UserRole {
  /// Pode gerenciar outros administradores (mudar cargos)
  bool get canManageRoles => this == UserRole.adminMaster || this == UserRole.adminDev;
  
  /// Pode realizar manutenções e edições diretas em perfis alheios
  bool get canRunMaintenance => this == UserRole.adminDev;
  
  /// É qualquer tipo de administrador
  bool get isAdmin => this != UserRole.user;

  String get name {
    switch (this) {
      case UserRole.admin: return 'Administrador';
      case UserRole.adminMaster: return 'ADM Master';
      case UserRole.adminDev: return 'ADM DEV';
      case UserRole.user: return 'Usuário';
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.admin: return 'admin';
      case UserRole.adminMaster: return 'admin_master';
      case UserRole.adminDev: return 'admin_dev';
      case UserRole.user: return 'user';
    }
  }
}

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
    UserRole parsedRole;
    final String roleStr = data['role']?.toString() ?? 'user';
    
    // Fallback de segurança para o criador do sistema
    if (data['email'] == 'lucasmslima1@gmail.com') {
      parsedRole = UserRole.adminDev;
    } else {
      switch (roleStr) {
        case 'admin': parsedRole = UserRole.admin; break;
        case 'admin_master': parsedRole = UserRole.adminMaster; break;
        case 'admin_dev': parsedRole = UserRole.adminDev; break;
        default: parsedRole = UserRole.user;
      }
    }

    return AppUser(
      id: data['id']?.toString() ?? '',
      name: (data['name']?.toString().isNotEmpty == true)
          ? data['name']
          : (data['full_name']?.toString().isNotEmpty == true 
              ? data['full_name'] 
              : 'Usuário'),
      email: data['email'] ?? '',
      cpf: data['cpf'] ?? '',
      phone: data['phone'] ?? '',
      role: parsedRole,
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
      'role': role.dbValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'date_of_birth': dateOfBirth ?? '',
      'city': city ?? '',
      'state': state ?? '',
      'institution': institution ?? '',
      'gender': gender ?? '',
      'race': race ?? '',
      'social_name': socialName ?? '',
    };
  }
}
