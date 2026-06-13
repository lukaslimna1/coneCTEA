enum AccountChangeType { email, cpf, unknown }

extension AccountChangeTypeExtension on AccountChangeType {
  String? get dbValue {
    switch (this) {
      case AccountChangeType.email:
        return 'email';
      case AccountChangeType.cpf:
        return 'cpf';
      case AccountChangeType.unknown:
        return null;
    }
  }
}

enum AccountChangeStatus {
  applying,
  completed,
  applicationFailed,
  waitingDocumentReplacement,
  underReview,
  waitingHolderConfirmation,
  rejectedByAdmin,
  cancelledByHolder,
  expired,
  unknown,
}

extension AccountChangeStatusExtension on AccountChangeStatus {
  String? get dbValue {
    switch (this) {
      case AccountChangeStatus.applying:
        return 'applying';
      case AccountChangeStatus.completed:
        return 'completed';
      case AccountChangeStatus.applicationFailed:
        return 'application_failed';
      case AccountChangeStatus.waitingDocumentReplacement:
        return 'waiting_document_replacement';
      case AccountChangeStatus.underReview:
        return 'under_review';
      case AccountChangeStatus.waitingHolderConfirmation:
        return 'waiting_holder_confirmation';
      case AccountChangeStatus.rejectedByAdmin:
        return 'rejected_by_admin';
      case AccountChangeStatus.cancelledByHolder:
        return 'cancelled_by_holder';
      case AccountChangeStatus.expired:
        return 'expired';
      case AccountChangeStatus.unknown:
        return null;
    }
  }
}

enum AccountChangeResolutionReason {
  cancelledDuringReview,
  cancelledWhileWaitingDocument,
  declinedFinalConfirmation,
  documentReplacementDeadline,
  holderConfirmationDeadline,
  unknown,
}

extension AccountChangeResolutionReasonExtension
    on AccountChangeResolutionReason {
  String? get dbValue {
    switch (this) {
      case AccountChangeResolutionReason.cancelledDuringReview:
        return 'cancelled_during_review';
      case AccountChangeResolutionReason.cancelledWhileWaitingDocument:
        return 'cancelled_while_waiting_document';
      case AccountChangeResolutionReason.declinedFinalConfirmation:
        return 'declined_final_confirmation';
      case AccountChangeResolutionReason.documentReplacementDeadline:
        return 'document_replacement_deadline';
      case AccountChangeResolutionReason.holderConfirmationDeadline:
        return 'holder_confirmation_deadline';
      case AccountChangeResolutionReason.unknown:
        return null;
    }
  }
}

enum AccountChangePublicAdminReasonCode {
  documentNotAccepted,
  unreadableDocument,
  cpfNotVisible,
  nameMismatch,
  birthDateMismatch,
  cpfMismatch,
  other,
  unknown,
}

extension AccountChangePublicAdminReasonCodeExtension
    on AccountChangePublicAdminReasonCode {
  String? get dbValue {
    switch (this) {
      case AccountChangePublicAdminReasonCode.documentNotAccepted:
        return 'document_not_accepted';
      case AccountChangePublicAdminReasonCode.unreadableDocument:
        return 'unreadable_document';
      case AccountChangePublicAdminReasonCode.cpfNotVisible:
        return 'cpf_not_visible';
      case AccountChangePublicAdminReasonCode.nameMismatch:
        return 'name_mismatch';
      case AccountChangePublicAdminReasonCode.birthDateMismatch:
        return 'birth_date_mismatch';
      case AccountChangePublicAdminReasonCode.cpfMismatch:
        return 'cpf_mismatch';
      case AccountChangePublicAdminReasonCode.other:
        return 'other';
      case AccountChangePublicAdminReasonCode.unknown:
        return null;
    }
  }
}

class AccountChangeCivilDate {
  final int year;
  final int month;
  final int day;

  const AccountChangeCivilDate._(this.year, this.month, this.day);

