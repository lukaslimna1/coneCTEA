import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/services/database_service.dart';

/// Testes da validação de allowlist e campos proibidos do método
/// [DatabaseService.updateMemberFields].
///
/// Não testa integração com Supabase.
/// Testa somente a lógica de validação pura via chamada direta que lança
/// antes de atingir o banco.
void main() {
  group('DatabaseService.validatePartialUpdateFields — Validação', () {
    void runValidation(String id, Map<String, dynamic> fields) {
      DatabaseService.validatePartialUpdateFields(id, fields);
    }

    test('1. Map vazio é rejeitado', () {
      expect(
        () => runValidation('member-id-123', {}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Nenhum campo fornecido para atualização.',
          ),
        ),
      );
    });

    test('2. ID vazio é rejeitado', () {
      expect(
        () => runValidation('', {'name': 'Teste'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'ID do membro não pode ser vazio.',
          ),
        ),
      );
    });

    test('3. ID com apenas espaços é rejeitado', () {
      expect(
        () => runValidation('   ', {'name': 'Teste'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'ID do membro não pode ser vazio.',
          ),
        ),
      );
    });

    test('4. Campo proibido "id" é rejeitado', () {
      expect(
        () => runValidation('member-id', {'id': 'novo-id'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo proibido para atualização parcial.',
          ),
        ),
      );
    });

    test('5. Campo proibido "user_id" é rejeitado', () {
      expect(
        () => runValidation('member-id', {'user_id': 'outro'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo proibido para atualização parcial.',
          ),
        ),
      );
    });

    test('6. Campo proibido "status" é rejeitado', () {
      expect(
        () => runValidation('member-id', {'status': 'active'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo proibido para atualização parcial.',
          ),
        ),
      );
    });

    test('7. Campo proibido "created_at" é rejeitado', () {
      expect(
        () => runValidation('member-id', {'created_at': '2026-01-01'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo proibido para atualização parcial.',
          ),
        ),
      );
    });

    test('8. Campo proibido "updated_at" é rejeitado', () {
      expect(
        () => runValidation('member-id', {'updated_at': '2026-01-01'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo proibido para atualização parcial.',
          ),
        ),
      );
    });

    test('9. Campo proibido "document_url" é rejeitado', () {
      expect(
        () => runValidation('member-id', {'document_url': 'url'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo proibido para atualização parcial.',
          ),
        ),
      );
    });

    test('10. Campo proibido "medical_report_url" é rejeitado', () {
      expect(
        () => runValidation('member-id', {'medical_report_url': 'url'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo proibido para atualização parcial.',
          ),
        ),
      );
    });

    test('11. Campo desconhecido é rejeitado', () {
      expect(
        () => runValidation('member-id', {'campo_inexistente': 'valor'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Campo não autorizado para atualização parcial.',
          ),
        ),
      );
    });

    test(
      '12. Allowlist aceita campos cadastrais base sem rejeição de validação',
      () {
        final fieldsToTest = {
          'name': 'Nome Ficticio',
          'city': 'Bauru',
          'social_name': 'Social',
          'blood_type': 'O+',
        };

        expect(
          () => runValidation('member-id-123', fieldsToTest),
          isNot(throwsA(isA<ArgumentError>())),
        );
      },
    );

    test(
      '13. Allowlist aceita campos legados de contato sem rejeição de validação',
      () {
        final fieldsToTest = {
          'phone': '14999990000',
          'emergency_contact': 'Contato Ficticio',
          'responsible_name': 'Responsavel Ficticio',
        };

        expect(
          () => runValidation('member-id-123', fieldsToTest),
          isNot(throwsA(isA<ArgumentError>())),
        );
      },
    );

    test(
      '14. null intencional em campo permitido não é rejeitado pela validação',
      () {
        final fieldsToTest = {'social_name': null};

        expect(
          () => runValidation('member-id-123', fieldsToTest),
          isNot(throwsA(isA<ArgumentError>())),
        );
      },
    );

    test(
      '15. Mistura de campo proibido com permitido é rejeitada integralmente',
      () {
        expect(
          () =>
              runValidation('member-id', {'name': 'Teste', 'status': 'active'}),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('16. Allowlist consistente - reuso da lista', () {
      final fields = {'name': 'Teste'};
      expect(
        () => runValidation('id-1', fields),
        isNot(throwsA(isA<ArgumentError>())),
      );
      expect(
        () => runValidation('id-2', fields),
        isNot(throwsA(isA<ArgumentError>())),
      );
    });

    test(
      '17. Quatro campos estruturados removidos da allowlist atual são rejeitados',
      () {
        final fieldsToTest = {
          'responsible_person_name': 'Nome',
          'responsible_phone': '111',
          'emergency_person_name': 'Nome2',
          'emergency_phone': '222',
        };
        expect(
          () => runValidation('member-id-123', fieldsToTest),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Campo proibido para atualização parcial.',
            ),
          ),
        );
      },
    );

    test('18. Map original não é modificado pela validação', () {
      final fieldsToTest = {'name': 'Teste'};
      runValidation('member-id-123', fieldsToTest);
      expect(fieldsToTest, equals({'name': 'Teste'}));
    });

    test('19. null em campo não anulável é rejeitado pela validação', () {
      final fieldsToTest = {'name': null};

      expect(
        () => runValidation('member-id-123', fieldsToTest),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'O campo name não pode receber valor nulo.',
          ),
        ),
      );
    });
  });
}
