class Member {
  final String id;
  final String userId;
  final String name;
  final String cpf;
  final String city;
  final String phone;
  final String emergencyContact;
  final String responsibleName;
  final String dateOfBirth; // Changed from birthDate to dateOfBirth (String to match AdminView usage)
  final String bloodType;
  final String cid;
  final String documentUrl;
  final String medicalReportUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    required this.id,
    required this.userId,
    required this.name,
    required this.cpf,
    required this.city,
    required this.phone,
    required this.emergencyContact,
    required this.responsibleName,
    required this.dateOfBirth,
    required this.bloodType,
    required this.cid,
    required this.documentUrl,
    required this.medicalReportUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      cpf: json['cpf'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      emergencyContact: json['emergencyContact'] ?? json['emergency_contact'] ?? '',
      responsibleName: json['responsibleName'] ?? json['responsible_name'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? json['birth_date'] ?? json['birthDate'] ?? '',
      bloodType: json['bloodType'] ?? json['blood_type'] ?? '',
      cid: json['cid'] ?? '',
      documentUrl: json['documentUrl'] ?? json['document_url'] ?? '',
      medicalReportUrl: json['medicalReportUrl'] ?? json['medical_report_url'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'cpf': cpf,
      'city': city,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'responsible_name': responsibleName,
      'birth_date': dateOfBirth,
      'blood_type': bloodType,
      'cid': cid,
      'document_url': documentUrl,
      'medical_report_url': medicalReportUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