  factory AccountChangeCivilDate({
    required int year,
    required int month,
    required int day,
  }) {
    if (year < 1 || year > 9999) {
      throw const FormatException('Ano inválido na data civil.');
    }
    if (month < 1 || month > 12) {
      throw const FormatException('Mês inválido na data civil.');
    }

    final maxDays = _daysInMonth(year, month);
    if (day < 1 || day > maxDays) {
      throw const FormatException('Dia inválido na data civil.');
    }

    return AccountChangeCivilDate._(year, month, day);
  }

  factory AccountChangeCivilDate.parse(dynamic value) {
    if (value is! String) {
      throw const FormatException('O valor da data civil deve ser uma String.');
    }
    final trimmed = value.trim();
    final regex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final match = regex.firstMatch(trimmed);
    if (match == null) {
      throw const FormatException(
        'Formato de data civil inválido. Esperado YYYY-MM-DD.',
      );
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    return AccountChangeCivilDate(year: year, month: month, day: day);
  }

  static int _daysInMonth(int year, int month) {
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) {
      return 29;
    }
    return days[month];
  }

  static bool _isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  String toIso8601String() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  String toString() => toIso8601String();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountChangeCivilDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);
}

class AccountChangeRequest {
  final String id;
  final String protocolNumber;
  final AccountChangeType type;
  final AccountChangeStatus status;
  final String newValueMasked;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos opcionais
  final String? oldValueMasked;
  final String? justification;
  final DateTime? holderConfirmedAt;
  final DateTime? applicationStartedAt;
  final DateTime? applicationCompletedAt;

  // Novos campos públicos
  final DateTime? statusChangedAt;
  final DateTime? holderDeadlineStartedAt;
  final AccountChangeCivilDate? holderDeadlineDueDate;
  final DateTime? closedAt;
  final AccountChangeResolutionReason resolutionReason;
  final AccountChangePublicAdminReasonCode publicAdminReasonCode;
  final String? publicAdminFeedback;

  const AccountChangeRequest({
    required this.id,
    required this.protocolNumber,
    required this.type,
    required this.status,
    required this.newValueMasked,
    required this.createdAt,
    required this.updatedAt,
    this.oldValueMasked,
    this.justification,
    this.holderConfirmedAt,
    this.applicationStartedAt,
    this.applicationCompletedAt,
    this.statusChangedAt,
    this.holderDeadlineStartedAt,
    this.holderDeadlineDueDate,
    this.closedAt,
    this.resolutionReason = AccountChangeResolutionReason.unknown,
    this.publicAdminReasonCode = AccountChangePublicAdminReasonCode.unknown,
    this.publicAdminFeedback,
  });

