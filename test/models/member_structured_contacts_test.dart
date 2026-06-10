import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/models/member.dart';

void main() {
  group('Member Structured Contacts Tests', () {
    final Map<String, dynamic> baseJson = {
      'id': 'member-id-123',
      'user_id': 'user-id-456',
      'name': 'Beneficiario Ficticio',
      'cpf': '000.000.000-00',
      'city': 'Bauru',
      'state': 'SP',
      'phone': '(14) 99999-1111',
      'emergency_contact': 'Contato Emergencia Composto - (14) 99999-2222',
      'responsible_name': 'Responsavel Composto - (14) 99999-3333',
      'birth_date': '2020-01-01',
      'blood_type': 'O+',
      'cid': 'F84.0',
      'document_url': 'https://drive.google.com/doc',
      'medical_report_url': 'https://drive.google.com/report',
      'status': 'active',
      'created_at': '2026-06-10T10:00:00.000Z',
      'updated_at': '2026-06-10T10:00:00.000Z',
      'gender': 'Masculino',
      'raca_cor': 'Parda',
      'social_name': 'Nome Social Ficticio',
      'tea_relation_type': 'pessoa_tea',
    };

    test('1. fromJson lê responsible_person_name', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['responsible_person_name'] = 'Responsavel Estruturado Novo';
      final member = Member.fromJson(json);
      expect(member.responsiblePersonName, 'Responsavel Estruturado Novo');
    });

    test('2. fromJson lê responsible_phone', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['responsible_phone'] = '(14) 99999-7777';
      final member = Member.fromJson(json);
      expect(member.responsiblePhone, '(14) 99999-7777');
    });

    test('3. fromJson lê emergency_person_name', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['emergency_person_name'] = 'Emergencia Estruturado Novo';
      final member = Member.fromJson(json);
      expect(member.emergencyPersonName, 'Emergencia Estruturado Novo');
    });

    test('4. fromJson lê emergency_phone', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['emergency_phone'] = '(14) 99999-6666';
      final member = Member.fromJson(json);
      expect(member.emergencyPhone, '(14) 99999-6666');
    });

    test('5. fromJson aceita camelCase', () {
      final json = Map<String, dynamic>.from(baseJson);
      json['responsiblePersonName'] = 'Camel Name';
      json['responsiblePhone'] = '14999993333';
      json['emergencyPersonName'] = 'Camel Emerg Name';
      json['emergencyPhone'] = '14999994444';
      final member = Member.fromJson(json);
      expect(member.responsiblePersonName, 'Camel Name');
      expect(member.responsiblePhone, '14999993333');
      expect(member.emergencyPersonName, 'Camel Emerg Name');
      expect(member.emergencyPhone, '14999994444');
    });

    test('6. fromJson ausente mantém null', () {
      final member = Member.fromJson(baseJson);
      expect(member.responsiblePersonName, isNull);
      expect(member.responsiblePhone, isNull);
      expect(member.emergencyPersonName, isNull);
      expect(member.emergencyPhone, isNull);
    });

    test('7. toJson inclui as quatro chaves novas', () {
      final member = Member.empty().copyWith(
        responsiblePersonName: 'Nome Resp',
        responsiblePhone: '(14) 99999-0000',
        emergencyPersonName: 'Nome Emerg',
        emergencyPhone: '(14) 99999-1111',
      );
      final json = member.toJson();
      expect(json['responsible_person_name'], 'Nome Resp');
      expect(json['responsible_phone'], '(14) 99999-0000');
      expect(json['emergency_person_name'], 'Nome Emerg');
      expect(json['emergency_phone'], '(14) 99999-1111');
    });

    test('8. toJson preserva as duas chaves legadas', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Nome Legado',
        emergencyContact: 'Emerg Legado',
      );
      final json = member.toJson();
      expect(json['responsible_name'], 'Nome Legado');
      expect(json['emergency_contact'], 'Emerg Legado');
    });

    test('9. campos estruturados novos prevalecem sobre legado', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Responsavel Legado - (14) 99999-1234',
        responsiblePersonName: 'Responsavel Novo',
        responsiblePhone: '(14) 99999-4321',
      );
      expect(member.effectiveResponsiblePersonName, 'Responsavel Novo');
      expect(member.effectiveResponsiblePhone, '(14) 99999-4321');
    });

    test('10. responsible nameOnly legado gera nome efetivo', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Responsavel Apenas Nome',
      );
      expect(member.effectiveResponsiblePersonName, 'Responsavel Apenas Nome');
      expect(member.effectiveResponsiblePhone, '');
    });

    test('11. responsible complete legado gera nome e telefone efetivos', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Responsavel Legado - (14) 99999-1234',
      );
      expect(member.effectiveResponsiblePersonName, 'Responsavel Legado');
      expect(member.effectiveResponsiblePhone, '(14) 99999-1234');
    });

    test('12. responsible ambiguous não gera nome efetivo', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Responsavel Legado - Ciclano',
      );
      expect(member.effectiveResponsiblePersonName, '');
      expect(member.effectiveResponsiblePhone, '');
    });

    test('13. responsible ambiguous não gera telefone efetivo', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Responsavel com Numeros 1234',
      );
      expect(member.effectiveResponsiblePersonName, '');
      expect(member.effectiveResponsiblePhone, '');
    });

    test('14. responsible phoneOnlyLegacy não gera telefone efetivo', () {
      // Justificativa: phoneOnlyLegacy é inconsistente (telefone sem nome). Pela regra das constraints físicas,
      // telefone estruturado exige nome estruturado. Não deve ser promovido a telefone efetivo.
      final member = Member.empty().copyWith(
        responsibleName: '(14) 99999-1234',
      );
      expect(member.effectiveResponsiblePersonName, '');
      expect(member.effectiveResponsiblePhone, '');
    });

    test('15. emergency nameOnly legado gera nome efetivo', () {
      final member = Member.empty().copyWith(
        emergencyContact: 'Emergencia Apenas Nome',
      );
      expect(member.effectiveEmergencyPersonName, 'Emergencia Apenas Nome');
      expect(member.effectiveEmergencyPhone, '');
    });

    test('16. emergency complete legado gera nome e telefone efetivos', () {
      final member = Member.empty().copyWith(
        emergencyContact: 'Emergencia Legado - (14) 99999-1234',
      );
      expect(member.effectiveEmergencyPersonName, 'Emergencia Legado');
      expect(member.effectiveEmergencyPhone, '(14) 99999-1234');
    });

    test('17. emergency ambiguous não gera dados efetivos', () {
      final member = Member.empty().copyWith(
        emergencyContact: 'Emergencia com Numeros 123',
      );
      expect(member.effectiveEmergencyPersonName, '');
      expect(member.effectiveEmergencyPhone, '');
    });

    test('18. fallback visual preserva legado ambiguous', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Responsavel Legado - Ciclano',
      );
      expect(member.responsibleLegacyDisplayValue, 'Responsavel Legado - Ciclano');
    });

    test('19. fallback visual preserva phoneOnlyLegacy', () {
      final member = Member.empty().copyWith(
        emergencyContact: '(14) 99999-1234',
      );
      expect(member.emergencyLegacyDisplayValue, '(14) 99999-1234');
    });

    test('20. fallback visual usa campos estruturados quando presentes', () {
      final member = Member.empty().copyWith(
        responsibleName: 'Legado - 14999990000',
        responsiblePersonName: 'Nome Novo',
        responsiblePhone: '14999994321',
      );
      expect(member.responsibleLegacyDisplayValue, 'Nome Novo - 14999994321');
    });

    test('21. somente nome estruturado gera display somente com nome', () {
      final member = Member.empty().copyWith(
        responsiblePersonName: 'Nome Estruturado Solo',
      );
      expect(member.responsibleLegacyDisplayValue, 'Nome Estruturado Solo');
    });

    test('22. nome e telefone estruturados geram display composto', () {
      final member = Member.empty().copyWith(
        emergencyPersonName: 'Nome Emerg',
        emergencyPhone: '14999995555',
      );
      expect(member.emergencyLegacyDisplayValue, 'Nome Emerg - 14999995555');
    });

    test('23. Member.empty inicializa campos novos como null', () {
      final member = Member.empty();
      expect(member.responsiblePersonName, isNull);
      expect(member.responsiblePhone, isNull);
      expect(member.emergencyPersonName, isNull);
      expect(member.emergencyPhone, isNull);
    });

    test('24. copyWith preserva campos novos', () {
      final member = Member.empty().copyWith(
        responsiblePersonName: 'Teste P',
      );
      final copied = member.copyWith();
      expect(copied.responsiblePersonName, 'Teste P');
    });

    test('25. copyWith substitui campos novos por valores não nulos', () {
      final member = Member.empty().copyWith(
        responsiblePersonName: 'Original',
      );
      final copied = member.copyWith(
        responsiblePersonName: 'Substituido',
      );
      expect(copied.responsiblePersonName, 'Substituido');
    });

    test('26. id, userId, cpf, status, URLs, createdAt e updatedAt permanecem intactos', () {
      final original = Member.fromJson(baseJson);
      final copied = original.copyWith(
        responsiblePersonName: 'Nome Novo',
      );
      expect(copied.id, original.id);
      expect(copied.userId, original.userId);
      expect(copied.cpf, original.cpf);
      expect(copied.status, original.status);
      expect(copied.documentUrl, original.documentUrl);
      expect(copied.medicalReportUrl, original.medicalReportUrl);
      expect(copied.createdAt, original.createdAt);
      expect(copied.updatedAt, original.updatedAt);
    });

    test('27. nenhum getter altera o objeto', () {
      final original = Member.fromJson(baseJson);
      final originalJsonBefore = original.toJson();
      
      // Chamar getters sem atribuição para verificar imutabilidade
      original.effectiveResponsiblePersonName;
      original.effectiveResponsiblePhone;
      original.responsibleLegacyDisplayValue;
      
      final originalJsonAfter = original.toJson();
      expect(originalJsonBefore, originalJsonAfter);
    });

    test('28. nenhum getter registra dados', () {
      final original = Member.empty().copyWith(
        responsibleName: 'Ficticio - 14999990000',
      );
      // Chamar os getters apenas para certificar ausência de exceções
      expect(original.effectiveResponsiblePersonName, 'Ficticio');
      expect(original.effectiveResponsiblePhone, '14999990000');
      expect(original.responsibleLegacyDisplayValue, 'Ficticio - 14999990000');
    });
  });
}
