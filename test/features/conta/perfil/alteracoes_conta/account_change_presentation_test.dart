import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_change_presentation.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';

void main() {
  group('AccountChangePresentation Tests', () {
    AccountChangeRequest createMockRequest({
      required AccountChangeStatus status,
      required AccountChangeType type,
    }) {
      return AccountChangeRequest(
        id: 'test-id',
        protocolNumber: 'AC-20260612-A1B2C3D4',
        type: type,
        status: status,
        newValueMasked: 'new-value',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
    }

    test(
      '1. waitingDocumentReplacement é classificado como em andamento (isOngoing == true)',
      () {
        final req = createMockRequest(
          status: AccountChangeStatus.waitingDocumentReplacement,
          type: AccountChangeType.cpf,
        );
        final pres = AccountChangePresentation(req);
        expect(pres.isOngoing, isTrue);
      },
    );

    test('2. expired é classificado como histórico (isOngoing == false)', () {
      final req = createMockRequest(
        status: AccountChangeStatus.expired,
        type: AccountChangeType.cpf,
      );
      final pres = AccountChangePresentation(req);
      expect(pres.isOngoing, isFalse);
    });

    test(
      '3. applicationFailed permanece classificado como em andamento (isOngoing == true)',
      () {
        final req = createMockRequest(
          status: AccountChangeStatus.applicationFailed,
          type: AccountChangeType.cpf,
        );
        final pres = AccountChangePresentation(req);
        expect(pres.isOngoing, isTrue);
      },
    );

    test(
      '4. unknown permanece classificado como em andamento (isOngoing == true)',
      () {
        final req = createMockRequest(
          status: AccountChangeStatus.unknown,
          type: AccountChangeType.cpf,
        );
        final pres = AccountChangePresentation(req);
        expect(pres.isOngoing, isTrue);
      },
    );

    test('5. Labels e títulos dos novos status', () {
      final reqDoc = createMockRequest(
        status: AccountChangeStatus.waitingDocumentReplacement,
        type: AccountChangeType.cpf,
      );
      final presDoc = AccountChangePresentation(reqDoc);
      expect(presDoc.statusLabel, 'NOVO DOCUMENTO NECESSÁRIO');
      expect(presDoc.statusTitle, 'Envie outro documento');

      final reqExp = createMockRequest(
        status: AccountChangeStatus.expired,
        type: AccountChangeType.cpf,
      );
      final presExp = AccountChangePresentation(reqExp);
      expect(presExp.statusLabel, 'PRAZO ENCERRADO');
      expect(presExp.statusTitle, 'Solicitação expirada');
    });

    test(
      '6. Intenção visual de waitingDocumentReplacement é DsCores.correcao',
      () {
        final req = createMockRequest(
          status: AccountChangeStatus.waitingDocumentReplacement,
          type: AccountChangeType.cpf,
        );
        final pres = AccountChangePresentation(req);
        expect(pres.visualToken, DsCores.correcao);
      },
    );

    test('7. Intenção visual de expired não utiliza sucesso', () {
      final req = createMockRequest(
        status: AccountChangeStatus.expired,
        type: AccountChangeType.cpf,
      );
      final pres = AccountChangePresentation(req);
      expect(pres.visualToken, isNot(equals(DsCores.sucesso)));
    });

    test('8. Títulos dependentes de tipo para waitingHolderConfirmation', () {
      final reqEmail = createMockRequest(
        status: AccountChangeStatus.waitingHolderConfirmation,
        type: AccountChangeType.email,
      );
      expect(
        AccountChangePresentation(reqEmail).statusTitle,
        'Revise o novo e-mail',
      );

      final reqCpf = createMockRequest(
        status: AccountChangeStatus.waitingHolderConfirmation,
        type: AccountChangeType.cpf,
      );
      expect(
        AccountChangePresentation(reqCpf).statusTitle,
        'Revise o novo CPF',
      );
    });

    test('9. Títulos dependentes de tipo para applying', () {
      final reqEmail = createMockRequest(
        status: AccountChangeStatus.applying,
        type: AccountChangeType.email,
      );
      expect(
        AccountChangePresentation(reqEmail).statusTitle,
        'Atualizando e-mail',
      );

      final reqCpf = createMockRequest(
        status: AccountChangeStatus.applying,
        type: AccountChangeType.cpf,
      );
      expect(AccountChangePresentation(reqCpf).statusTitle, 'Atualizando CPF');
    });

    test('10. Títulos dependentes de tipo para applicationFailed', () {
      final reqEmail = createMockRequest(
        status: AccountChangeStatus.applicationFailed,
        type: AccountChangeType.email,
      );
      expect(
        AccountChangePresentation(reqEmail).statusTitle,
        'Não foi possível atualizar o e-mail',
      );

      final reqCpf = createMockRequest(
        status: AccountChangeStatus.applicationFailed,
        type: AccountChangeType.cpf,
      );
      expect(
        AccountChangePresentation(reqCpf).statusTitle,
        'Não foi possível atualizar o CPF',
      );
    });

    test('11. Títulos dependentes de tipo para completed', () {
      final reqEmail = createMockRequest(
        status: AccountChangeStatus.completed,
        type: AccountChangeType.email,
      );
      expect(
        AccountChangePresentation(reqEmail).statusTitle,
        'E-mail atualizado',
      );

      final reqCpf = createMockRequest(
        status: AccountChangeStatus.completed,
        type: AccountChangeType.cpf,
      );
      expect(AccountChangePresentation(reqCpf).statusTitle, 'CPF atualizado');
    });

    test('12. Descrição final de applicationFailed', () {
      final req = createMockRequest(
        status: AccountChangeStatus.applicationFailed,
        type: AccountChangeType.cpf,
      );
      final pres = AccountChangePresentation(req);
      expect(
        pres.statusDescription,
        'Seus dados atuais continuam ativos e esta solicitação foi preservada.',
      );
    });

    test(
      '13. Label, título e descrição detalhados de waitingDocumentReplacement',
      () {
        final req = createMockRequest(
          status: AccountChangeStatus.waitingDocumentReplacement,
          type: AccountChangeType.cpf,
        );
        final pres = AccountChangePresentation(req);
        expect(pres.statusLabel, 'NOVO DOCUMENTO NECESSÁRIO');
        expect(pres.statusTitle, 'Envie outro documento');
        expect(
          pres.statusDescription,
          'A equipe solicitou um novo documento para continuar a análise da alteração do CPF.',
        );
        expect(pres.isOngoing, isTrue);
      },
    );

    test('14. Label, título e descrição detalhados de expired', () {
      final req = createMockRequest(
        status: AccountChangeStatus.expired,
        type: AccountChangeType.cpf,
      );
      final pres = AccountChangePresentation(req);
      expect(pres.statusLabel, 'PRAZO ENCERRADO');
      expect(pres.statusTitle, 'Solicitação expirada');
      expect(
        pres.statusDescription,
        'O prazo para concluir esta etapa terminou e a alteração não foi realizada.',
      );
      expect(pres.isOngoing, isFalse);
    });
  });
}
