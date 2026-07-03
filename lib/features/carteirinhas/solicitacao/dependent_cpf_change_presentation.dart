import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/tokens/ds_cores.dart';
import 'package:conectea/core/utils/conectea_date_time_helper.dart';
import 'package:conectea/models/dependent_cpf_change_request.dart';

class DependentCpfChangePresentation {
  final DependentCpfChangeRequest request;

  const DependentCpfChangePresentation(this.request);

  /// Título padrão para a alteração.
  String get typeLabel => 'CPF do dependente';

  /// Ícone representativo para o tipo da alteração.
  IconData get typeIcon => PhosphorIconsRegular.identificationCard;

  /// Label humanizado para o status da alteração.
  String get statusLabel {
    switch (request.status.toLowerCase()) {
      case 'under_review':
        return 'EM ANÁLISE';
      case 'waiting_document_replacement':
        return 'NOVO DOCUMENTO NECESSÁRIO';
      case 'waiting_cpf_correction':
        return 'CORREÇÃO DE CPF SOLICITADA';
      case 'applying':
        return 'ALTERAÇÃO EM ANDAMENTO';
      case 'completed':
        return 'ALTERAÇÃO CONCLUÍDA';
      case 'rejected_by_admin':
        return 'NÃO APROVADA';
      case 'cancelled_by_holder':
        return 'ENCERRADA POR VOCÊ';
      case 'expired':
        return 'PRAZO ENCERRADO';
      case 'application_failed':
        return 'ALTERAÇÃO NÃO CONCLUÍDA';
      default:
        return 'STATUS EM ATUALIZAÇÃO';
    }
  }

  /// Título explicativo para o status da alteração.
  String get statusTitle {
    switch (request.status.toLowerCase()) {
      case 'under_review':
        return 'Solicitação em análise';
      case 'waiting_document_replacement':
        return 'Envie outro documento';
      case 'waiting_cpf_correction':
        return 'Revise o CPF e o documento';
      case 'applying':
        return 'Atualizando CPF do dependente';
      case 'completed':
        return 'CPF do dependente atualizado';
      case 'rejected_by_admin':
        return 'Solicitação não aprovada';
      case 'cancelled_by_holder':
        return 'Solicitação encerrada';
      case 'expired':
        return 'Solicitação expirada';
      case 'application_failed':
        return 'Não foi possível atualizar o CPF';
      default:
        return 'Status em atualização';
    }
  }

  /// Descrição curta e amigável para cada status.
  String get statusDescription {
    switch (request.status.toLowerCase()) {
      case 'under_review':
        return 'A equipe está analisando os dados e o documento enviados para a alteração do CPF do dependente.';
      case 'waiting_document_replacement':
        return 'A equipe solicitou um novo documento para continuar a análise da alteração do CPF do dependente.';
      case 'waiting_cpf_correction':
        return 'A equipe identificou que o CPF informado ou o documento de comprovação precisa ser corrigido.';
      case 'applying':
        return 'A alteração confirmada está sendo concluída no sistema.';
      case 'completed':
        return 'A alteração de CPF do dependente foi concluída com sucesso.';
      case 'rejected_by_admin':
        return 'A equipe não pôde aprovar a alteração com os dados enviados.';
      case 'cancelled_by_holder':
        return 'A alteração não foi realizada e o CPF anterior do dependente continua ativo.';
      case 'expired':
        return 'O prazo para concluir a etapa terminou e a alteração não foi realizada.';
      case 'application_failed':
        return 'Os dados atuais do dependente continuam ativos e esta solicitação foi preservada.';
      default:
        return 'O status está sendo atualizado.';
    }
  }

  /// Ícone representativo para o status.
  IconData get statusIcon {
    switch (request.status.toLowerCase()) {
      case 'applying':
        return PhosphorIconsRegular.arrowsClockwise;
      case 'completed':
        return PhosphorIconsRegular.checkCircle;
      case 'application_failed':
      case 'waiting_cpf_correction':
        return PhosphorIconsRegular.warningOctagon;
      case 'waiting_document_replacement':
        return PhosphorIconsRegular.fileArrowUp;
      case 'under_review':
        return PhosphorIconsRegular.magnifyingGlass;
      case 'rejected_by_admin':
        return PhosphorIconsRegular.xCircle;
      case 'cancelled_by_holder':
        return PhosphorIconsRegular.minusCircle;
      case 'expired':
        return PhosphorIconsRegular.clockCountdown;
      default:
        return PhosphorIconsRegular.clock;
    }
  }

  /// Resolve o token de cor visual correspondente ao status.
  DsCorVisual get visualToken {
    switch (request.status.toLowerCase()) {
      case 'completed':
        return DsCores.sucesso;
      case 'rejected_by_admin':
      case 'application_failed':
        return DsCores.perigo;
      case 'waiting_document_replacement':
      case 'waiting_cpf_correction':
        return DsCores.correcao;
      case 'applying':
        return DsCores.solicitacao;
      case 'under_review':
        return DsCores.comunicacao;
      case 'cancelled_by_holder':
      case 'expired':
        return DsCores.manutencao;
      default:
        return DsCores.fallback;
    }
  }

  /// Retorna se a requisição está em andamento/pendente.
  bool get isOngoing {
    final s = request.status.toLowerCase();
    return s == 'under_review' ||
        s == 'waiting_document_replacement' ||
        s == 'waiting_cpf_correction' ||
        s == 'applying' ||
        s == 'application_failed';
  }

  /// Retorna se a solicitação deve exibir prazo de ação.
  bool get canShowDeadline {
    final s = request.status.toLowerCase();
    return request.expiresAt != null &&
        (s == 'waiting_document_replacement' ||
            s == 'waiting_cpf_correction');
  }

  /// Retorna o texto formatado do prazo de ação.
  String? get deadlineText {
    if (!canShowDeadline || request.expiresAt == null) return null;
    final dateStr = ConecteaDateTimeHelper.formatProjectDateShort(request.expiresAt!);
    return 'Prazo para sua ação: até $dateStr.';
  }

  /// Retorna se a data de encerramento pode ser exibida.
  bool get canShowClosedAt {
    final s = request.status.toLowerCase();
    return (request.completedAt != null || request.cancelledAt != null) &&
        (s == 'completed' ||
            s == 'rejected_by_admin' ||
            s == 'cancelled_by_holder' ||
            s == 'expired');
  }

  /// Rótulo do encerramento.
  String? get closedAtLabel {
    if (!canShowClosedAt) return null;
    final s = request.status.toLowerCase();
    switch (s) {
      case 'completed':
        return 'Concluída em';
      case 'cancelled_by_holder':
        return 'Cancelado em';
      case 'rejected_by_admin':
      case 'expired':
        return 'Encerrada em';
      default:
        return null;
    }
  }

  /// Retorna o texto de encerramento formatado.
  String? get closedAtText {
    if (!canShowClosedAt) return null;
    final label = closedAtLabel;
    if (label == null) return null;
    final closedDate = request.cancelledAt ?? request.completedAt ?? request.updatedAt;
    final formattedDate = ConecteaDateTimeHelper.formatProjectDateShort(closedDate);

    if (request.status.toLowerCase() == 'cancelled_by_holder') {
      final time = ConecteaDateTimeHelper.formatProjectTime(closedDate);
      return '$label $formattedDate às $time';
    }
    return '$label $formattedDate';
  }
}
