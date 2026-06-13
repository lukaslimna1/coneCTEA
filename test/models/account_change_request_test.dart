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
        'waiting_proof': AccountChangeStatus.waitingProof,
        'under_review': AccountChangeStatus.underReview,
        'waiting_holder_confirmation':
            AccountChangeStatus.waitingHolderConfirmation,
        'rejected_by_admin': AccountChangeStatus.rejectedByAdmin,
        'cancelled_by_holder': AccountChangeStatus.cancelledByHolder,
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
    });
  });
}
