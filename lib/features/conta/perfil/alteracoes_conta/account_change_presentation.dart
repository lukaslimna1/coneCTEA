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
        return 'Aplicando alteração';
      case AccountChangeStatus.completed:
        return 'Alteração concluída';
      case AccountChangeStatus.applicationFailed:
        return 'Ação necessária';
      case AccountChangeStatus.waitingProof:
        return 'Aguardando documento';
      case AccountChangeStatus.underReview:
        return 'Em análise';
      case AccountChangeStatus.waitingHolderConfirmation:
        return 'Aguardando sua confirmação';
      case AccountChangeStatus.rejectedByAdmin:
        return 'Solicitação não aprovada';
      case AccountChangeStatus.cancelledByHolder:
        return 'Cancelada por você';
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
      case AccountChangeStatus.waitingProof:
        return PhosphorIconsRegular.fileText;
      case AccountChangeStatus.underReview:
        return PhosphorIconsRegular.magnifyingGlass;
      case AccountChangeStatus.waitingHolderConfirmation:
        return PhosphorIconsRegular.userFocus;
      case AccountChangeStatus.rejectedByAdmin:
        return PhosphorIconsRegular.xCircle;
      case AccountChangeStatus.cancelledByHolder:
        return PhosphorIconsRegular.minusCircle;
      case AccountChangeStatus.unknown:
        return PhosphorIconsRegular.clock;
    }
  }

  /// Retorna se a requisição está em andamento/pendente.
  bool get isOngoing {
    switch (request.status) {
      case AccountChangeStatus.applying:
      case AccountChangeStatus.waitingProof:
      case AccountChangeStatus.underReview:
      case AccountChangeStatus.waitingHolderConfirmation:
      case AccountChangeStatus.applicationFailed:
      case AccountChangeStatus.unknown:
        return true;
      case AccountChangeStatus.completed:
      case AccountChangeStatus.rejectedByAdmin:
      case AccountChangeStatus.cancelledByHolder:
        return false;
    }
  }

  /// Resolve o token de cor visual correspondente ao status da alteração.
  ///
  /// Cores e intenções visuais pré-existentes na DS V2:
  /// - completed: sucesso (verde)
  /// - rejectedByAdmin/applicationFailed: perigo (vermelho)
  /// - waitingProof/waitingHolderConfirmation: alerta (laranja)
  /// - applying: solicitacao (azul claro)
  /// - underReview: comunicacao (ciano)
  /// - cancelledByHolder: manutencao (cinza/neutro)
  /// - unknown: fallback (cinza)
  DsCorVisual get visualToken {
    switch (request.status) {
      case AccountChangeStatus.completed:
        return DsCores.sucesso;
      case AccountChangeStatus.rejectedByAdmin:
      case AccountChangeStatus.applicationFailed:
        return DsCores.perigo;
      case AccountChangeStatus.waitingProof:
      case AccountChangeStatus.waitingHolderConfirmation:
        return DsCores.alerta;
      case AccountChangeStatus.applying:
        return DsCores.solicitacao;
      case AccountChangeStatus.underReview:
        return DsCores.comunicacao;
      case AccountChangeStatus.cancelledByHolder:
        return DsCores.manutencao;
      case AccountChangeStatus.unknown:
        return DsCores.fallback;
    }
  }
}
