import 'package:conectea/models/account_change_request.dart';

class AdminDependentCpfChangeSensitiveReview {
  final bool canView;
  final String requestId;
  final AccountChangeStatus status;
  final String? oldCpfClear;
  final String? newCpfClear;
  final String documentState;
  final bool canViewDocument;
  final String? documentFileId;
  final DateTime? serverNow;

  const AdminDependentCpfChangeSensitiveReview({
    required this.canView,
    required this.requestId,
    required this.status,
    this.oldCpfClear,
    this.newCpfClear,
    required this.documentState,
    required this.canViewDocument,
    this.documentFileId,
    this.serverNow,
  });

  factory AdminDependentCpfChangeSensitiveReview.fromJson(Map<String, dynamic> json) {
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

    final rawServerNow = json['server_now'];
    final serverNow = rawServerNow != null
        ? DateTime.parse(rawServerNow.toString())
        : null;

    return AdminDependentCpfChangeSensitiveReview(
      canView: json['can_view'] as bool? ?? false,
      requestId: json['request_id'] as String? ?? '',
      status: parsedStatus,
      oldCpfClear: json['old_cpf_clear'] as String?,
      newCpfClear: json['new_cpf_clear'] as String?,
      documentState: json['document_state'] as String? ?? 'unavailable',
      canViewDocument: json['can_view_document'] as bool? ?? false,
      documentFileId: json['document_file_id'] as String?,
      serverNow: serverNow,
    );
  }
}