  factory AccountChangeRequest.fromJson(Map<String, dynamic> json) {
    // 1. Validação estrita do id (obrigatório e não vazio)
    final rawId = json['id'];
    if (rawId == null || rawId is! String || rawId.trim().isEmpty) {
      throw const FormatException(
        'ID inválido ou ausente no JSON da requisição.',
      );
    }
    final String id = rawId.trim();

    // 2. Validação estrita do protocol_number (obrigatório e não vazio)
    final rawProtocolNumber = json['protocol_number'] ?? json['protocolNumber'];
    if (rawProtocolNumber == null ||
        rawProtocolNumber is! String ||
        rawProtocolNumber.trim().isEmpty) {
      throw const FormatException(
        'protocol_number inválido ou ausente no JSON da requisição.',
      );
    }
    final String protocolNumber = rawProtocolNumber.trim();

    // 3. Validação estrita do new_value_masked (exigir String, trim, rejeitar vazia ou só espaços)
    final rawNewValueMasked =
        json['new_value_masked'] ?? json['newValueMasked'];
    if (rawNewValueMasked == null || rawNewValueMasked is! String) {
      throw const FormatException('newValueMasked inválido ou ausente.');
    }
    final String newValueMasked = rawNewValueMasked.trim();
    if (newValueMasked.isEmpty) {
      throw const FormatException('newValueMasked inválido ou ausente.');
    }

    // 4. Parsing de datas obrigatórias
    DateTime parseRequiredDate(dynamic val, String fieldName) {
      if (val == null) {
        throw FormatException('$fieldName é obrigatório.');
      }
      try {
        if (val is DateTime) return val.toUtc();
        return DateTime.parse(val.toString()).toUtc();
      } catch (e) {
        throw FormatException('$fieldName possui formato inválido.');
      }
    }

    final DateTime createdAt = parseRequiredDate(
      json['created_at'] ?? json['createdAt'],
      'created_at',
    );
    final DateTime updatedAt = parseRequiredDate(
      json['updated_at'] ?? json['updatedAt'],
      'updated_at',
    );

    // 5. Parsing de datas opcionais (exigir String ou DateTime, lançar FormatException se inválido/tipo errado)
    DateTime? parseOptionalDate(dynamic val, String fieldName) {
      if (val == null) return null;
      if (val is DateTime) return val.toUtc();
      if (val is! String) {
        throw FormatException('$fieldName possui tipo inválido.');
      }
      try {
        return DateTime.parse(val).toUtc();
      } catch (_) {
        throw FormatException('$fieldName possui formato de data inválido.');
      }
    }

    final DateTime? holderConfirmedAt = parseOptionalDate(
      json['holder_confirmed_at'] ?? json['holderConfirmedAt'],
      'holder_confirmed_at',
    );
    final DateTime? applicationStartedAt = parseOptionalDate(
      json['application_started_at'] ?? json['applicationStartedAt'],
      'application_started_at',
    );
    final DateTime? applicationCompletedAt = parseOptionalDate(
      json['application_completed_at'] ?? json['applicationCompletedAt'],
      'application_completed_at',
    );

    final DateTime? statusChangedAt = parseOptionalDate(
      json['status_changed_at'] ?? json['statusChangedAt'],
      'status_changed_at',
    );
    final DateTime? holderDeadlineStartedAt = parseOptionalDate(
      json['holder_deadline_started_at'] ?? json['holderDeadlineStartedAt'],
      'holder_deadline_started_at',
    );
    final DateTime? closedAt = parseOptionalDate(
      json['closed_at'] ?? json['closedAt'],
      'closed_at',
    );

    final rawHolderDeadlineDueDate =
        json['holder_deadline_due_date'] ?? json['holderDeadlineDueDate'];
    final AccountChangeCivilDate? holderDeadlineDueDate =
        rawHolderDeadlineDueDate != null
        ? AccountChangeCivilDate.parse(rawHolderDeadlineDueDate)
        : null;

    // 6. Parsing seguro do AccountChangeType
    final String rawTypeStr = (json['type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    AccountChangeType type;
    switch (rawTypeStr) {
      case 'email':
        type = AccountChangeType.email;
        break;
      case 'cpf':
        type = AccountChangeType.cpf;
        break;
      default:
        type = AccountChangeType.unknown;
    }

    // 7. Parsing seguro do AccountChangeStatus
    final String rawStatusStr = (json['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    AccountChangeStatus status;
    switch (rawStatusStr) {
      case 'applying':
        status = AccountChangeStatus.applying;
        break;
      case 'completed':
        status = AccountChangeStatus.completed;
        break;
      case 'application_failed':
      case 'applicationfailed':
        status = AccountChangeStatus.applicationFailed;
        break;
      case 'under_review':
      case 'underreview':
        status = AccountChangeStatus.underReview;
        break;
      case 'waiting_holder_confirmation':
      case 'waitingholderconfirmation':
        status = AccountChangeStatus.waitingHolderConfirmation;
        break;
      case 'rejected_by_admin':
      case 'rejectedbyadmin':
        status = AccountChangeStatus.rejectedByAdmin;
        break;
      case 'cancelled_by_holder':
      case 'cancelledbyholder':
        status = AccountChangeStatus.cancelledByHolder;
        break;
      case 'waiting_document_replacement':
      case 'waitingdocumentreplacement':
        status = AccountChangeStatus.waitingDocumentReplacement;
        break;
      case 'expired':
        status = AccountChangeStatus.expired;
        break;
      default:
        status = AccountChangeStatus.unknown;
    }

    // parsing de resolution_reason
    final String rawResolutionReasonStr =
        (json['resolution_reason'] ?? json['resolutionReason'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    AccountChangeResolutionReason resolutionReason;
    switch (rawResolutionReasonStr) {
      case 'cancelled_during_review':
      case 'cancelledduringreview':
        resolutionReason = AccountChangeResolutionReason.cancelledDuringReview;
        break;
      case 'cancelled_while_waiting_document':
      case 'cancelledwhilewaitingdocument':
        resolutionReason =
            AccountChangeResolutionReason.cancelledWhileWaitingDocument;
        break;
      case 'declined_final_confirmation':
      case 'declinedfinalconfirmation':
        resolutionReason =
            AccountChangeResolutionReason.declinedFinalConfirmation;
        break;
      case 'document_replacement_deadline':
      case 'documentreplacementdeadline':
        resolutionReason =
            AccountChangeResolutionReason.documentReplacementDeadline;
        break;
      case 'holder_confirmation_deadline':
      case 'holderconfirmationdeadline':
        resolutionReason =
            AccountChangeResolutionReason.holderConfirmationDeadline;
        break;
      default:
        resolutionReason = AccountChangeResolutionReason.unknown;
    }

    // parsing de public_admin_reason_code
    final String rawPublicAdminReasonCodeStr =
        (json['public_admin_reason_code'] ??
                json['publicAdminReasonCode'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
    AccountChangePublicAdminReasonCode publicAdminReasonCode;
    switch (rawPublicAdminReasonCodeStr) {
      case 'document_not_accepted':
      case 'documentnotaccepted':
        publicAdminReasonCode =
            AccountChangePublicAdminReasonCode.documentNotAccepted;
        break;
      case 'unreadable_document':
      case 'unreadabledocument':
        publicAdminReasonCode =
            AccountChangePublicAdminReasonCode.unreadableDocument;
        break;
      case 'cpf_not_visible':
      case 'cpfnotvisible':
        publicAdminReasonCode =
            AccountChangePublicAdminReasonCode.cpfNotVisible;
        break;
      case 'name_mismatch':
      case 'namemismatch':
        publicAdminReasonCode = AccountChangePublicAdminReasonCode.nameMismatch;
        break;
      case 'birth_date_mismatch':
      case 'birthdatemismatch':
        publicAdminReasonCode =
            AccountChangePublicAdminReasonCode.birthDateMismatch;
        break;
      case 'cpf_mismatch':
      case 'cpfmismatch':
        publicAdminReasonCode = AccountChangePublicAdminReasonCode.cpfMismatch;
        break;
      case 'other':
        publicAdminReasonCode = AccountChangePublicAdminReasonCode.other;
        break;
      default:
        publicAdminReasonCode = AccountChangePublicAdminReasonCode.unknown;
    }

    final rawPublicAdminFeedback =
        json['public_admin_feedback'] ?? json['publicAdminFeedback'];
    String? publicAdminFeedback;
    if (rawPublicAdminFeedback != null) {
      if (rawPublicAdminFeedback is! String) {
        throw const FormatException(
          'public_admin_feedback deve ser do tipo String.',
        );
      }
      final trimmed = rawPublicAdminFeedback.trim();
      publicAdminFeedback = trimmed.isEmpty ? null : trimmed;
    }

    // Helpers opcionais
    String? parseNullableString(dynamic val) {
      if (val == null) return null;
      return val.toString();
    }

    final String? oldValueMasked = parseNullableString(
      json['old_value_masked'] ?? json['oldValueMasked'],
    );
    final String? justification = parseNullableString(json['justification']);

    return AccountChangeRequest(
      id: id,
      protocolNumber: protocolNumber,
      type: type,
      status: status,
      newValueMasked: newValueMasked,
      createdAt: createdAt,
      updatedAt: updatedAt,
      oldValueMasked: oldValueMasked,
      justification: justification,
      holderConfirmedAt: holderConfirmedAt,
      applicationStartedAt: applicationStartedAt,
      applicationCompletedAt: applicationCompletedAt,
      statusChangedAt: statusChangedAt,
      holderDeadlineStartedAt: holderDeadlineStartedAt,
      holderDeadlineDueDate: holderDeadlineDueDate,
      closedAt: closedAt,
      resolutionReason: resolutionReason,
      publicAdminReasonCode: publicAdminReasonCode,
      publicAdminFeedback: publicAdminFeedback,
    );
  }
}
