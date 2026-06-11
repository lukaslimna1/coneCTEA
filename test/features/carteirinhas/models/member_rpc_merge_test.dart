import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_result.dart';
import 'package:conectea/features/carteirinhas/models/member_rpc_merge_extension.dart';

void main() {
  group('MemberRpcMergeExtension Tests (V2)', () {
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

    test(
      '1. mescla válida com todos os quatro campos estruturados aplicados',
      () {
        final result = FillEmptyMemberOptionalFieldsResult(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: 'A-',
          phone: '14988887777',
          racaCor: 'Branca',
          gender: 'Outro',
          cid: 'F84.1',
          responsiblePersonName: 'Carla Silva',
          responsiblePhone: '14966665555',
          emergencyPersonName: 'Tadeu Silva',
          emergencyPhone: '14944443333',
          appliedFields: [
            'blood_type',
            'phone',
            'raca_cor',
            'gender',
            'cid',
            'responsible_person_name',
            'responsible_phone',
            'emergency_person_name',
            'emergency_phone',
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
        expect(merged.responsiblePersonName, 'Carla Silva');
        expect(merged.responsiblePhone, '14966665555');
        expect(merged.emergencyPersonName, 'Tadeu Silva');
        expect(merged.emergencyPhone, '14944443333');
      },
    );

    test('2. preservação de id', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
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
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
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
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
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
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
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
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
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
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
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
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.updatedAt, originalUpdatedAt);
    });

    test('9. racaCor null respeitado', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: null,
        gender: 'Masculino',
        cid: 'F84.1',
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.racaCor, isNull);
    });

    test('10. gender null respeitado', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: null,
        cid: 'F84.1',
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      final merged = originalMember.mergeRpcResult(result);
      expect(merged.gender, isNull);
    });

    test('11. null estruturado é respeitado', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: '',
        phone: '',
        racaCor: 'Parda',
        gender: 'Masculino',
        cid: '',
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
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
      '12. campos legados existentes são preservados sem alterações do DTO V2',
      () {
        final result = FillEmptyMemberOptionalFieldsResult(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: 'A-',
          phone: '14988887777',
          racaCor: 'Branca',
          gender: 'Outro',
          cid: 'F84.1',
          responsiblePersonName: 'Carla Silva',
          responsiblePhone: '14966665555',
          emergencyPersonName: 'Tadeu Silva',
          emergencyPhone: '14944443333',
          appliedFields: [],
          preservedFields: [],
          changed: true,
        );

        final merged = originalMember.mergeRpcResult(result);
        // Os legados permanecem intactos copiados da instância original
        expect(merged.responsibleName, 'Pedro da Silva - 14977777777');
        expect(merged.emergencyContact, 'Maria da Silva - 14988888888');
      },
    );

    test('13. memberId divergente continua gerando erro', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'outro-id-divergente-999',
        bloodType: 'A-',
        phone: '14988887777',
        racaCor: 'Branca',
        gender: 'Outro',
        cid: 'F84.1',
        responsiblePersonName: null,
        responsiblePhone: null,
        emergencyPersonName: null,
        emergencyPhone: null,
        appliedFields: [],
        preservedFields: [],
        changed: true,
      );

      expect(
        () => originalMember.mergeRpcResult(result),
        throwsA(isA<StateError>()),
      );
    });

    test('14. changed false aplica o retorno consolidado normalmente', () {
      final result = FillEmptyMemberOptionalFieldsResult(
        memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        bloodType: 'AB+',
        phone: '14977776666',
        racaCor: 'Amarela',
        gender: 'Não binário',
        cid: 'F84.5',
        responsiblePersonName: 'Pedro Silva',
        responsiblePhone: '14911111111',
        emergencyPersonName: 'Paulo Silva',
        emergencyPhone: '14922222222',
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
      expect(merged.responsiblePersonName, 'Pedro Silva');
      expect(merged.responsiblePhone, '14911111111');
      expect(merged.emergencyPersonName, 'Paulo Silva');
      expect(merged.emergencyPhone, '14922222222');
    });
  });
}
