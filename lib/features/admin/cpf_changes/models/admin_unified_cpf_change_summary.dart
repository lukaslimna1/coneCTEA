import 'package:conectea/models/account_change_request.dart';
import 'package:conectea/features/admin/cpf_changes/models/admin_cpf_change_summary.dart';
import 'package:conectea/features/admin/cpf_dependente/models/admin_dependent_cpf_change_summary.dart';

enum CpfChangeRequestType { account, dependent }

class AdminUnifiedCpfChangeSummary {
  final String id;
  final String protocolNumber;
  final AccountChangeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? statusChangedAt;
  final DateTime? closedAt;
  final bool hasDocument;
  
  // Tipo de solicitação
  final CpfChangeRequestType type;

  // Informações de Titular/Conta
  final String userFirstName;
  final String userEmailMasked;

  // Informações de Dependente (se for do tipo dependent)
  final String? dependentFirstName;
  final String? dependentFullName;

  // Valores Mascarados
  final String oldValueMasked;
  final String newValueMasked;
  
  // Metadados adicionais
  final String? adminDeadlineDueDate;
  final String? holderDeadlineDueDate;
  final bool isOverdue;

  // Referência para o summary original da conta (para não quebrar abertura de detalhes)
  final AdminCpfChangeSummary? rawAccountSummary;

  // Referência para o summary original de dependente
  final AdminDependentCpfChangeSummary? rawDependentSummary;

  const AdminUnifiedCpfChangeSummary({
    required this.id,
    required this.protocolNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.statusChangedAt,
    this.closedAt,
    required this.hasDocument,
    required this.type,
    required this.userFirstName,
    required this.userEmailMasked,
    this.dependentFirstName,
    this.dependentFullName,
    required this.oldValueMasked,
    required this.newValueMasked,
    this.adminDeadlineDueDate,
    this.holderDeadlineDueDate,
    this.isOverdue = false,
    this.rawAccountSummary,
    this.rawDependentSummary,
  });

  // Converte a partir do model de CPF da conta (titular)
  factory AdminUnifiedCpfChangeSummary.fromAccount(AdminCpfChangeSummary summary) {
    return AdminUnifiedCpfChangeSummary(
      id: summary.id,
      protocolNumber: summary.protocolNumber,
      status: summary.status,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      statusChangedAt: summary.statusChangedAt,
      closedAt: summary.closedAt,
      hasDocument: summary.hasDocument,
      type: CpfChangeRequestType.account,
      userFirstName: summary.userFirstName,
      userEmailMasked: summary.userEmailMasked,
      oldValueMasked: summary.oldValueMasked ?? '***.***.***-**',
      newValueMasked: summary.newValueMasked ?? '***.***.***-**',
      adminDeadlineDueDate: summary.adminDeadlineDueDate,
      holderDeadlineDueDate: summary.holderDeadlineDueDate,
      isOverdue: summary.isOverdue,
      rawAccountSummary: summary,
      rawDependentSummary: null,
    );
  }

  // Converte a partir do model de CPF de dependente
  factory AdminUnifiedCpfChangeSummary.fromDependent(AdminDependentCpfChangeSummary summary) {
    return AdminUnifiedCpfChangeSummary(
      id: summary.id,
      protocolNumber: summary.protocolNumber,
      status: summary.status,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      statusChangedAt: null,
      closedAt: summary.cancelledAt ?? summary.completedAt,
      hasDocument: summary.hasDocument,
      type: CpfChangeRequestType.dependent,
      userFirstName: summary.userFirstName,
      userEmailMasked: summary.userEmailMasked,
      dependentFirstName: summary.dependentFirstName,
      dependentFullName: summary.dependentFullName,
      oldValueMasked: summary.currentCpfMasked,
      newValueMasked: summary.requestedCpfMasked,
      adminDeadlineDueDate: null,
      holderDeadlineDueDate: null,
      isOverdue: false,
      rawAccountSummary: null,
      rawDependentSummary: summary,
    );
  }
}
