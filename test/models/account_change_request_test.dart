import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/models/account_change_request.dart';

void main() {
  group('AccountChangeRequest Model Tests', () {
    final Map<String, dynamic> validBaseJson = {
      'id': '6bf571f0-c0ec-4543-81fe-1f3f032d7c5c',
      'protocol_number': 'AC-20260612-A1B2C3D4',
      'type': 'email',
      'status': 'waiting_holder_confirmation',
      'new_value_masked': 'us***@domain.com',
      'created_at': '2026-06-12T18:00:00Z',
      'updated_at': '2026-06-12T18:30:00Z',
    };

    test('1. Parsing da resposta com campos comuns obrigatórios', () {
      final request = AccountChangeRequest.fromJson(validBaseJson);
      expect(request.id, '6bf571f0-c0ec-4543-81fe-1f3f032d7c5c');
      expect(request.protocolNumber, 'AC-20260612-A1B2C3D4');
      expect(request.type, AccountChangeType.email);
      expect(request.status, AccountChangeStatus.waitingHolderConfirmation);
      expect(request.newValueMasked, 'us***@domain.com');
      expect(request.createdAt, DateTime.parse('2026-06-12T18:00:00Z').toUtc());
      expect(request.updatedAt, DateTime.parse('2026-06-12T18:30:00Z').toUtc());
    });

    test('2. Parsing do detalhe com todos os campos opcionais preenchidos', () {
      final detailJson = Map<String, dynamic>.from(validBaseJson)
        ..addAll({
          'old_value_masked': 'old***@domain.com',
          'justification': 'Alteração de e-mail principal',
          'holder_confirmed_at': '2026-06-12T18:05:00Z',
          'application_started_at': '2026-06-12T18:10:00Z',
          'application_completed_at': '2026-06-12T18:15:00Z',
        });

      final request = AccountChangeRequest.fromJson(detailJson);
      expect(request.oldValueMasked, 'old***@domain.com');
      expect(request.justification, 'Alteração de e-mail principal');
      expect(
        request.holderConfirmedAt,
        DateTime.parse('2026-06-12T18:05:00Z').toUtc(),
      );
      expect(
        request.applicationStartedAt,
        DateTime.parse('2026-06-12T18:10:00Z').toUtc(),
      );
      expect(
        request.applicationCompletedAt,
        DateTime.parse('2026-06-12T18:15:00Z').toUtc(),
      );
    });

    test('3. Campos opcionais ausentes permanecem nulos no model', () {
      final request = AccountChangeRequest.fromJson(validBaseJson);
      expect(request.oldValueMasked, isNull);
      expect(request.justification, isNull);
      expect(request.holderConfirmedAt, isNull);
      expect(request.applicationStartedAt, isNull);
      expect(request.applicationCompletedAt, isNull);
    });

    test('4. Mapeamento de type para email', () {
      final json = Map<String, dynamic>.from(validBaseJson)..['type'] = 'email';
      final request = AccountChangeRequest.fromJson(json);
      expect(request.type, AccountChangeType.email);
    });

    test('5. Mapeamento de type para cpf', () {
      final json = Map<String, dynamic>.from(validBaseJson)..['type'] = 'cpf';
      final request = AccountChangeRequest.fromJson(json);
      expect(request.type, AccountChangeType.cpf);
    });

    test('6. Mapeamento de type desconhecido ou inválido para unknown', () {
      final jsonInvalid = Map<String, dynamic>.from(validBaseJson)
        ..['type'] = 'invalid_type';
      final jsonNull = Map<String, dynamic>.from(validBaseJson)..remove('type');

      expect(
        AccountChangeRequest.fromJson(jsonInvalid).type,
        AccountChangeType.unknown,
      );
      expect(
        AccountChangeRequest.fromJson(jsonNull).type,
        AccountChangeType.unknown,
      );
    });

    test('7. Mapeamento de todos os statuses válidos', () {
      final statuses = {
        'applying': AccountChangeStatus.applying,
        'completed': AccountChangeStatus.completed,
        'application_failed': AccountChangeStatus.applicationFailed,
        'waiting_document_replacement':
            AccountChangeStatus.waitingDocumentReplacement,
        'under_review': AccountChangeStatus.underReview,
        'waiting_holder_confirmation':
            AccountChangeStatus.waitingHolderConfirmation,
        'rejected_by_admin': AccountChangeStatus.rejectedByAdmin,
        'cancelled_by_holder': AccountChangeStatus.cancelledByHolder,
        'expired': AccountChangeStatus.expired,
      };

      for (final entry in statuses.entries) {
        final json = Map<String, dynamic>.from(validBaseJson)
          ..['status'] = entry.key;
        final request = AccountChangeRequest.fromJson(json);
        expect(
          request.status,
          entry.value,
          reason: 'Falha ao mapear status: ${entry.key}',
        );
      }
    });

    test('8. Status desconhecido ou inválido mapeia para unknown', () {
      final jsonInvalid = Map<String, dynamic>.from(validBaseJson)
        ..['status'] = 'invalid_status';
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..remove('status');

      expect(
        AccountChangeRequest.fromJson(jsonInvalid).status,
        AccountChangeStatus.unknown,
      );
      expect(
        AccountChangeRequest.fromJson(jsonNull).status,
        AccountChangeStatus.unknown,
      );
    });

    test(
      '9. Timestamps obrigatórios createdAt e updatedAt são convertidos para DateTime UTC',
      () {
        final json = Map<String, dynamic>.from(validBaseJson)
          ..['created_at'] =
              '2026-06-12T15:00:00-03:00' // Horário SP/DF (-3)
          ..['updated_at'] = '2026-06-12T15:30:00-03:00';

        final request = AccountChangeRequest.fromJson(json);
        expect(request.createdAt.isUtc, isTrue);
        expect(request.updatedAt.isUtc, isTrue);
        expect(request.createdAt, DateTime.parse('2026-06-12T18:00:00Z'));
        expect(request.updatedAt, DateTime.parse('2026-06-12T18:30:00Z'));
      },
    );

    test(
      '10. Timestamps opcionais válidos são convertidos para DateTime UTC',
      () {
        final json = Map<String, dynamic>.from(validBaseJson)
          ..['holder_confirmed_at'] = '2026-06-12T15:05:00-03:00'
          ..['application_started_at'] = '2026-06-12T15:10:00-03:00'
          ..['application_completed_at'] = '2026-06-12T15:15:00-03:00';

        final request = AccountChangeRequest.fromJson(json);
        expect(request.holderConfirmedAt!.isUtc, isTrue);
        expect(request.applicationStartedAt!.isUtc, isTrue);
        expect(request.applicationCompletedAt!.isUtc, isTrue);
        expect(
          request.holderConfirmedAt,
          DateTime.parse('2026-06-12T18:05:00Z'),
        );
        expect(
          request.applicationStartedAt,
          DateTime.parse('2026-06-12T18:10:00Z'),
        );
        expect(
          request.applicationCompletedAt,
          DateTime.parse('2026-06-12T18:15:00Z'),
        );
      },
    );

    test('11. ID ausente ou vazio gera FormatException', () {
      final jsonNull = Map<String, dynamic>.from(validBaseJson)..remove('id');
      final jsonEmpty = Map<String, dynamic>.from(validBaseJson)
        ..['id'] = '   ';

      expect(
        () => AccountChangeRequest.fromJson(jsonNull),
        throwsFormatException,
      );
      expect(
        () => AccountChangeRequest.fromJson(jsonEmpty),
        throwsFormatException,
      );
    });

    test('12. protocol_number ausente ou vazio gera FormatException', () {
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..remove('protocol_number');
      final jsonEmpty = Map<String, dynamic>.from(validBaseJson)
        ..['protocol_number'] = '';

      expect(
        () => AccountChangeRequest.fromJson(jsonNull),
        throwsFormatException,
      );
      expect(
        () => AccountChangeRequest.fromJson(jsonEmpty),
        throwsFormatException,
      );
    });

    test('13. new_value_masked ausente ou inválido gera FormatException', () {
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..remove('new_value_masked');
      final jsonType = Map<String, dynamic>.from(validBaseJson)
        ..['new_value_masked'] = 12345;

      expect(
        () => AccountChangeRequest.fromJson(jsonNull),
        throwsFormatException,
      );
      expect(
        () => AccountChangeRequest.fromJson(jsonType),
        throwsFormatException,
      );
    });

    test('14. created_at inválido ou ausente gera FormatException', () {
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..remove('created_at');
      final jsonInvalid = Map<String, dynamic>.from(validBaseJson)
        ..['created_at'] = 'not-a-date';

      expect(
        () => AccountChangeRequest.fromJson(jsonNull),
        throwsFormatException,
      );
      expect(
        () => AccountChangeRequest.fromJson(jsonInvalid),
        throwsFormatException,
      );
    });

    test('15. updated_at inválido ou ausente gera FormatException', () {
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..remove('updated_at');
      final jsonInvalid = Map<String, dynamic>.from(validBaseJson)
        ..['updated_at'] = 'not-a-date';

      expect(
        () => AccountChangeRequest.fromJson(jsonNull),
        throwsFormatException,
      );
      expect(
        () => AccountChangeRequest.fromJson(jsonInvalid),
        throwsFormatException,
      );
    });

    test(
      '16. Chaves extras e sensíveis do payload são ignoradas no mapping',
      () {
        final payloadExtra = Map<String, dynamic>.from(validBaseJson)
          ..addAll({
            'user_id': '6bf571f0-c0ec-4543-81fe-1f3f032d7c5c',
            'new_value_hmac': 'abcdef1234567890',
            'document_reference': 'https://drive.google.com/doc',
            'document_state': 'valid',
            'admin_id': 'b1bc111b-1283-4af3-85cc-79eb848f359e',
            'admin_feedback': 'Rejeitado por dados inconsistentes',
            'failure_code': 'LIMIT_EXCEEDED',
            'idempotency_key': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
            'extra_key_not_mapped': 'hello_world',
          });

        final request = AccountChangeRequest.fromJson(payloadExtra);
        expect(request.id, '6bf571f0-c0ec-4543-81fe-1f3f032d7c5c');
        expect(request.protocolNumber, 'AC-20260612-A1B2C3D4');
      },
    );

    // --- CORREÇÃO 1: TESTES DE NEW_VALUE_MASKED ---
    test('17. new_value_masked null gera FormatException', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..['new_value_masked'] = null;
      expect(() => AccountChangeRequest.fromJson(json), throwsFormatException);
    });

    test('18. new_value_masked vazio gera FormatException', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..['new_value_masked'] = '';
      expect(() => AccountChangeRequest.fromJson(json), throwsFormatException);
    });

    test('19. new_value_masked apenas com espaços gera FormatException', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..['new_value_masked'] = '     ';
      expect(() => AccountChangeRequest.fromJson(json), throwsFormatException);
    });

    test(
      '20. new_value_masked com espaços externos é normalizado por trim',
      () {
        final json = Map<String, dynamic>.from(validBaseJson)
          ..['new_value_masked'] = '  us***@domain.com  ';
        final request = AccountChangeRequest.fromJson(json);
        expect(request.newValueMasked, 'us***@domain.com');
      },
    );

    // --- CORREÇÃO 2: TESTES DE TIMESTAMPS OPCIONAIS ---
    test('21. Timestamps opcionais null não geram erro e permanecem null', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..['holder_confirmed_at'] = null
        ..['application_started_at'] = null
        ..['application_completed_at'] = null;

      final request = AccountChangeRequest.fromJson(json);
      expect(request.holderConfirmedAt, isNull);
      expect(request.applicationStartedAt, isNull);
      expect(request.applicationCompletedAt, isNull);
    });

    test(
      '22. Timestamps opcionais presentes, mas de tipo inválido, geram FormatException',
      () {
        final jsonTypeInt = Map<String, dynamic>.from(validBaseJson)
          ..['holder_confirmed_at'] = 123456789;
        final jsonTypeBool = Map<String, dynamic>.from(validBaseJson)
          ..['application_started_at'] = true;

        expect(
          () => AccountChangeRequest.fromJson(jsonTypeInt),
          throwsFormatException,
        );
        expect(
          () => AccountChangeRequest.fromJson(jsonTypeBool),
          throwsFormatException,
        );
      },
    );

    test(
      '23. Timestamps opcionais presentes, mas com formato string inválido, geram FormatException',
      () {
        final jsonInvalidString = Map<String, dynamic>.from(validBaseJson)
          ..['application_completed_at'] = 'invalid-timestamp-string';
        expect(
          () => AccountChangeRequest.fromJson(jsonInvalidString),
          throwsFormatException,
        );
      },
    );

    // --- CORREÇÃO 3: TESTES DE UNKNOWN E DBVALUE ---
    test(
      '24. dbValue de unknown em AccountChangeType e AccountChangeStatus retorna null',
      () {
        expect(AccountChangeType.unknown.dbValue, isNull);
        expect(AccountChangeStatus.unknown.dbValue, isNull);
      },
    );

    test('25. dbValue de valores válidos retorna string correta', () {
      expect(AccountChangeType.email.dbValue, 'email');
      expect(AccountChangeType.cpf.dbValue, 'cpf');
      expect(AccountChangeStatus.applying.dbValue, 'applying');
      expect(AccountChangeStatus.completed.dbValue, 'completed');
      expect(
        AccountChangeStatus.waitingDocumentReplacement.dbValue,
        'waiting_document_replacement',
      );
      expect(AccountChangeStatus.expired.dbValue, 'expired');
    });

    test('26. waiting_proof e waitingproof obsoletos mapeiam para unknown', () {
      final json1 = Map<String, dynamic>.from(validBaseJson)
        ..['status'] = 'waiting_proof';
      final json2 = Map<String, dynamic>.from(validBaseJson)
        ..['status'] = 'waitingproof';

      expect(
        AccountChangeRequest.fromJson(json1).status,
        AccountChangeStatus.unknown,
      );
      expect(
        AccountChangeRequest.fromJson(json2).status,
        AccountChangeStatus.unknown,
      );
    });

    // --- NOVOS TESTES DA MICROFRENTE 3C.5A (CAMPOS PÚBLICOS E DATA CIVIL) ---
    test('27. Parsing integrado de todos os novos campos no JSON', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..addAll({
          'status_changed_at': '2026-06-12T18:05:00Z',
          'holder_deadline_started_at': '2026-06-12T18:10:00Z',
          'holder_deadline_due_date': '2026-06-25',
          'closed_at': '2026-06-12T18:15:00Z',
          'resolution_reason': 'cancelled_during_review',
          'public_admin_reason_code': 'document_not_accepted',
          'public_admin_feedback':
              '   O documento enviado foi rejeitado por conter rasuras.   ',
        });

      final request = AccountChangeRequest.fromJson(json);
      expect(
        request.statusChangedAt,
        DateTime.parse('2026-06-12T18:05:00Z').toUtc(),
      );
      expect(
        request.holderDeadlineStartedAt,
        DateTime.parse('2026-06-12T18:10:00Z').toUtc(),
      );
      expect(
        request.holderDeadlineDueDate,
        AccountChangeCivilDate(year: 2026, month: 6, day: 25),
      );
      expect(request.closedAt, DateTime.parse('2026-06-12T18:15:00Z').toUtc());
      expect(
        request.resolutionReason,
        AccountChangeResolutionReason.cancelledDuringReview,
      );
      expect(
        request.publicAdminReasonCode,
        AccountChangePublicAdminReasonCode.documentNotAccepted,
      );
      expect(
        request.publicAdminFeedback,
        'O documento enviado foi rejeitado por conter rasuras.',
      );
    });

    test('28. Novos timestamps opcionais válidos convertidos para UTC', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..addAll({
          'status_changed_at': '2026-06-12T15:05:00-03:00',
          'holder_deadline_started_at': '2026-06-12T15:10:00-03:00',
          'closed_at': '2026-06-12T15:15:00-03:00',
        });

      final request = AccountChangeRequest.fromJson(json);
      expect(request.statusChangedAt!.isUtc, isTrue);
      expect(request.holderDeadlineStartedAt!.isUtc, isTrue);
      expect(request.closedAt!.isUtc, isTrue);
      expect(request.statusChangedAt, DateTime.parse('2026-06-12T18:05:00Z'));
      expect(
        request.holderDeadlineStartedAt,
        DateTime.parse('2026-06-12T18:10:00Z'),
      );
      expect(request.closedAt, DateTime.parse('2026-06-12T18:15:00Z'));
    });

    test('29. Novos timestamps opcionais ausentes/nulos permanecem null', () {
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..['status_changed_at'] = null
        ..['holder_deadline_started_at'] = null
        ..['closed_at'] = null;

      final request1 = AccountChangeRequest.fromJson(jsonNull);
      expect(request1.statusChangedAt, isNull);
      expect(request1.holderDeadlineStartedAt, isNull);
      expect(request1.closedAt, isNull);

      final request2 = AccountChangeRequest.fromJson(validBaseJson);
      expect(request2.statusChangedAt, isNull);
      expect(request2.holderDeadlineStartedAt, isNull);
      expect(request2.closedAt, isNull);
    });

    test('30. Novos timestamps opcionais inválidos geram FormatException', () {
      final jsonInvalidString = Map<String, dynamic>.from(validBaseJson)
        ..['status_changed_at'] = 'not-a-date';
      final jsonInvalidType = Map<String, dynamic>.from(validBaseJson)
        ..['closed_at'] = 12345;

      expect(
        () => AccountChangeRequest.fromJson(jsonInvalidString),
        throwsFormatException,
      );
      expect(
        () => AccountChangeRequest.fromJson(jsonInvalidType),
        throwsFormatException,
      );
    });

    test('31. Parsing de data civil válida YYYY-MM-DD', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..['holder_deadline_due_date'] = '2026-02-28';

      final request = AccountChangeRequest.fromJson(json);
      expect(
        request.holderDeadlineDueDate,
        AccountChangeCivilDate(year: 2026, month: 2, day: 28),
      );
      expect(request.holderDeadlineDueDate!.toString(), '2026-02-28');
      expect(request.holderDeadlineDueDate!.toIso8601String(), '2026-02-28');
    });

    test('32. Data civil bissexta válida e inválida', () {
      // 2024 é bissexto
      final leapDate = AccountChangeCivilDate.parse('2024-02-29');
      expect(leapDate.year, 2024);
      expect(leapDate.month, 2);
      expect(leapDate.day, 29);

      // 2026 não é bissexto -> 29 de fevereiro deve falhar
      expect(
        () => AccountChangeCivilDate.parse('2026-02-29'),
        throwsFormatException,
      );
    });

    test('33. Data civil inválida gera FormatException', () {
      final invalidDates = [
        '2026-02-30', // fevereiro com 30 dias
        '2026-13-01', // mês inválido
        '2026-06-32', // dia inválido
        '2026/06/20', // formato inválido com barra
        '2026-6-20', // mês com 1 dígito
        '', // string vazia
      ];

      for (final dateStr in invalidDates) {
        expect(
          () => AccountChangeCivilDate.parse(dateStr),
          throwsFormatException,
          reason: 'Deveria falhar para a string: $dateStr',
        );
      }

      // Tipos diferentes de String
      expect(() => AccountChangeCivilDate.parse(12345), throwsFormatException);
      expect(() => AccountChangeCivilDate.parse(true), throwsFormatException);
    });

    test('34. Data civil nula ou ausente permanece null', () {
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..['holder_deadline_due_date'] = null;
      final request1 = AccountChangeRequest.fromJson(jsonNull);
      expect(request1.holderDeadlineDueDate, isNull);

      final request2 = AccountChangeRequest.fromJson(validBaseJson);
      expect(request2.holderDeadlineDueDate, isNull);
    });

    test('35. Mapeamento de todos os motivos de resolução válidos', () {
      final resolutionReasons = {
        'cancelled_during_review':
            AccountChangeResolutionReason.cancelledDuringReview,
        'cancelled_while_waiting_document':
            AccountChangeResolutionReason.cancelledWhileWaitingDocument,
        'declined_final_confirmation':
            AccountChangeResolutionReason.declinedFinalConfirmation,
        'document_replacement_deadline':
            AccountChangeResolutionReason.documentReplacementDeadline,
        'holder_confirmation_deadline':
            AccountChangeResolutionReason.holderConfirmationDeadline,
      };

      for (final entry in resolutionReasons.entries) {
        final json = Map<String, dynamic>.from(validBaseJson)
          ..['resolution_reason'] = entry.key;
        final request = AccountChangeRequest.fromJson(json);
        expect(request.resolutionReason, entry.value);
      }
    });

    test('36. Motivo de resolução desconhecido ou nulo vira unknown', () {
      final jsonUnknown = Map<String, dynamic>.from(validBaseJson)
        ..['resolution_reason'] = 'future_reason_code';
      final jsonNull = Map<String, dynamic>.from(validBaseJson)
        ..['resolution_reason'] = null;

      final request1 = AccountChangeRequest.fromJson(jsonUnknown);
      expect(request1.resolutionReason, AccountChangeResolutionReason.unknown);

      final request2 = AccountChangeRequest.fromJson(jsonNull);
      expect(request2.resolutionReason, AccountChangeResolutionReason.unknown);

      final request3 = AccountChangeRequest.fromJson(validBaseJson);
      expect(request3.resolutionReason, AccountChangeResolutionReason.unknown);
    });

    test(
      '37. Mapeamento de todos os códigos administrativos públicos válidos',
      () {
        final adminCodes = {
          'document_not_accepted':
              AccountChangePublicAdminReasonCode.documentNotAccepted,
          'unreadable_document':
              AccountChangePublicAdminReasonCode.unreadableDocument,
          'cpf_not_visible': AccountChangePublicAdminReasonCode.cpfNotVisible,
          'name_mismatch': AccountChangePublicAdminReasonCode.nameMismatch,
          'birth_date_mismatch':
              AccountChangePublicAdminReasonCode.birthDateMismatch,
          'cpf_mismatch': AccountChangePublicAdminReasonCode.cpfMismatch,
          'other': AccountChangePublicAdminReasonCode.other,
        };

        for (final entry in adminCodes.entries) {
          final json = Map<String, dynamic>.from(validBaseJson)
            ..['public_admin_reason_code'] = entry.key;
          final request = AccountChangeRequest.fromJson(json);
          expect(request.publicAdminReasonCode, entry.value);
        }
      },
    );

    test(
      '38. Código administrativo público desconhecido ou nulo vira unknown',
      () {
        final jsonUnknown = Map<String, dynamic>.from(validBaseJson)
          ..['public_admin_reason_code'] = 'future_reason_code';
        final jsonNull = Map<String, dynamic>.from(validBaseJson)
          ..['public_admin_reason_code'] = null;

        final request1 = AccountChangeRequest.fromJson(jsonUnknown);
        expect(
          request1.publicAdminReasonCode,
          AccountChangePublicAdminReasonCode.unknown,
        );

        final request2 = AccountChangeRequest.fromJson(jsonNull);
        expect(
          request2.publicAdminReasonCode,
          AccountChangePublicAdminReasonCode.unknown,
        );

        final request3 = AccountChangeRequest.fromJson(validBaseJson);
        expect(
          request3.publicAdminReasonCode,
          AccountChangePublicAdminReasonCode.unknown,
        );
      },
    );

    test(
      '39. Feedback público com espaços externos e vazio/espaços apenas',
      () {
        final jsonTrim = Map<String, dynamic>.from(validBaseJson)
          ..['public_admin_feedback'] = '   feedback com espaços   ';
        final jsonEmpty = Map<String, dynamic>.from(validBaseJson)
          ..['public_admin_feedback'] = '      ';
        final jsonNull = Map<String, dynamic>.from(validBaseJson)
          ..['public_admin_feedback'] = null;

        final request1 = AccountChangeRequest.fromJson(jsonTrim);
        expect(request1.publicAdminFeedback, 'feedback com espaços');

        final request2 = AccountChangeRequest.fromJson(jsonEmpty);
        expect(request2.publicAdminFeedback, isNull);

        final request3 = AccountChangeRequest.fromJson(jsonNull);
        expect(request3.publicAdminFeedback, isNull);
      },
    );

    test('40. Feedback público com tipo inválido gera FormatException', () {
      final jsonInt = Map<String, dynamic>.from(validBaseJson)
        ..['public_admin_feedback'] = 12345;
      final jsonBool = Map<String, dynamic>.from(validBaseJson)
        ..['public_admin_feedback'] = true;

      expect(
        () => AccountChangeRequest.fromJson(jsonInt),
        throwsFormatException,
      );
      expect(
        () => AccountChangeRequest.fromJson(jsonBool),
        throwsFormatException,
      );
    });

    test('41. Getters dbValue dos novos enums', () {
      expect(
        AccountChangeResolutionReason.cancelledDuringReview.dbValue,
        'cancelled_during_review',
      );
      expect(AccountChangeResolutionReason.unknown.dbValue, isNull);

      expect(
        AccountChangePublicAdminReasonCode.documentNotAccepted.dbValue,
        'document_not_accepted',
      );
      expect(AccountChangePublicAdminReasonCode.unknown.dbValue, isNull);
    });

    test('42. Igualdade e hashCode para AccountChangeCivilDate', () {
      final date1 = AccountChangeCivilDate(year: 2026, month: 6, day: 20);
      final date2 = AccountChangeCivilDate(year: 2026, month: 6, day: 20);
      final date3 = AccountChangeCivilDate(year: 2026, month: 6, day: 21);

      expect(date1, date2);
      expect(date1.hashCode, date2.hashCode);
      expect(date1, isNot(date3));
    });

    test('43. Campos internos extras continuam a ser ignorados', () {
      final json = Map<String, dynamic>.from(validBaseJson)
        ..addAll({
          'admin_deadline_started_at': '2026-06-12T18:00:00Z',
          'admin_reason': 'wrong_document',
          'admin_feedback': 'Feedback interno do admin',
          'document_state': 'waiting_validation',
          'admin_id': '6bf571f0-c0ec-4543-81fe-1f3f032d7c5c',
        });

      final request = AccountChangeRequest.fromJson(json);
      expect(request.id, '6bf571f0-c0ec-4543-81fe-1f3f032d7c5c');
      // Garante que não joga exceção de chaves não mapeadas
    });

    test(
      '44. Testes diretos da criação pública via factory AccountChangeCivilDate',
      () {
        // 1. aceita 2028-02-29 (ano bissexto)
        final leapDate = AccountChangeCivilDate(year: 2028, month: 2, day: 29);
        expect(leapDate.year, 2028);
        expect(leapDate.month, 2);
        expect(leapDate.day, 29);

        // 2. rejeita 2026-02-29 (não bissexto)
        expect(
          () => AccountChangeCivilDate(year: 2026, month: 2, day: 29),
          throwsFormatException,
        );

        // 3. rejeita 2026-02-30
        expect(
          () => AccountChangeCivilDate(year: 2026, month: 2, day: 30),
          throwsFormatException,
        );

        // 4. rejeita mês 0
        expect(
          () => AccountChangeCivilDate(year: 2026, month: 0, day: 15),
          throwsFormatException,
        );

        // 5. rejeita mês 13
        expect(
          () => AccountChangeCivilDate(year: 2026, month: 13, day: 15),
          throwsFormatException,
        );

        // 6. rejeita dia 0
        expect(
          () => AccountChangeCivilDate(year: 2026, month: 6, day: 0),
          throwsFormatException,
        );

        // 7. rejeita dia acima do limite do mês
        expect(
          () => AccountChangeCivilDate(year: 2026, month: 4, day: 31),
          throwsFormatException,
        );

        // 8. factory e parse da mesma data geram objetos iguais
        final dateFromFactory = AccountChangeCivilDate(
          year: 2026,
          month: 6,
          day: 20,
        );
        final dateFromParse = AccountChangeCivilDate.parse('2026-06-20');
        expect(dateFromFactory, dateFromParse);
      },
    );

    test('45. Testes de limite de ano civil para AccountChangeCivilDate', () {
      // 1. ano 1 é aceito e produz 0001-01-01
      final dateMin = AccountChangeCivilDate(year: 1, month: 1, day: 1);
      expect(dateMin.toIso8601String(), '0001-01-01');

      // 2. ano 9999 é aceito e produz 9999-12-31
      final dateMax = AccountChangeCivilDate(year: 9999, month: 12, day: 31);
      expect(dateMax.toIso8601String(), '9999-12-31');

      // 3. ano 0 é rejeitado
      expect(
        () => AccountChangeCivilDate(year: 0, month: 1, day: 1),
        throwsFormatException,
      );

      // 4. ano negativo é rejeitado
      expect(
        () => AccountChangeCivilDate(year: -1, month: 1, day: 1),
        throwsFormatException,
      );

      // 5. ano 10000 é rejeitado
      expect(
        () => AccountChangeCivilDate(year: 10000, month: 1, day: 1),
        throwsFormatException,
      );

      // 6. parse de 0000-01-01 é rejeitado
      expect(
        () => AccountChangeCivilDate.parse('0000-01-01'),
        throwsFormatException,
      );

      // 7. parse de 10000-01-01 é rejeitado (formato/faixa)
      expect(
        () => AccountChangeCivilDate.parse('10000-01-01'),
        throwsFormatException,
      );
    });
  });
}
