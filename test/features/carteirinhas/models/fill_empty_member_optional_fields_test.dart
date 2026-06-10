import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_params.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_result.dart';

void main() {
  group('FillEmptyMemberOptionalFieldsParams Tests', () {
    test('1. parâmetros completos: toRpcParams com todos os campos preenchidos e válidos', () {
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

      expect(rpcParams['p_member_id'], 'a3d07e60-4e56-4b8c-8c7e-976e1a123456');
      expect(rpcParams['p_blood_type'], 'A+');
      expect(rpcParams['p_phone'], '14999999999');
      expect(rpcParams['p_raca_cor'], 'Parda');
      expect(rpcParams['p_gender'], 'Masculino');
      expect(rpcParams['p_cid'], 'F84.0');
      expect(rpcParams['p_responsible_person_name'], 'João Silva');
      expect(rpcParams['p_responsible_phone'], '14988888888');
      expect(rpcParams['p_emergency_person_name'], 'Maria Silva');
      expect(rpcParams['p_emergency_phone'], '14977777777');
    });

    test('2. trim dos parâmetros: limpeza de textos nos parâmetros opcionais', () {
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
    });

    test('3. opcionais vazios convertidos para null: strings contendo apenas espaços', () {
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
    });

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

    test('6. memberId somente com espaços rejeitado: lança ArgumentError após o trim', () {
      expect(
        () => FillEmptyMemberOptionalFieldsParams(memberId: '     '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FillEmptyMemberOptionalFieldsResult Tests', () {
    final Map<String, dynamic> validResultMap = {
      'member_id': 'a3d07e60-4e56-4b8c-8c7e-976e1a123456',
      'blood_type': 'A+',
      'phone': '14999999999',
      'raca_cor': 'Parda',
      'gender': 'Masculino',
      'cid': 'F84.0',
      'responsible_name': 'João Silva - 14988888888',
      'emergency_contact': 'Maria Silva - 14977777777',
      'applied_fields': ['blood_type', 'phone'],
      'preserved_fields': ['cid'],
      'changed': true,
    };

    test('7. resultado completo válido parseado com sucesso', () {
      final result = FillEmptyMemberOptionalFieldsResult.fromJson(validResultMap);

      expect(result.memberId, 'a3d07e60-4e56-4b8c-8c7e-976e1a123456');
      expect(result.bloodType, 'A+');
      expect(result.phone, '14999999999');
      expect(result.racaCor, 'Parda');
      expect(result.gender, 'Masculino');
      expect(result.cid, 'F84.0');
      expect(result.responsibleName, 'João Silva - 14988888888');
      expect(result.emergencyContact, 'Maria Silva - 14977777777');
      expect(result.appliedFields, containsAll(['blood_type', 'phone']));
      expect(result.preservedFields, contains('cid'));
      expect(result.changed, isTrue);
    });

    test('8. campos text nulos tratados: obrigatórios viram string vazia, opcionais viram null', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['raca_cor'] = null
        ..['gender'] = null
        ..['blood_type'] = null;

      final result = FillEmptyMemberOptionalFieldsResult.fromJson(resultMap);

      expect(result.racaCor, isNull);
      expect(result.gender, isNull);
      expect(result.bloodType, '');
    });

    test('9. applied_fields válido parseado e retornado como List.unmodifiable', () {
      final result = FillEmptyMemberOptionalFieldsResult.fromJson(validResultMap);

      expect(result.appliedFields, containsAll(['blood_type', 'phone']));
      expect(
        () => result.appliedFields.add('raca_cor'),
        throwsUnsupportedError,
      );
    });

    test('10. preserved_fields válido parseado e retornado como List.unmodifiable', () {
      final result = FillEmptyMemberOptionalFieldsResult.fromJson(validResultMap);

      expect(result.preservedFields, contains('cid'));
      expect(
        () => result.preservedFields.add('gender'),
        throwsUnsupportedError,
      );
    });

    test('11. campo desconhecido em applied_fields gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 'campo_invalido_de_teste'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('12. campo desconhecido em preserved_fields gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['preserved_fields'] = ['cid', 'outro_campo_invalido'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('13. item não String em applied_fields gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 12345];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('14. item não String em preserved_fields gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['preserved_fields'] = [true, 'cid'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('15. duplicidade em applied_fields gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 'phone', 'blood_type'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('16. duplicidade em preserved_fields gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['preserved_fields'] = ['cid', 'cid'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('17. mesmo campo presente em applied e preserved (interseção) gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = ['blood_type', 'phone']
        ..['preserved_fields'] = ['phone', 'cid'];

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('18. member_id ausente gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)..remove('member_id');

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('19. member_id vazio gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)..['member_id'] = '   ';

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('20. member_id de tipo inválido gera FormatException', () {
      // member_id como número inteiro é convertido para String e testado.
      // O parser atual faz rawMemberId.toString().trim().isEmpty. Para ser verdadeiramente estrito de tipo:
      // se não for String ou se for vazio gera FormatException.
      // Como o design do parse aceita converter UUIDs puros (pode vir como dynamic representável),
      // o teste garante que se vier nulo ou vazio lança erro. Mas se for tipo inválido como um Map, lança erro.
      final resultMapMap = Map<String, dynamic>.from(validResultMap)..['member_id'] = {'id': 'uuid'};
      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMapMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('21. changed ausente gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)..remove('changed');

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('22. changed de tipo inválido gera FormatException', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)..['changed'] = 'true';

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('23. arrays que não são List geram FormatException', () {
      final resultMap1 = Map<String, dynamic>.from(validResultMap)..['applied_fields'] = 'blood_type';
      final resultMap2 = Map<String, dynamic>.from(validResultMap)..['preserved_fields'] = 12345;

      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap1),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => FillEmptyMemberOptionalFieldsResult.fromJson(resultMap2),
        throwsA(isA<FormatException>()),
      );
    });

    test('24. retorno válido com listas vazias', () {
      final resultMap = Map<String, dynamic>.from(validResultMap)
        ..['applied_fields'] = []
        ..['preserved_fields'] = [];

      final result = FillEmptyMemberOptionalFieldsResult.fromJson(resultMap);

      expect(result.appliedFields, isEmpty);
      expect(result.preservedFields, isEmpty);
    });
  });
}
