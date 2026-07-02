class DependentCpfChangeRequest {
  final String id;
  final String userId;
  final String memberId;
  final String status;
  final String protocolNumber;
  final String? currentCpfMasked;
  final String? requestedCpfMasked;
  final String? documentReferenceMasked;
  final String? adminFeedback;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  DependentCpfChangeRequest({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.status,
    required this.protocolNumber,
    this.currentCpfMasked,
    this.requestedCpfMasked,
    this.documentReferenceMasked,
    this.adminFeedback,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.completedAt,
  });

  factory DependentCpfChangeRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    DateTime parseRequiredDate(dynamic value) {
      final parsed = parseDate(value);
      if (parsed == null) {
        throw const FormatException('Data obrigatória inválida ou nula.');
      }
      return parsed;
    }

    return DependentCpfChangeRequest(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'under_review',
      protocolNumber: json['protocol_number'] ?? json['protocolNumber'] ?? '',
      currentCpfMasked: json['current_cpf_masked'] ?? json['currentCpfMasked'],
      requestedCpfMasked: json['requested_cpf_masked'] ?? json['requestedCpfMasked'],
      documentReferenceMasked: json['document_reference_masked'] ?? json['documentReferenceMasked'],
      adminFeedback: json['admin_feedback'] ?? json['adminFeedback'],
      expiresAt: parseDate(json['expires_at'] ?? json['expiresAt']),
      createdAt: parseRequiredDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseRequiredDate(json['updated_at'] ?? json['updatedAt']),
      cancelledAt: parseDate(json['cancelled_at'] ?? json['cancelledAt']),
      completedAt: parseDate(json['completed_at'] ?? json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'member_id': memberId,
      'status': status,
      'protocol_number': protocolNumber,
      'current_cpf_masked': currentCpfMasked,
      'requested_cpf_masked': requestedCpfMasked,
      'document_reference_masked': documentReferenceMasked,
      'admin_feedback': adminFeedback,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
