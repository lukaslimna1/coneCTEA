import 'package:conectea/models/account_change_request.dart';

class AdminDependentCpfChangeSummary {
  final String id;
  final String protocolNumber;
  final AccountChangeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String userId;
  final String memberId;
  final String currentCpfMasked;
  final String requestedCpfMasked;
  final String documentReferenceMasked;
  final String? adminFeedback;
  final bool hasDocument;
  final String userFirstName;
  final String userEmailMasked;
  final String dependentFirstName;
  final String dependentFullName;

  const AdminDependentCpfChangeSummary({
    required this.id,
    required this.protocolNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.completedAt,
    this.cancelledAt,
    required this.userId,
    required this.memberId,
    required this.currentCpfMasked,
    required this.requestedCpfMasked,
    required this.documentReferenceMasked,
    this.adminFeedback,
    required this.hasDocument,
    required this.userFirstName,
    required this.userEmailMasked,
    required this.dependentFirstName,
    required this.dependentFullName,
  });

  factory AdminDependentCpfChangeSummary.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    if (rawId == null || rawId.trim().isEmpty) {
      throw const FormatException('ID inválido no resumo da alteração.');
    }

    final rawProtocol = json['protocol_number'] as String?;
    if (rawProtocol == null || rawProtocol.trim().isEmpty) {
      throw const FormatException('protocol_number inválido no resumo.');
    }

    DateTime parseRequiredDate(dynamic val, String fieldName) {
      if (val == null) {
        throw FormatException('$fieldName é obrigatório.');
      }
      if (val is DateTime) return val;
      return DateTime.parse(val.toString());
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.parse(val.toString());
    }

    final rawStatus = json['status'] as String?;
    AccountChangeStatus parsedStatus = AccountChangeStatus.unknown;
    if (rawStatus != null) {
      final statusLower = rawStatus.trim().toLowerCase();
      switch (statusLower) {
        case 'applying':
          parsedStatus = AccountChangeStatus.applying;
          break;
        case 'completed':
          parsedStatus = AccountChangeStatus.completed;
          break;
        case 'application_failed':
          parsedStatus = AccountChangeStatus.applicationFailed;
          break;
        case 'under_review':
          parsedStatus = AccountChangeStatus.underReview;
          break;
        case 'rejected_by_admin':
          parsedStatus = AccountChangeStatus.rejectedByAdmin;
          break;
        case 'cancelled_by_holder':
          parsedStatus = AccountChangeStatus.cancelledByHolder;
          break;
        case 'expired':
          parsedStatus = AccountChangeStatus.expired;
          break;
        case 'waiting_cpf_correction':
          parsedStatus = AccountChangeStatus.waitingCpfCorrection;
          break;
        case 'waiting_document_replacement':
          parsedStatus = AccountChangeStatus.waitingDocumentReplacement;
          break;
      }
    }

    return AdminDependentCpfChangeSummary(
      id: rawId.trim(),
      protocolNumber: rawProtocol.trim(),
      status: parsedStatus,
      createdAt: parseRequiredDate(json['created_at'], 'created_at'),
      updatedAt: parseRequiredDate(json['updated_at'], 'updated_at'),
      expiresAt: parseOptionalDate(json['expires_at']),
      completedAt: parseOptionalDate(json['completed_at']),
      cancelledAt: parseOptionalDate(json['cancelled_at']),
      userId: json['user_id'] as String? ?? '',
      memberId: json['member_id'] as String? ?? '',
      currentCpfMasked: json['current_cpf_masked'] as String? ?? '',
      requestedCpfMasked: json['requested_cpf_masked'] as String? ?? '',
      documentReferenceMasked: json['document_reference_masked'] as String? ?? '',
      adminFeedback: json['admin_feedback'] as String?,
      hasDocument: json['has_document'] as bool? ?? false,
      userFirstName: json['user_first_name'] as String? ?? 'Titular',
      userEmailMasked: json['user_email_masked'] as String? ?? '',
      dependentFirstName: json['dependent_first_name'] as String? ?? 'Dependente',
      dependentFullName: json['dependent_full_name'] as String? ?? 'Dependente',
    );
  }
}
