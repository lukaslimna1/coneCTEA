class CardRequest {
  final String id;
  final String userId;
  final String memberId;
  final String type;
  final String status;
  final String protocol;
  final String adminNotes;
  final String driveFolderUrl;
  final String documentUrl;
  final String medicalReportUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CardRequest({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.type,
    required this.status,
    required this.protocol,
    required this.adminNotes,
    required this.driveFolderUrl,
    required this.documentUrl,
    required this.medicalReportUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardRequest.fromJson(Map<String, dynamic> data) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return CardRequest(
      id: data['id']?.toString() ?? '',
      userId: data['user_id'] ?? data['userId'] ?? '',
      memberId: data['member_id'] ?? data['memberId'] ?? '',
      type: data['type'] ?? 'Primeira via',
      status: data['status'] ?? 'waiting_approval',
      protocol: data['protocol'] ?? '',
      adminNotes: data['admin_notes'] ?? data['adminNotes'] ?? '',
      driveFolderUrl: data['drive_folder_url'] ?? data['driveFolderUrl'] ?? '',
      documentUrl: data['document_url'] ?? data['documentUrl'] ?? data['id_photo_url'] ?? data['idPhotoUrl'] ?? '',
      medicalReportUrl: data['medical_report_url'] ?? data['medicalReportUrl'] ?? '',
      createdAt: parseDate(data['created_at'] ?? data['createdAt']),
      updatedAt: parseDate(data['updated_at'] ?? data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'member_id': memberId,
      'type': type,
      'status': status,
      'protocol': protocol,
      'admin_notes': adminNotes,
      'drive_folder_url': driveFolderUrl,
      'document_url': documentUrl,
      'medical_report_url': medicalReportUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CardRequest copyWith({
    String? id,
    String? userId,
    String? memberId,
    String? type,
    String? status,
    String? protocol,
    String? adminNotes,
    String? driveFolderUrl,
    String? documentUrl,
    String? medicalReportUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CardRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberId: memberId ?? this.memberId,
      type: type ?? this.type,
      status: status ?? this.status,
      protocol: protocol ?? this.protocol,
      adminNotes: adminNotes ?? this.adminNotes,
      driveFolderUrl: driveFolderUrl ?? this.driveFolderUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      medicalReportUrl: medicalReportUrl ?? this.medicalReportUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
