import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
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
      case AccountChangeStatus.waitingCpfCorrection:
        return 'CORREÇÃO DE CPF SOLICITADA';
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
      case AccountChangeStatus.waitingCpfCorrection:
        return 'Revise o CPF e o documento';
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
      case AccountChangeStatus.waitingCpfCorrection:
        return PhosphorIconsRegular.warningOctagon;
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
      case AccountChangeStatus.waitingCpfCorrection:
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
      case AccountChangeStatus.waitingCpfCorrection:
        return DsCores.correcao;
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
      case AccountChangeStatus.waitingCpfCorrection:
        return 'A equipe identificou que o CPF informado ou o documento de comprovação precisa ser corrigido.';
      case AccountChangeStatus.unknown:
        return 'O status está sendo atualizado.';
    }
  }

  /// Formata um objeto AccountChangeCivilDate no formato DD/MM/AAAA.
  static String formatCivilDate(AccountChangeCivilDate date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  /// Retorna true apenas quando holderDeadlineDueDate não for nulo
  /// e o status for waitingDocumentReplacement ou waitingHolderConfirmation.
  bool get canShowHolderDeadline {
    return request.holderDeadlineDueDate != null &&
        (request.status == AccountChangeStatus.waitingDocumentReplacement ||
            request.status == AccountChangeStatus.waitingHolderConfirmation ||
            request.status == AccountChangeStatus.waitingCpfCorrection);
  }

  /// Retorna o texto formatado do prazo do titular, ou nulo se não puder ser exibido.
  String? get holderDeadlineText {
    if (!canShowHolderDeadline) return null;
    final dateStr = formatCivilDate(request.holderDeadlineDueDate!);
    return 'Prazo para sua ação: até $dateStr.';
  }

  /// Retorna true apenas quando o status for cancelledByHolder ou expired
  /// e o resolutionReason não for unknown.
  bool get canShowResolutionReason {
    return (request.status == AccountChangeStatus.cancelledByHolder ||
            request.status == AccountChangeStatus.expired) &&
        request.resolutionReason != AccountChangeResolutionReason.unknown;
  }

  /// Retorna o texto humanizado para o motivo de resolução, ou nulo se não puder ser exibido.
  String? get resolutionReasonText {
    if (!canShowResolutionReason) return null;
    switch (request.resolutionReason) {
      case AccountChangeResolutionReason.cancelledDuringReview:
        return 'Você encerrou a solicitação enquanto ela estava em análise.';
      case AccountChangeResolutionReason.cancelledWhileWaitingDocument:
        return 'Você encerrou a solicitação enquanto aguardávamos o novo documento.';
      case AccountChangeResolutionReason.declinedFinalConfirmation:
        return 'Você decidiu não concluir a alteração.';
      case AccountChangeResolutionReason.documentReplacementDeadline:
        return 'O prazo para enviar um novo documento terminou.';
      case AccountChangeResolutionReason.holderConfirmationDeadline:
        return 'O prazo para confirmar a alteração terminou.';
      case AccountChangeResolutionReason.unknown:
        return null;
    }
  }

  /// Retorna true apenas quando o status for waitingDocumentReplacement ou rejectedByAdmin
  /// e existir pelo menos publicAdminReasonCode != unknown ou publicAdminFeedback não nulo.
  bool get canShowPublicAdminGuidance {
    final hasInfo =
        request.publicAdminReasonCode !=
            AccountChangePublicAdminReasonCode.unknown ||
        request.publicAdminFeedback != null;
    return (request.status == AccountChangeStatus.waitingDocumentReplacement ||
            request.status == AccountChangeStatus.rejectedByAdmin ||
            request.status == AccountChangeStatus.waitingCpfCorrection) &&
        hasInfo;
  }

  /// Retorna a orientação humanizada para o código administrativo público, ou nula se desconhecido/não exibível.
  String? get publicAdminReasonText {
    if (!canShowPublicAdminGuidance) return null;
    switch (request.publicAdminReasonCode) {
      case AccountChangePublicAdminReasonCode.documentNotAccepted:
        return 'O documento enviado não pôde ser aceito.';
      case AccountChangePublicAdminReasonCode.unreadableDocument:
        return 'Não foi possível ler o documento enviado.';
      case AccountChangePublicAdminReasonCode.cpfNotVisible:
        return 'O CPF não está visível no documento.';
      case AccountChangePublicAdminReasonCode.nameMismatch:
        return 'O nome no documento não confere com os dados cadastrados.';
      case AccountChangePublicAdminReasonCode.birthDateMismatch:
        return 'A data de nascimento no documento não confere com os dados cadastrados.';
      case AccountChangePublicAdminReasonCode.cpfMismatch:
        return 'O CPF no documento não confere com a alteração solicitada.';
      case AccountChangePublicAdminReasonCode.other:
        return 'Precisamos de um ajuste no documento para continuar.';
      case AccountChangePublicAdminReasonCode.unknown:
        return null;
    }
  }

  /// Retorna o feedback administrativo textual seguro destinado ao titular, ou nulo se não exibível.
  String? get publicAdminFeedbackText {
    if (!canShowPublicAdminGuidance) return null;
    return request.publicAdminFeedback;
  }

  /// Retorna true apenas se closedAt não for nulo e o status for terminal
  /// (completed, rejectedByAdmin, cancelledByHolder, expired).
  bool get canShowClosedAt {
    return request.closedAt != null &&
        (request.status == AccountChangeStatus.completed ||
            request.status == AccountChangeStatus.rejectedByAdmin ||
            request.status == AccountChangeStatus.cancelledByHolder ||
            request.status == AccountChangeStatus.expired);
  }

  /// Retorna o rótulo contextual do encerramento com base no status, ou null se não for um status terminal.
  String? get closedAtLabel {
    if (!canShowClosedAt) return null;
    switch (request.status) {
      case AccountChangeStatus.completed:
        return 'Concluída em';
      case AccountChangeStatus.rejectedByAdmin:
      case AccountChangeStatus.cancelledByHolder:
      case AccountChangeStatus.expired:
        return 'Encerrada em';
      default:
        return null;
    }
  }

  /// Retorna a data de encerramento formatada de forma contextual, ou null se não puder ser exibida.
  String? get closedAtText {
    if (!canShowClosedAt || request.closedAt == null) return null;
    final label = closedAtLabel;
    if (label == null) return null;
    final formattedDate = ConecteaDateTimeHelper.formatProjectDateShort(
      request.closedAt!,
    );
    return '$label $formattedDate';
  }
}
