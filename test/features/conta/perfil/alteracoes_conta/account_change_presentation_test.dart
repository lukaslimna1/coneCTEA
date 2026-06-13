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

    // --- NOVOS TESTES DE APRESENTAÇÃO DA MICROFRENTE 3C.5B.1 ---
    AccountChangeRequest createExtendedMockRequest({
      required AccountChangeStatus status,
      required AccountChangeType type,
      AccountChangeCivilDate? holderDeadlineDueDate,
      AccountChangeResolutionReason resolutionReason =
          AccountChangeResolutionReason.unknown,
      AccountChangePublicAdminReasonCode publicAdminReasonCode =
          AccountChangePublicAdminReasonCode.unknown,
      String? publicAdminFeedback,
      DateTime? closedAt,
    }) {
      return AccountChangeRequest(
        id: 'test-id',
        protocolNumber: 'AC-20260612-A1B2C3D4',
        type: type,
        status: status,
        newValueMasked: 'new-value',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        holderDeadlineDueDate: holderDeadlineDueDate,
        resolutionReason: resolutionReason,
        publicAdminReasonCode: publicAdminReasonCode,
        publicAdminFeedback: publicAdminFeedback,
        closedAt: closedAt,
      );
    }

    test(
      '15. Formatação da data civil com preenchimento à esquerda e 4 dígitos',
      () {
        final dateNormal = AccountChangeCivilDate(year: 2026, month: 1, day: 5);
        final dateMin = AccountChangeCivilDate(year: 1, month: 1, day: 1);

        expect(
          AccountChangePresentation.formatCivilDate(dateNormal),
          '05/01/2026',
        );
        expect(
          AccountChangePresentation.formatCivilDate(dateMin),
          '01/01/0001',
        );
      },
    );

    test('16. Prazo do titular visível apenas nos status permitidos', () {
      final deadline = AccountChangeCivilDate(year: 2026, month: 6, day: 25);

      final reqReplacement = createExtendedMockRequest(
        status: AccountChangeStatus.waitingDocumentReplacement,
        type: AccountChangeType.cpf,
        holderDeadlineDueDate: deadline,
      );
      final presReplacement = AccountChangePresentation(reqReplacement);
      expect(presReplacement.canShowHolderDeadline, isTrue);
      expect(
        presReplacement.holderDeadlineText,
        'Prazo para sua ação: até 25/06/2026.',
      );

      final reqConfirmation = createExtendedMockRequest(
        status: AccountChangeStatus.waitingHolderConfirmation,
        type: AccountChangeType.cpf,
        holderDeadlineDueDate: deadline,
      );
      final presConfirmation = AccountChangePresentation(reqConfirmation);
      expect(presConfirmation.canShowHolderDeadline, isTrue);
      expect(
        presConfirmation.holderDeadlineText,
        'Prazo para sua ação: até 25/06/2026.',
      );
    });

    test(
      '17. Prazo do titular ocultado em status ativos não permitidos e terminais',
      () {
        final deadline = AccountChangeCivilDate(year: 2026, month: 6, day: 25);

        final statuses = [
          AccountChangeStatus.underReview,
          AccountChangeStatus.applying,
          AccountChangeStatus.applicationFailed,
          AccountChangeStatus.completed,
          AccountChangeStatus.rejectedByAdmin,
          AccountChangeStatus.cancelledByHolder,
          AccountChangeStatus.expired,
        ];

        for (final status in statuses) {
          final req = createExtendedMockRequest(
            status: status,
            type: AccountChangeType.cpf,
            holderDeadlineDueDate: deadline,
          );
          final pres = AccountChangePresentation(req);
          expect(
            pres.canShowHolderDeadline,
            isFalse,
            reason: 'Deveria ocultar prazo no status: $status',
          );
          expect(pres.holderDeadlineText, isNull);
        }
      },
    );

    test(
      '18. Motivos de resolução retornam seus textos explicativos corretos',
      () {
        final mapping = {
          AccountChangeResolutionReason.cancelledDuringReview:
              'Você encerrou a solicitação enquanto ela estava em análise.',
          AccountChangeResolutionReason.cancelledWhileWaitingDocument:
              'Você encerrou a solicitação enquanto aguardávamos o novo documento.',
          AccountChangeResolutionReason.declinedFinalConfirmation:
              'Você decidiu não concluir a alteração.',
          AccountChangeResolutionReason.documentReplacementDeadline:
              'O prazo para enviar um novo documento terminou.',
          AccountChangeResolutionReason.holderConfirmationDeadline:
              'O prazo para confirmar a alteração terminou.',
        };

        for (final entry in mapping.entries) {
          final req = createExtendedMockRequest(
            status: AccountChangeStatus.cancelledByHolder,
            type: AccountChangeType.cpf,
            resolutionReason: entry.key,
          );
          final pres = AccountChangePresentation(req);
          expect(pres.canShowResolutionReason, isTrue);
          expect(pres.resolutionReasonText, entry.value);
        }
      },
    );

    test(
      '19. Motivo de resolução ocultado fora de cancelledByHolder e expired',
      () {
        final statuses = [
          AccountChangeStatus.underReview,
          AccountChangeStatus.applying,
          AccountChangeStatus.applicationFailed,
          AccountChangeStatus.completed,
          AccountChangeStatus.rejectedByAdmin,
          AccountChangeStatus.waitingDocumentReplacement,
          AccountChangeStatus.waitingHolderConfirmation,
        ];

        for (final status in statuses) {
          final req = createExtendedMockRequest(
            status: status,
            type: AccountChangeType.cpf,
            resolutionReason:
                AccountChangeResolutionReason.cancelledDuringReview,
          );
          final pres = AccountChangePresentation(req);
          expect(pres.canShowResolutionReason, isFalse);
          expect(pres.resolutionReasonText, isNull);
        }
      },
    );

    test('20. Motivo de resolução unknown ou nulo retorna nulo', () {
      final req = createExtendedMockRequest(
        status: AccountChangeStatus.cancelledByHolder,
        type: AccountChangeType.cpf,
        resolutionReason: AccountChangeResolutionReason.unknown,
      );
      final pres = AccountChangePresentation(req);
      expect(pres.canShowResolutionReason, isFalse);
      expect(pres.resolutionReasonText, isNull);
    });

    test(
      '21. Orientação administrativa visível apenas nos status permitidos',
      () {
        final reqReplacement = createExtendedMockRequest(
          status: AccountChangeStatus.waitingDocumentReplacement,
          type: AccountChangeType.cpf,
          publicAdminReasonCode:
              AccountChangePublicAdminReasonCode.unreadableDocument,
          publicAdminFeedback: 'Envie um documento legível',
        );
        final presReplacement = AccountChangePresentation(reqReplacement);
        expect(presReplacement.canShowPublicAdminGuidance, isTrue);
        expect(
          presReplacement.publicAdminReasonText,
          'Não foi possível ler o documento enviado.',
        );
        expect(
          presReplacement.publicAdminFeedbackText,
          'Envie um documento legível',
        );

        final reqRejected = createExtendedMockRequest(
          status: AccountChangeStatus.rejectedByAdmin,
          type: AccountChangeType.cpf,
          publicAdminReasonCode: AccountChangePublicAdminReasonCode.cpfMismatch,
          publicAdminFeedback: 'CPF incompatível',
        );
        final presRejected = AccountChangePresentation(reqRejected);
        expect(presRejected.canShowPublicAdminGuidance, isTrue);
        expect(
          presRejected.publicAdminReasonText,
          'O CPF no documento não confere com a alteração solicitada.',
        );
        expect(presRejected.publicAdminFeedbackText, 'CPF incompatível');
      },
    );

    test(
      '22. Orientação administrativa ocultada fora dos status permitidos',
      () {
        final statuses = [
          AccountChangeStatus.underReview,
          AccountChangeStatus.applying,
          AccountChangeStatus.applicationFailed,
          AccountChangeStatus.completed,
          AccountChangeStatus.cancelledByHolder,
          AccountChangeStatus.expired,
        ];

        for (final status in statuses) {
          final req = createExtendedMockRequest(
            status: status,
            type: AccountChangeType.cpf,
            publicAdminReasonCode:
                AccountChangePublicAdminReasonCode.unreadableDocument,
            publicAdminFeedback: 'Feedback antigo',
          );
          final pres = AccountChangePresentation(req);
          expect(pres.canShowPublicAdminGuidance, isFalse);
          expect(pres.publicAdminReasonText, isNull);
          expect(pres.publicAdminFeedbackText, isNull);
        }
      },
    );

    test('23. Código unknown sem feedback não gera orientação', () {
      final req = createExtendedMockRequest(
        status: AccountChangeStatus.rejectedByAdmin,
        type: AccountChangeType.cpf,
        publicAdminReasonCode: AccountChangePublicAdminReasonCode.unknown,
        publicAdminFeedback: null,
      );
      final pres = AccountChangePresentation(req);
      expect(pres.canShowPublicAdminGuidance, isFalse);
      expect(pres.publicAdminReasonText, isNull);
      expect(pres.publicAdminFeedbackText, isNull);
    });

    test('24. Feedback válido sem código ativa orientação', () {
      final req = createExtendedMockRequest(
        status: AccountChangeStatus.rejectedByAdmin,
        type: AccountChangeType.cpf,
        publicAdminReasonCode: AccountChangePublicAdminReasonCode.unknown,
        publicAdminFeedback: 'Ajuste de documento necessário',
      );
      final pres = AccountChangePresentation(req);
      expect(pres.canShowPublicAdminGuidance, isTrue);
      expect(pres.publicAdminReasonText, isNull);
      expect(pres.publicAdminFeedbackText, 'Ajuste de documento necessário');
    });

    test('25. Código válido sem feedback ativa orientação', () {
      final req = createExtendedMockRequest(
        status: AccountChangeStatus.rejectedByAdmin,
        type: AccountChangeType.cpf,
        publicAdminReasonCode: AccountChangePublicAdminReasonCode.other,
        publicAdminFeedback: null,
      );
      final pres = AccountChangePresentation(req);
      expect(pres.canShowPublicAdminGuidance, isTrue);
      expect(
        pres.publicAdminReasonText,
        'Precisamos de um ajuste no documento para continuar.',
      );
      expect(pres.publicAdminFeedbackText, isNull);
    });

    test('26. Mapeamento detalhado dos códigos administrativos públicos', () {
      final mapping = {
        AccountChangePublicAdminReasonCode.documentNotAccepted:
            'O documento enviado não pôde ser aceito.',
        AccountChangePublicAdminReasonCode.unreadableDocument:
            'Não foi possível ler o documento enviado.',
        AccountChangePublicAdminReasonCode.cpfNotVisible:
            'O CPF não está visível no documento.',
        AccountChangePublicAdminReasonCode.nameMismatch:
            'O nome no documento não confere com os dados cadastrados.',
        AccountChangePublicAdminReasonCode.birthDateMismatch:
            'A data de nascimento no documento não confere com os dados cadastrados.',
        AccountChangePublicAdminReasonCode.cpfMismatch:
            'O CPF no documento não confere com a alteração solicitada.',
        AccountChangePublicAdminReasonCode.other:
            'Precisamos de um ajuste no documento para continuar.',
      };

      for (final entry in mapping.entries) {
        final req = createExtendedMockRequest(
          status: AccountChangeStatus.rejectedByAdmin,
          type: AccountChangeType.cpf,
          publicAdminReasonCode: entry.key,
        );
        final pres = AccountChangePresentation(req);
        expect(pres.canShowPublicAdminGuidance, isTrue);
        expect(pres.publicAdminReasonText, entry.value);
      }
    });

    test('27. Data de encerramento visível apenas para status terminais', () {
      final closedDate = DateTime.now().toUtc();

      final terminalStatuses = [
        AccountChangeStatus.completed,
        AccountChangeStatus.rejectedByAdmin,
        AccountChangeStatus.cancelledByHolder,
        AccountChangeStatus.expired,
      ];

      for (final status in terminalStatuses) {
        final req = createExtendedMockRequest(
          status: status,
          type: AccountChangeType.cpf,
          closedAt: closedDate,
        );
        final pres = AccountChangePresentation(req);
        expect(
          pres.canShowClosedAt,
          isTrue,
          reason: 'Deveria mostrar encerramento no status: $status',
        );
      }
    });

    test('28. Data de encerramento ocultada em status ativos', () {
      final closedDate = DateTime.now().toUtc();

      final activeStatuses = [
        AccountChangeStatus.underReview,
        AccountChangeStatus.applying,
        AccountChangeStatus.applicationFailed,
        AccountChangeStatus.waitingDocumentReplacement,
        AccountChangeStatus.waitingHolderConfirmation,
      ];

      for (final status in activeStatuses) {
        final req = createExtendedMockRequest(
          status: status,
          type: AccountChangeType.cpf,
          closedAt: closedDate,
        );
        final pres = AccountChangePresentation(req);
        expect(
          pres.canShowClosedAt,
          isFalse,
          reason: 'Deveria ocultar encerramento no status: $status',
        );
      }
    });
  });
}
