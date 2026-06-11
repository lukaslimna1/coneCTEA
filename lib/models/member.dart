
class Member {
  final String id;
  final String userId;
  final String name;
  final String cpf;
  final String city;
  final String state;
  final String phone;
  final String
  dateOfBirth; // Alterado de birthDate para dateOfBirth (String para alinhar com o AdminView)
  final String bloodType;
  final String cid;
  final String documentUrl;
  final String medicalReportUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gender;
  final String? racaCor;
  final String? socialName;
  final String? teaRelationType;
  final String? responsiblePersonName;
  final String? responsiblePhone;
  final String? emergencyPersonName;
  final String? emergencyPhone;

  Member({
    required this.id,
    required this.userId,
    required this.name,
    required this.cpf,
    required this.city,
    required this.state,
    required this.phone,
    required this.dateOfBirth,
    required this.bloodType,
    required this.cid,
    required this.documentUrl,
    required this.medicalReportUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.gender,
    this.racaCor,
    this.socialName,
    this.teaRelationType,
    this.responsiblePersonName,
    this.responsiblePhone,
    this.emergencyPersonName,
    this.emergencyPhone,
  });

  factory Member.empty() {
    return Member(
      id: '',
      userId: '',
      name: '',
      cpf: '',
      city: '',
      state: '',
      phone: '',
      dateOfBirth: '',
      bloodType: '',
      cid: '',
      documentUrl: '',
      medicalReportUrl: '',
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      gender: null,
      racaCor: null,
      socialName: null,
      teaRelationType: null,
      responsiblePersonName: null,
      responsiblePhone: null,
      emergencyPersonName: null,
      emergencyPhone: null,
    );
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      name: (json['name']?.toString().isNotEmpty == true)
          ? json['name']
          : (json['full_name']?.toString().isNotEmpty == true
                ? json['full_name']
                : ''),
      cpf: json['cpf'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      phone: json['phone'] ?? '',
      dateOfBirth:
          json['dateOfBirth'] ?? json['birth_date'] ?? json['birthDate'] ?? '',
      bloodType: json['bloodType'] ?? json['blood_type'] ?? '',
      cid: json['cid'] ?? '',
      documentUrl: json['documentUrl'] ?? json['document_url'] ?? '',
      medicalReportUrl:
          json['medicalReportUrl'] ?? json['medical_report_url'] ?? '',
      status: json['status'] ?? 'waiting_approval',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null
                ? DateTime.parse(json['updated_at'])
                : DateTime.now()),
      gender: json['gender']?.toString(),
      racaCor: json['raca_cor']?.toString() ?? json['racaCor']?.toString(),
      socialName: json['social_name'] ?? json['socialName'],
      teaRelationType:
          json['tea_relation_type']?.toString() ??
          json['teaRelationType']?.toString(),
      responsiblePersonName:
          json['responsible_person_name'] ?? json['responsiblePersonName'],
      responsiblePhone: json['responsible_phone'] ?? json['responsiblePhone'],
      emergencyPersonName:
          json['emergency_person_name'] ?? json['emergencyPersonName'],
      emergencyPhone: json['emergency_phone'] ?? json['emergencyPhone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'cpf': cpf,
      'city': city,
      'state': state,
      'phone': phone,
      'birth_date': dateOfBirth,
      'blood_type': bloodType,
      'cid': cid,
      'document_url': documentUrl,
      'medical_report_url': medicalReportUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'gender': gender,
      'raca_cor': racaCor,
      'social_name': socialName,
      'tea_relation_type': teaRelationType,
      'responsible_person_name': responsiblePersonName,
      'responsible_phone': responsiblePhone,
      'emergency_person_name': emergencyPersonName,
      'emergency_phone': emergencyPhone,
    };
  }

  Member copyWith({
    String? id,
    String? userId,
    String? name,
    String? cpf,
    String? city,
    String? state,
    String? phone,
    String? dateOfBirth,
    String? bloodType,
    String? cid,
    String? documentUrl,
    String? medicalReportUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gender,
    String? racaCor,
    String? socialName,
    String? teaRelationType,
    String? responsiblePersonName,
    String? responsiblePhone,
    String? emergencyPersonName,
    String? emergencyPhone,
  }) {
    return Member(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      city: city ?? this.city,
      state: state ?? this.state,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      cid: cid ?? this.cid,
      documentUrl: documentUrl ?? this.documentUrl,
      medicalReportUrl: medicalReportUrl ?? this.medicalReportUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      racaCor: racaCor ?? this.racaCor,
      socialName: socialName ?? this.socialName,
      teaRelationType: teaRelationType ?? this.teaRelationType,
      responsiblePersonName:
          responsiblePersonName ?? this.responsiblePersonName,
      responsiblePhone: responsiblePhone ?? this.responsiblePhone,
      emergencyPersonName: emergencyPersonName ?? this.emergencyPersonName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }

  String get initials {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'U';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  String get displayName =>
      (socialName != null && socialName!.trim().isNotEmpty)
      ? socialName!.trim()
      : name;

  bool get isSupportNetwork => teaRelationType == 'rede_apoio_tea';

  bool get isPessoaTea =>
      teaRelationType == null || teaRelationType == 'pessoa_tea';

  String get teaRelationLabel =>
      isSupportNetwork ? 'Rede de Apoio TEA' : 'Pessoa TEA';
}
