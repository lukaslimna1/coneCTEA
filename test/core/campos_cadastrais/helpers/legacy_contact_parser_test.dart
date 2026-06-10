import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/core/campos_cadastrais/helpers/legacy_contact_parser.dart';

void main() {
  group('LegacyContactParser Tests', () {
    test('1. null => empty', () {
      final result = LegacyContactParser.parse(null);
      expect(result.classification, LegacyContactClassification.empty);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, '');
    });

    test('2. string vazia => empty', () {
      final result = LegacyContactParser.parse('');
      expect(result.classification, LegacyContactClassification.empty);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, '');
    });

    test('3. somente espaços => empty', () {
      final result = LegacyContactParser.parse('     ');
      expect(result.classification, LegacyContactClassification.empty);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, '');
    });

    test('4. nome simples => nameOnly', () {
      final result = LegacyContactParser.parse('Fulano de Tal');
      expect(result.classification, LegacyContactClassification.nameOnly);
      expect(result.name, 'Fulano de Tal');
      expect(result.phone, isNull);
      expect(result.rawValue, 'Fulano de Tal');
    });

    test('5. nome com hífen simples sem espaços => nameOnly', () {
      final result = LegacyContactParser.parse('Ana-Maria');
      expect(result.classification, LegacyContactClassification.nameOnly);
      expect(result.name, 'Ana-Maria');
      expect(result.phone, isNull);
      expect(result.rawValue, 'Ana-Maria');
    });

    test('6. nome com separador " - " sem telefone => ambiguous', () {
      final result = LegacyContactParser.parse('Fulano - Ciclano');
      expect(result.classification, LegacyContactClassification.ambiguous);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, 'Fulano - Ciclano');
    });

    test('7. nome e telefone mascarado válido => complete', () {
      final result = LegacyContactParser.parse(
        'Fulano de Tal - (14) 99999-8888',
      );
      expect(result.classification, LegacyContactClassification.complete);
      expect(result.name, 'Fulano de Tal');
      expect(result.phone, '(14) 99999-8888');
      expect(result.rawValue, 'Fulano de Tal - (14) 99999-8888');
    });

    test('8. nome e telefone de 10 dígitos => complete', () {
      final result = LegacyContactParser.parse('Fulano de Tal - 1432221111');
      expect(result.classification, LegacyContactClassification.complete);
      expect(result.name, 'Fulano de Tal');
      expect(result.phone, '1432221111');
      expect(result.rawValue, 'Fulano de Tal - 1432221111');
    });

    test('9. nome e telefone de 11 dígitos => complete', () {
      final result = LegacyContactParser.parse('Fulano de Tal - 14999998888');
      expect(result.classification, LegacyContactClassification.complete);
      expect(result.name, 'Fulano de Tal');
      expect(result.phone, '14999998888');
      expect(result.rawValue, 'Fulano de Tal - 14999998888');
    });

    test(
      '10. múltiplos separadores e telefone válido no final => complete',
      () {
        final result = LegacyContactParser.parse(
          'Fulano - Diretor - (14) 99999-8888',
        );
        expect(result.classification, LegacyContactClassification.complete);
        expect(result.name, 'Fulano - Diretor');
        expect(result.phone, '(14) 99999-8888');
        expect(result.rawValue, 'Fulano - Diretor - (14) 99999-8888');
      },
    );

    test('11. telefone válido isolado => phoneOnlyLegacy', () {
      final result = LegacyContactParser.parse('(14) 99999-8888');
      expect(
        result.classification,
        LegacyContactClassification.phoneOnlyLegacy,
      );
      expect(result.name, isNull);
      expect(result.phone, '(14) 99999-8888');
      expect(result.rawValue, '(14) 99999-8888');
    });

    test('12. telefone isolado de dígitos repetidos => ambiguous', () {
      final result = LegacyContactParser.parse('99999999999');
      expect(result.classification, LegacyContactClassification.ambiguous);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, '99999999999');
    });

    test('13. nome com números sem telefone válido => ambiguous', () {
      final result = LegacyContactParser.parse('Lucas123');
      expect(result.classification, LegacyContactClassification.ambiguous);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, 'Lucas123');
    });

    test('14. parte final com telefone curto => ambiguous', () {
      final result = LegacyContactParser.parse('Fulano - 9999');
      expect(result.classification, LegacyContactClassification.ambiguous);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, 'Fulano - 9999');
    });

    test('15. parte final com telefone longo => ambiguous', () {
      final result = LegacyContactParser.parse('Fulano - 1499999888877');
      expect(result.classification, LegacyContactClassification.ambiguous);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, 'Fulano - 1499999888877');
    });

    test('16. telefone repetido após separador => ambiguous', () {
      final result = LegacyContactParser.parse('Fulano - 99999999999');
      expect(result.classification, LegacyContactClassification.ambiguous);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, 'Fulano - 99999999999');
    });

    test(
      '17. separador com parte esquerda vazia e telefone válido => phoneOnlyLegacy',
      () {
        // Justificativa: Como não existe nome útil antes do separador, tratamos como apenas telefone presente,
        // preservando a informação única de contato telefônico e mantendo a consistência.
        final result = LegacyContactParser.parse(' - (14) 99999-8888');
        expect(
          result.classification,
          LegacyContactClassification.phoneOnlyLegacy,
        );
        expect(result.name, isNull);
        expect(result.phone, '(14) 99999-8888');
        expect(result.rawValue, '- (14) 99999-8888');
      },
    );

    test('18. espaços externos são removidos', () {
      final result = LegacyContactParser.parse(
        '   Fulano de Tal - (14) 99999-8888   ',
      );
      expect(result.classification, LegacyContactClassification.complete);
      expect(result.name, 'Fulano de Tal');
      expect(result.phone, '(14) 99999-8888');
      expect(result.rawValue, 'Fulano de Tal - (14) 99999-8888');
    });

    test('19. rawValue preserva conteúdo interno', () {
      final result = LegacyContactParser.parse(
        'Fulano   de   Tal - (14) 99999-8888',
      );
      expect(result.classification, LegacyContactClassification.complete);
      expect(result.name, 'Fulano   de   Tal');
      expect(result.phone, '(14) 99999-8888');
      expect(result.rawValue, 'Fulano   de   Tal - (14) 99999-8888');
    });

    test('20. parser não lança exceção com caracteres especiais comuns', () {
      final result = LegacyContactParser.parse(
        'Fulano @#%&*()_+[]{}? - (14) 99999-8888',
      );
      expect(result.classification, LegacyContactClassification.complete);
      expect(result.name, 'Fulano @#%&*()_+[]{}?');
      expect(result.phone, '(14) 99999-8888');
      expect(result.rawValue, 'Fulano @#%&*()_+[]{}? - (14) 99999-8888');
    });

    test('21. separador final vazio => ambiguous', () {
      final result = LegacyContactParser.parse('Fulano - ');
      expect(result.classification, LegacyContactClassification.ambiguous);
      expect(result.name, isNull);
      expect(result.phone, isNull);
      expect(result.rawValue, 'Fulano -');
    });
  });
}
