class CardRequest {
  final String id;
  final String userId;
  final String memberId;
  final String type;
  final String status;
  final String protocol;
  final String adminNotes;
  final String driveFolderUrl;
  final String idPhotoUrl;
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
    required this.idPhotoUrl,
    required this.medicalReportUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CardRequest.fromJson(Map<String, dynamic> data) {
    return CardRequest(
      id: data['id']?.toString() ?? '',
      userId: data['userId'] ?? data['user_id'] ?? '',
      memberId: data['memberId'] ?? data['member_id'] ?? '',
      type: data['type'] ?? 'new_card',
      status: data['status'] ?? 'under_review',
      protocol: data['protocol'] ?? '',
      adminNotes: data['adminNotes'] ?? data['admin_notes'] ?? '',
      driveFolderUrl: data['driveFolderUrl'] ?? data['drive_folder_url'] ?? '',
      idPhotoUrl: data['idPhotoUrl'] ?? data['id_photo_url'] ?? '',
      medicalReportUrl: data['medicalReportUrl'] ?? data['medical_report_url'] ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : (data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now()),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt']) 
          : (data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now()),
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
      'id_photo_url': idPhotoUrl,
      'medical_report_url': medicalReportUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
