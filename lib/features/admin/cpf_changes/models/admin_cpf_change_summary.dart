import 'package:conectea/models/account_change_request.dart';

class AdminCpfChangeSummary {
  final String id;
  final String protocolNumber;
  final AccountChangeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? statusChangedAt;
  final DateTime? closedAt;
  final String? adminDeadlineDueDate;
  final String? holderDeadlineDueDate;
  final bool isOverdue;
  final int? remainingCalendarDays;
  final bool hasDocument;
  final String? oldValueMasked;
  final String? newValueMasked;
  final String userFirstName;
  final String userEmailMasked;

  const AdminCpfChangeSummary({
    required this.id,
    required this.protocolNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.statusChangedAt,
    this.closedAt,
    this.adminDeadlineDueDate,
    this.holderDeadlineDueDate,
    required this.isOverdue,
    this.remainingCalendarDays,
    required this.hasDocument,
    this.oldValueMasked,
    this.newValueMasked,
    required this.userFirstName,
    required this.userEmailMasked,
  });

  factory AdminCpfChangeSummary.fromJson(Map<String, dynamic> json) {
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

    String? parseLocalDateStr(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      return str.isEmpty ? null : str;
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
        case 'waiting_holder_confirmation':
          parsedStatus = AccountChangeStatus.waitingHolderConfirmation;
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

    return AdminCpfChangeSummary(
      id: rawId.trim(),
      protocolNumber: rawProtocol.trim(),
      status: parsedStatus,
      createdAt: parseRequiredDate(json['created_at'], 'created_at'),
      updatedAt: parseRequiredDate(json['updated_at'], 'updated_at'),
      statusChangedAt: parseOptionalDate(json['status_changed_at']),
      closedAt: parseOptionalDate(json['closed_at']),
      adminDeadlineDueDate: parseLocalDateStr(json['admin_deadline_due_date']),
      holderDeadlineDueDate: parseLocalDateStr(
        json['holder_deadline_due_date'],
      ),
      isOverdue: json['is_overdue'] as bool? ?? false,
      remainingCalendarDays: json['remaining_calendar_days'] as int?,
      hasDocument: json['has_document'] as bool? ?? false,
      oldValueMasked: json['old_value_masked'] as String?,
      newValueMasked: json['new_value_masked'] as String?,
      userFirstName: json['user_first_name'] as String? ?? 'Titular',
      userEmailMasked: json['user_email_masked'] as String? ?? '',
    );
  }
}
