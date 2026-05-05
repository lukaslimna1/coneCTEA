enum RequestStatus {
  pending, // em análise
  waitingContact, // aguardando contato
  approved, // aprovado
  rejected, // recusado
  expired, // vencido
  needsRenewal, // renovação necessária
}

class IDRequest {
  final String id;
  final String userId;
  final String applicantName;
  final String birthDate;
  final String city;
  final String institution;
  final RequestStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final String? cardNumber;
  final DateTime? expiryDate;

  IDRequest({
    required this.id,
    required this.userId,
    required this.applicantName,
    required this.birthDate,
    required this.city,
    required this.institution,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.cardNumber,
    this.expiryDate,
  });

  factory IDRequest.fromJson(Map<String, dynamic> json) {
    return IDRequest(
      id: json['id'],
      userId: json['user_id'],
      applicantName: json['applicant_name'],
      birthDate: json['birth_date'],
      city: json['city'],
      institution: json['institution'],
      status: _statusFromString(json['status']),
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at']),
      cardNumber: json['card_number'],
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
    );
  }

  static RequestStatus _statusFromString(String status) {
    switch (status) {
      case 'waiting_contact': return RequestStatus.waitingContact;
      case 'approved': return RequestStatus.approved;
      case 'rejected': return RequestStatus.rejected;
      case 'expired': return RequestStatus.expired;
      case 'needs_renewal': return RequestStatus.needsRenewal;
      default: return RequestStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending: return 'Em análise';
      case RequestStatus.waitingContact: return 'Aguardando contato';
      case RequestStatus.approved: return 'Aprovado';
      case RequestStatus.rejected: return 'Recusado';
      case RequestStatus.expired: return 'Vencido';
      case RequestStatus.needsRenewal: return 'Renovação necessária';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'applicant_name': applicantName,
      'birth_date': birthDate,
      'city': city,
      'institution': institution,
      'status': statusToString(status),
      'admin_notes': adminNotes,
      'card_number': cardNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.waitingContact: return 'waiting_contact';
      case RequestStatus.approved: return 'approved';
      case RequestStatus.rejected: return 'rejected';
      case RequestStatus.expired: return 'expired';
      case RequestStatus.needsRenewal: return 'needs_renewal';
      default: return 'pending';
    }
  }
}
