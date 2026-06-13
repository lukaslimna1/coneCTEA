import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/models/account_change_request.dart';

class AccountChangePresentation {
  final AccountChangeRequest request;

  const AccountChangePresentation(this.request);

  /// Label humanizado para o tipo da alteração.
  String get typeLabel {
    switch (request.type) {
      case AccountChangeType.email:
        return 'E-mail';
      case AccountChangeType.cpf:
        return 'CPF';
      case AccountChangeType.unknown:
        return 'Alteração de conta';
    }
  }

  /// Ícone representativo para o tipo da alteração.
  IconData get typeIcon {
    switch (request.type) {
      case AccountChangeType.email:
        return PhosphorIconsRegular.envelope;
      case AccountChangeType.cpf:
        return PhosphorIconsRegular.identificationCard;
      case AccountChangeType.unknown:
        return PhosphorIconsRegular.question;
    }
  }

  /// Label humanizado para o status da alteração.
  String get statusLabel {
    switch (request.status) {
      case AccountChangeStatus.applying:
        return 'ALTERAÇÃO EM ANDAMENTO';
      case AccountChangeStatus.completed:
        return 'ALTERAÇÃO CONCLUÍDA';
      case AccountChangeStatus.applicationFailed:
        return 'ALTERAÇÃO NÃO CONCLUÍDA';
      case AccountChangeStatus.waitingDocumentReplacement:
        return 'NOVO DOCUMENTO NECESSÁRIO';
      case AccountChangeStatus.underReview:
        return 'EM ANÁLISE';
      case AccountChangeStatus.waitingHolderConfirmation:
        return 'CONFIRMAÇÃO PENDENTE';
      case AccountChangeStatus.rejectedByAdmin:
        return 'NÃO APROVADA';
      case AccountChangeStatus.cancelledByHolder:
        return 'ENCERRADA POR VOCÊ';
      case AccountChangeStatus.expired:
        return 'PRAZO ENCERRADO';
      case AccountChangeStatus.unknown:
        return 'STATUS EM ATUALIZAÇÃO';
    }
  }

  /// Título explicativo para o status da alteração.
  String get statusTitle {
    switch (request.status) {
      case AccountChangeStatus.applying:
        return request.type == AccountChangeType.email
            ? 'Atualizando e-mail'
            : 'Atualizando CPF';
      case AccountChangeStatus.completed:
        return request.type == AccountChangeType.email
            ? 'E-mail atualizado'
            : 'CPF atualizado';
      case AccountChangeStatus.applicationFailed:
        return request.type == AccountChangeType.email
            ? 'Não foi possível atualizar o e-mail'
            : 'Não foi possível atualizar o CPF';
      case AccountChangeStatus.waitingDocumentReplacement:
        return 'Envie outro documento';
      case AccountChangeStatus.underReview:
        return 'Solicitação em análise';
      case AccountChangeStatus.waitingHolderConfirmation:
        return request.type == AccountChangeType.email
            ? 'Revise o novo e-mail'
            : 'Revise o novo CPF';
      case AccountChangeStatus.rejectedByAdmin:
        return 'Solicitação não aprovada';
      case AccountChangeStatus.cancelledByHolder:
        return 'Solicitação encerrada';
      case AccountChangeStatus.expired:
        return 'Solicitação expirada';
      case AccountChangeStatus.unknown:
        return 'Status em atualização';
    }
  }

  /// Ícone representativo para o status da alteração.
  IconData get statusIcon {
    switch (request.status) {
      case AccountChangeStatus.applying:
        return PhosphorIconsRegular.arrowsClockwise;
      case AccountChangeStatus.completed:
        return PhosphorIconsRegular.checkCircle;
      case AccountChangeStatus.applicationFailed:
        return PhosphorIconsRegular.warningOctagon;
      case AccountChangeStatus.waitingDocumentReplacement:
        return PhosphorIconsRegular.fileArrowUp;
      case AccountChangeStatus.underReview:
        return PhosphorIconsRegular.magnifyingGlass;
      case AccountChangeStatus.waitingHolderConfirmation:
        return PhosphorIconsRegular.userFocus;
      case AccountChangeStatus.rejectedByAdmin:
        return PhosphorIconsRegular.xCircle;
      case AccountChangeStatus.cancelledByHolder:
        return PhosphorIconsRegular.minusCircle;
      case AccountChangeStatus.expired:
        return PhosphorIconsRegular.clockCountdown;
      case AccountChangeStatus.unknown:
        return PhosphorIconsRegular.clock;
    }
  }

  /// Retorna se a requisição está em andamento/pendente.
  bool get isOngoing {
    switch (request.status) {
      case AccountChangeStatus.applying:
      case AccountChangeStatus.waitingDocumentReplacement:
      case AccountChangeStatus.underReview:
      case AccountChangeStatus.waitingHolderConfirmation:
      case AccountChangeStatus.applicationFailed:
      case AccountChangeStatus.unknown:
        return true;
      case AccountChangeStatus.completed:
      case AccountChangeStatus.rejectedByAdmin:
      case AccountChangeStatus.cancelledByHolder:
      case AccountChangeStatus.expired:
        return false;
    }
  }

  /// Resolve o token de cor visual correspondente ao status da alteração.
  DsCorVisual get visualToken {
    switch (request.status) {
      case AccountChangeStatus.completed:
        return DsCores.sucesso;
      case AccountChangeStatus.rejectedByAdmin:
      case AccountChangeStatus.applicationFailed:
        return DsCores.perigo;
      case AccountChangeStatus.waitingHolderConfirmation:
        return DsCores.alerta;
      case AccountChangeStatus.waitingDocumentReplacement:
        return DsCores.correcao;
      case AccountChangeStatus.applying:
        return DsCores.solicitacao;
      case AccountChangeStatus.underReview:
        return DsCores.comunicacao;
      case AccountChangeStatus.cancelledByHolder:
      case AccountChangeStatus.expired:
        return DsCores.manutencao;
      case AccountChangeStatus.unknown:
        return DsCores.fallback;
    }
  }

  /// Descrição curta para cada status da alteração.
  String get statusDescription {
    switch (request.status) {
      case AccountChangeStatus.applying:
        return 'A alteração confirmada está sendo concluída.';
      case AccountChangeStatus.completed:
        return 'A alteração foi concluída com sucesso.';
      case AccountChangeStatus.applicationFailed:
        return 'Seus dados atuais continuam ativos e esta solicitação foi preservada.';
      case AccountChangeStatus.waitingDocumentReplacement:
        return 'A equipe solicitou um novo documento para continuar a análise da alteração do CPF.';
      case AccountChangeStatus.underReview:
        return 'A equipe está analisando os dados e o documento enviados para a alteração do CPF.';
      case AccountChangeStatus.waitingHolderConfirmation:
        return 'Confira os dados antes de concluir a alteração.';
      case AccountChangeStatus.rejectedByAdmin:
        return 'A equipe não pôde aprovar a alteração com os dados enviados.';
      case AccountChangeStatus.cancelledByHolder:
        return 'A alteração não foi realizada e seus dados anteriores continuam ativos.';
      case AccountChangeStatus.expired:
        return 'O prazo para concluir esta etapa terminou e a alteração não foi realizada.';
      case AccountChangeStatus.unknown:
        return 'O status está sendo atualizado.';
    }
  }
}
