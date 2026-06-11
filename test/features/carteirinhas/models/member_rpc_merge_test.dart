import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_result.dart';
import 'package:conectea/features/carteirinhas/models/member_rpc_merge_extension.dart';

void main() {
  group('MemberRpcMergeExtension Tests', () {
    final originalCreatedAt = DateTime(2026, 1, 1, 12, 0);
    final originalUpdatedAt = DateTime(2026, 1, 2, 14, 0);

    final originalMember = Member(
      id: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
      userId: 'user-id-123',
      name: 'João da Silva',
      cpf: '123.456.789-00',
      city: 'Bauru',
      state: 'SP',
      phone: '14999999999',
      emergencyContact: 'Maria da Silva - 14988888888',
      responsibleName: 'Pedro da Silva - 14977777777',
      dateOfBirth: '2000-05-15',
      bloodType: 'O+',
      cid: 'F84.0',
      documentUrl: 'https://drive.google.com/doc.pdf',
      medicalReportUrl: 'https://drive.google.com/report.pdf',
      status: 'active',
      createdAt: originalCreatedAt,
      updatedAt: originalUpdatedAt,
      gender: 'Masculino',
      racaCor: 'Parda',
      socialName: 'Joãozinho',
      teaRelationType: 'pessoa_tea',
    );

    test('1. mescla válida com todos os sete campos', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva - 14966665555',
        emergencyContact: 'Tadeu Silva - 14944443333',
        appliedFields: [
          'blood_type',
          'phone',
          'raca_cor',
          'gender',
          'cid',
          'responsible_name',
          'emergency_contact',
        ],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);

      expect(merged.bloodType, 'A-');
      expect(merged.phone, '14988887777');
      expect(merged.racaCor, 'Branca');
      expect(merged.gender, 'Outro');
      expect(merged.cid, 'F84.1');
      expect(merged.responsibleName, 'Carla Silva - 14966665555');
      expect(merged.emergencyContact, 'Tadeu Silva - 14944443333');
    });

    test('2. preservação de id', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.id, 'a3d07e60-4e56-4b8c-8c7e-976e1a123456');
    });

    test('3. preservação de userId', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.userId, 'user-id-123');
    });

    test('4. preservação de CPF', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.cpf, '123.456.789-00');
    });

    test('5. preservação de status', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.status, 'active');
    });

    test('6. preservação de URLs de documentos', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.documentUrl, 'https://drive.google.com/doc.pdf');
      expect(merged.medicalReportUrl, 'https://drive.google.com/report.pdf');
    });

    test('7. preservação de createdAt', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.createdAt, originalCreatedAt);
    });

    test('8. preservação de updatedAt', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.updatedAt, originalUpdatedAt);
    });

    test('9. racaCor null', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: null,
        gender: 'Masculino',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.racaCor, isNull);
    });

    test('10. gender null', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: null,
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.gender, isNull);
    });

    test('11. strings vazias retornadas', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: '',
        phone: '',
        racaCor: 'Parda',
        gender: 'Masculino',
        cid: '',
        responsibleName: '',
        emergencyContact: '',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.bloodType, '');
      expect(merged.phone, '');
      expect(merged.cid, '');
      expect(merged.responsibleName, '');
      expect(merged.emergencyContact, '');
    });

    test('12. responsibleName composto preservado integralmente', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva - 14966665555 - Contato Extra',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(
        merged.responsibleName,
        'Carla Silva - 14966665555 - Contato Extra',
      );
    });

    test('13. emergencyContact composto preservado integralmente', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva - 14944443333 - Contato Extra',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(
        merged.emergencyContact,
        'Tadeu Silva - 14944443333 - Contato Extra',
      );
    });

    test('14. memberId divergente gera erro', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'outro-id-divergente-999',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      expect(
        () => originalMember.mergeRpcResult(result),
        throwsA(isA<StateError>()),
      );
    });

    test('15. changed false ainda aplica o estado consolidado retornado', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'AB+',
        phone: '14977776666',
        racaCor: 'Amarela',
        gender: 'Não binário',
        cid: 'F84.5',
        responsibleName: 'Pedro Silva',
        emergencyContact: 'Paulo Silva',
        appliedFields: [],
        preservedFields: [],
        changed: false,
      );

      final merged = originalMember.mergeRpcResult(result);

      expect(merged.bloodType, 'AB+');
      expect(merged.phone, '14977776666');
      expect(merged.racaCor, 'Amarela');
      expect(merged.gender, 'Não binário');
      expect(merged.cid, 'F84.5');
      expect(merged.responsibleName, 'Pedro Silva');
      expect(merged.emergencyContact, 'Paulo Silva');
    });

    test(
      '16. appliedFields e preservedFields não alteram o comportamento da mescla',
      () {
        final result = FillEmptyMemberOptionalFieldsResult(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: 'AB-',
          phone: '14955554444',
          racaCor: 'Indígena',
          gender: 'Feminino',
          cid: 'F84.9',
          responsibleName: 'José Silva',
          emergencyContact: 'Zezinho',
          appliedFields: ['blood_type'],
          preservedFields: ['phone', 'cid'],
          changed: true,
        );

        final merged = originalMember.mergeRpcResult(result);

        expect(merged.bloodType, 'AB-');
        expect(merged.phone, '14955554444');
        expect(merged.racaCor, 'Indígena');
        expect(merged.gender, 'Feminino');
        expect(merged.cid, 'F84.9');
        expect(merged.responsibleName, 'José Silva');
        expect(merged.emergencyContact, 'Zezinho');
      },
    );

    // Testes de preservação dos campos estruturados (B7)
    test('17. campos estruturados preservados após merge', () {
      final memberWithStructured = Member(
        id: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        userId: 'user-id-123',
        name: 'Beneficiario Ficticio',
        cpf: '000.000.000-00',
        city: 'Bauru',
        state: 'SP',
        phone: '14999999999',
        emergencyContact: 'Contato Legado',
        responsibleName: 'Resp Legado',
        dateOfBirth: '2020-01-01',
        bloodType: 'O+',
        cid: 'F84.0',
        documentUrl: 'https://example.com/doc',
        medicalReportUrl: 'https://example.com/report',
        status: 'active',
        createdAt: originalCreatedAt,
        updatedAt: originalUpdatedAt,
        responsiblePersonName: 'Responsavel Estruturado Ficticio',
        responsiblePhone: '14988880000',
        emergencyPersonName: 'Emergencia Estruturada Ficticia',
        emergencyPhone: '14977770000',
      );

      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14955554444',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Resp Legado RPC',
        emergencyContact: 'Emerg Legado RPC',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = memberWithStructured.mergeRpcResult(result);

      // Campos estruturados devem permanecer da instância original
      expect(merged.responsiblePersonName, 'Responsavel Estruturado Ficticio');
      expect(merged.responsiblePhone, '14988880000');
      expect(merged.emergencyPersonName, 'Emergencia Estruturada Ficticia');
      expect(merged.emergencyPhone, '14977770000');
    });

    test(
      '18. campos legados retornados pela RPC continuam aplicados após merge com estruturados',
      () {
        final memberWithStructured = Member(
          id: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          userId: 'user-id-123',
          name: 'Beneficiario Ficticio',
          cpf: '000.000.000-00',
          city: 'Bauru',
          state: 'SP',
          phone: '14999999999',
          emergencyContact: 'Contato Legado Original',
          responsibleName: 'Resp Legado Original',
          dateOfBirth: '2020-01-01',
          bloodType: 'O+',
          cid: 'F84.0',
          documentUrl: 'https://example.com/doc',
          medicalReportUrl: 'https://example.com/report',
          status: 'active',
          createdAt: originalCreatedAt,
          updatedAt: originalUpdatedAt,
          responsiblePersonName: 'Resp Estruturado',
          responsiblePhone: '14988880000',
        );

        final result = FillEmptyMemberOptionalFieldsResult(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: 'A+',
          phone: '14911112222',
          racaCor: null,
          gender: null,
          cid: 'F84.0',
          responsibleName: 'Resp Legado Atualizado pela RPC',
          emergencyContact: 'Emerg Legado Atualizado pela RPC',
          appliedFields: ['responsible_name', 'emergency_contact'],
          preservedFields: [],
          changed: true,
        );

        final merged = memberWithStructured.mergeRpcResult(result);

        // Legados vêm da RPC
        expect(merged.responsibleName, 'Resp Legado Atualizado pela RPC');
        expect(merged.emergencyContact, 'Emerg Legado Atualizado pela RPC');
        // Estruturados preservados da instância original
        expect(merged.responsiblePersonName, 'Resp Estruturado');
        expect(merged.responsiblePhone, '14988880000');
      },
    );

    test('19. campos estruturados null permanecem null após merge', () {
      // originalMember não tem campos estruturados (ficam null)
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsibleName: 'Carla Silva',
        emergencyContact: 'Tadeu Silva',
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);

      expect(merged.responsiblePersonName, isNull);
      expect(merged.responsiblePhone, isNull);
      expect(merged.emergencyPersonName, isNull);
      expect(merged.emergencyPhone, isNull);
    });

    test(
      '20. propriedades sensíveis preservadas com campos estruturados presentes',
      () {
        final memberWithAll = Member(
          id: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          userId: 'user-id-123',
          name: 'Beneficiario Ficticio',
          cpf: '000.000.000-00',
          city: 'Bauru',
          state: 'SP',
          phone: '14999999999',
          emergencyContact: 'Contato Legado',
          responsibleName: 'Resp Legado',
          dateOfBirth: '2020-01-01',
          bloodType: 'O+',
          cid: 'F84.0',
          documentUrl: 'https://example.com/doc',
          medicalReportUrl: 'https://example.com/report',
          status: 'active',
          createdAt: originalCreatedAt,
          updatedAt: originalUpdatedAt,
          socialName: 'Nome Social Ficticio',
          teaRelationType: 'pessoa_tea',
          responsiblePersonName: 'Resp Estruturado',
          responsiblePhone: '14988880000',
          emergencyPersonName: 'Emerg Estruturada',
          emergencyPhone: '14977770000',
        );

        final result = FillEmptyMemberOptionalFieldsResult(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: 'B+',
          phone: '14900001111',
          racaCor: 'Parda',
          gender: 'Masculino',
          cid: 'F84.0',
          responsibleName: 'Resp RPC',
          emergencyContact: 'Emerg RPC',
          appliedFields: [],
          preservedFields: [],
          changed: true,
        );

        final merged = memberWithAll.mergeRpcResult(result);

        // Sensíveis preservados
        expect(merged.id, 'a3d07e60-4e56-4b8c-8c7e-976e1a123456');
        expect(merged.userId, 'user-id-123');
        expect(merged.cpf, '000.000.000-00');
        expect(merged.status, 'active');
        expect(merged.documentUrl, 'https://example.com/doc');
        expect(merged.medicalReportUrl, 'https://example.com/report');
        expect(merged.createdAt, originalCreatedAt);
        expect(merged.updatedAt, originalUpdatedAt);
        expect(merged.socialName, 'Nome Social Ficticio');
        expect(merged.teaRelationType, 'pessoa_tea');
        // Estruturados preservados
        expect(merged.responsiblePersonName, 'Resp Estruturado');
        expect(merged.responsiblePhone, '14988880000');
        expect(merged.emergencyPersonName, 'Emerg Estruturada');
        expect(merged.emergencyPhone, '14977770000');
      },
    );
  });
}
