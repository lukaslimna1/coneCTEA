import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/features/carteirinhas/utils/print_contacts_helper.dart';

void main() {
  group('PrintContactsHelper.getUiState - ', () {
    test('Cenário A: nome e telefone estruturados preenchidos -> ambos bloqueados', () {
      final state = PrintContactsHelper.getUiState(
        structuredName: 'João Silva',
        structuredPhone: '11999999999',
      );
      expect(state.uiState, PrintContactUiState.bothLocked);
    });

    test('Cenário B: nome estruturado presente + telefone estruturado vazio -> nome travado, tel editável', () {
      final state = PrintContactsHelper.getUiState(
        structuredName: 'João Silva',
        structuredPhone: '',
      );
      expect(state.uiState, PrintContactUiState.nameLockedPhoneEditable);
    });

    test('Cenário C: nome e telefone estruturados vazios -> ambos editáveis', () {
      final state = PrintContactsHelper.getUiState(
        structuredName: '',
        structuredPhone: '',
      );
      expect(state.uiState, PrintContactUiState.bothEditable);
    });
  });

  group('PrintContactsHelper.buildRpcParams - ', () {
    test('Enviar telefone novo quando nome estruturado já existe', () {
      final params = PrintContactsHelper.buildRpcParams(
        structuredName: 'João Silva',
        structuredPhone: '',
        inputName: '',
        inputPhone: '11999999999',
        isIncluded: true,
      );
      expect(params['name'], isNull);
      expect(params['phone'], '11999999999');
    });

    test('Enviar nome novo quando ambos vazios', () {
      final params = PrintContactsHelper.buildRpcParams(
        structuredName: '',
        structuredPhone: '',
        inputName: 'Maria Silva',
        inputPhone: '11888888888',
        isIncluded: true,
      );
      expect(params['name'], 'Maria Silva');
      expect(params['phone'], '11888888888');
    });

    test('Bloquear envio de apenas telefone se nome estruturado não existe e inputName é vazio', () {
      final params = PrintContactsHelper.buildRpcParams(
        structuredName: '',
        structuredPhone: '',
        inputName: '',
        inputPhone: '11999999999',
        isIncluded: true,
      );
      expect(params['name'], isNull);
      expect(params['phone'], isNull);
    });

    test('Ignorar quando isIncluded false', () {
      final params = PrintContactsHelper.buildRpcParams(
        structuredName: '',
        structuredPhone: '',
        inputName: 'Maria Silva',
        inputPhone: '11888888888',
        isIncluded: false,
      );
      expect(params['name'], isNull);
      expect(params['phone'], isNull);
    });
  });
}
