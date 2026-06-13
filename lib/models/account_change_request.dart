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
    );
  }
}
