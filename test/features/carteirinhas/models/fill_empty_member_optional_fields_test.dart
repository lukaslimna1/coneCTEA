import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_params.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_result.dart';

void main() {
  group('FillEmptyMemberOptionalFieldsParams Tests', () {
    test(
      '1. parâmetros completos: toRpcParams com todos os campos preenchidos e válidos',
      () {
        final params = FillEmptyMemberOptionalFieldsParams(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: 'A+',
          phone: '14999999999',
          racaCor: 'Parda',
          gender: 'Masculino',
          cid: 'F84.0',
          responsiblePersonName: 'João Silva',
          responsiblePhone: '14988888888',
          emergencyPersonName: 'Maria Silva',
          emergencyPhone: '14977777777',
        );

        final rpcParams = params.toRpcParams();

        expect(
          rpcParams['p_member_id'],
          'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
        );
        expect(rpcParams['p_blood_type'], 'A+');
        expect(rpcParams['p_phone'], '14999999999');
        expect(rpcParams['p_raca_cor'], 'Parda');
        expect(rpcParams['p_gender'], 'Masculino');
        expect(rpcParams['p_cid'], 'F84.0');
        expect(rpcParams['p_responsible_person_name'], 'João Silva');
        expect(rpcParams['p_responsible_phone'], '14988888888');
        expect(rpcParams['p_emergency_person_name'], 'Maria Silva');
        expect(rpcParams['p_emergency_phone'], '14977777777');
      },
    );

    test(
      '2. trim dos parâmetros: limpeza de textos nos parâmetros opcionais',
      () {
        final params = FillEmptyMemberOptionalFieldsParams(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: '  O-  ',
          phone: ' 14999999999 ',
          racaCor: ' Branca ',
          gender: ' Feminino ',
          cid: '  F84.0  ',
          responsiblePersonName: '  João Silva  ',
          responsiblePhone: '  14988888888  ',
          emergencyPersonName: '  Maria Silva  ',
          emergencyPhone: '  14977777777  ',
        );

        final rpcParams = params.toRpcParams();

        expect(rpcParams['p_blood_type'], 'O-');
        expect(rpcParams['p_phone'], '14999999999');
        expect(rpcParams['p_raca_cor'], 'Branca');
        expect(rpcParams['p_gender'], 'Feminino');
        expect(rpcParams['p_cid'], 'F84.0');
        expect(rpcParams['p_responsible_person_name'], 'João Silva');
        expect(rpcParams['p_responsible_phone'], '14988888888');
        expect(rpcParams['p_emergency_person_name'], 'Maria Silva');
        expect(rpcParams['p_emergency_phone'], '14977777777');
      },
    );

    test(
      '3. opcionais vazios convertidos para null: strings contendo apenas espaços',
      () {
        final params = FillEmptyMemberOptionalFieldsParams(
          memberId: 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
          bloodType: '   ',
          phone: '',
          racaCor: null,
          gender: ' ',
        );

        final rpcParams = params.toRpcParams();

        expect(rpcParams['p_blood_type'], isNull);
        expect(rpcParams['p_phone'], isNull);
        expect(rpcParams['p_raca_cor'], isNull);
        expect(rpcParams['p_gender'], isNull);
        expect(rpcParams['p_cid'], isNull);
      },
    );

    test('4. memberId com espaços externos normalizado: trim é aplicado', () {
      final params = FillEmptyMemberOptionalFieldsParams(
        memberId: '   a3d07e60-4e56-4b8c-8c7e-976e1a123456   ',
      );

      expect(params.memberId, 'a3d07e60-4e56-4b8c-8c7e-976e1a123456');
    });

    test('5. memberId vazio rejeitado: lança ArgumentError', () {
      expect(
        () => FillEmptyMemberOptionalFieldsParams(memberId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      '6. memberId somente com espaços rejeitado: lança ArgumentError após o trim',
      () {
        expect(
          () => FillEmptyMemberOptionalFieldsParams(memberId: '     '),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('FillEmptyMemberOptionalFieldsResult Tests (V2)', () {
    final Map<String, dynamic> validResultMap = {
      'member_id': 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
      'blood_type': 'A+',
      'phone': '14999999999',
      'raca_cor': 'Parda',
      'gender': 'Masculino',
      'cid': 'F84.0',
      'responsible_person_name': 'João Silva',
      'responsible_phone': '14988888888',
      'emergency_person_name': 'Maria Silva',
      'emergency_phone': '14977777777',
      'applied_fields': ['blood_type', 'phone', 'responsible_person_name'],
      'preserved_fields': ['cid'],
      'changed': true,
    };

    test(
      '7. retorno completo da V2 com quatro campos estruturados preenchidos',
      () {
        final result = FillEmptyMemberOptionalFieldsResult.fromJson(
          validResultMap,
        );

        expect(result.memberId, 'a3d07e60-4e56-4b8c-8c7e-976e1a123456');
        expect(result.bloodType, 'A+');
        expect(result.phone, '14999999999');
        expect(result.racaCor, 'Parda');
        expect(result.gender, 'Masculino');
        expect(result.cid, 'F84.0');

        expect(result.responsiblePersonName, 'João Silva');
        expect(result.responsiblePhone, '14988888888');
        expect(result.emergencyPersonName, 'Maria Silva');
        expect(result.emergencyPhone, '14977777777');

        expect(
          result.appliedFields,
          containsAll(['blood_type', 'phone', 'responsible_person_name']),
        );
        expect(result.preservedFields, contains('cid'));
        expect(result.changed, isTrue);
      },
    );

    test('8. retorno com quatro campos estruturados nulos', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['responsible_person_name'] = null
        ..['responsible_phone'] = null
        ..['emergency_person_name'] = null
        ..['emergency_phone'] = null;

      final result = FillEmptyMemberOptionalFieldsResult.fromJson(resultMap);

      expect(result.responsiblePersonName, isNull);
      expect(result.responsiblePhone, isNull);
      expect(result.emergencyPersonName, isNull);
      expect(result.emergencyPhone, isNull);
    });

    test('9. allowlist aceita os quatro novos identificadores', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['responsible_person_name', 'responsible_phone']
        ..['preserved_fields'] = ['emergency_person_name', 'emergency_phone'];

      final result = FillEmptyMemberOptionalFieldsResult.fromJson(resultMap);

      expect(
        result.appliedFields,
        containsAll(['responsible_person_name', 'responsible_phone']),
      );
      expect(
        result.preservedFields,
        containsAll(['emergency_person_name', 'emergency_phone']),
      );
    });

    test('10. allowlist rejeita responsible_name legado', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['responsible_name'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('11. allowlist rejeita emergency_contact legado', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['preserved_fields'] = ['emergency_contact'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('12. campo desconhecido gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 'campo_invalido_de_teste'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('13. duplicidade em applied_fields gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 'phone', 'blood_type'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('14. interseção entre applied e preserved gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 'phone']
        ..['preserved_fields'] = ['phone', 'cid'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('15. item não String gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 12345];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('16. member_id ausente ou vazio gera FormatException', () {
      final resultMap1 = Map<String, dynamic>.from(validResultMap)
        ..remove('member_id');
      final resultMap2 = Map<String, dynamic>.from(validResultMap)
        ..['member_id'] = '   ';

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap1),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap2),
        throwsA(isA<FormatException>()),
      );
    });

    test('17. changed ausente ou inválido gera FormatException', () {
      final resultMap1 = Map<String, dynamic>.from(validResultMap)
        ..remove('changed');
      final resultMap2 = Map<String, dynamic>.from(validResultMap)
        ..['changed'] = 'true';

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap1),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap2),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
