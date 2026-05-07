import 'package:flutter/material.dart';

enum RequestStatus {
  pending, // Em análise
  waitingDocument, // Aguardando documentação
  approved, // Aprovada
  rejected, // Reprovada
  suspended, // Suspensa
  expired, // Vencida
  renewalRequested, // Aguardando renovação
  needsAdjustment, // Aguardando correção
}

class IDRequest {
  final String id;
  final String userId;
  final String applicantName;
  final String birthDate;
  final String city;
  final String institution;
  final String rgCpf;
  final String phone;
  final RequestStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final String? cardNumber;
  final DateTime? expiryDate;
  final String? photoUrl;
  final String? driveLink;

  IDRequest({
    required this.id,
    required this.userId,
    required this.applicantName,
    required this.birthDate,
    required this.city,
    required this.institution,
    required this.rgCpf,
    required this.phone,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.cardNumber,
    this.expiryDate,
    this.photoUrl,
    this.driveLink,
  });

  factory IDRequest.fromJson(Map<String, dynamic> json) {
    return IDRequest(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      applicantName: json['applicant_name'] ?? '',
      birthDate: json['birth_date'] ?? '',
      city: json['city'] ?? '',
      institution: json['institution'] ?? '',
      rgCpf: json['rg_cpf'] ?? '',
      phone: json['phone'] ?? '',
      status: _statusFromString(json['status']),
      adminNotes: json['admin_notes'],
      cardNumber: json['card_number'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      photoUrl: json['photo_url'],
      driveLink: json['drive_link'],
    );
  }

  static RequestStatus _statusFromString(String? status) {
    if (status == null) return RequestStatus.pending;
    switch (status) {
      case 'waiting_document': return RequestStatus.waitingDocument;
      case 'approved': return RequestStatus.approved;
      case 'rejected': return RequestStatus.rejected;
      case 'suspended': return RequestStatus.suspended;
      case 'expired': return RequestStatus.expired;
      case 'renewal_requested': return RequestStatus.renewalRequested;
      case 'needs_adjustment': return RequestStatus.needsAdjustment;
      default: return RequestStatus.pending;
    }
  }

  // Label para o Usuário (Texto claro e direto)
  String get userStatusLabel {
    switch (status) {
      case RequestStatus.pending: return 'Em análise';
      case RequestStatus.waitingDocument: return 'Faltam documentos';
      case RequestStatus.approved: return 'Aprovada';
      case RequestStatus.rejected: return 'Reprovada';
      case RequestStatus.suspended: return 'Suspensa';
      case RequestStatus.expired: return 'Vencida';
      case RequestStatus.renewalRequested: return 'Em renovação';
      case RequestStatus.needsAdjustment: return 'Ajuste necessário';
    }
  }

  // Descrição para o Usuário (Explicação com contexto)
  String get userStatusDescription {
    switch (status) {
      case RequestStatus.pending: 
        return 'Sua solicitação está sendo revisada por um profissional do Centro de Gestão ConeCTEA.';
      case RequestStatus.waitingDocument: 
        return 'Sua solicitação precisa de documentos complementares. Clique no botão para enviar pelo Drive.';
      case RequestStatus.approved: 
        return 'Sua identificação digital foi aprovada! Ela já está disponível no seu painel.';
      case RequestStatus.rejected: 
        return 'Sua solicitação não pôde ser aprovada. Verifique o motivo detalhado clicando abaixo.';
      case RequestStatus.suspended: 
        return 'Sua identificação está suspensa temporariamente. Clique no botão para pedir uma revisão.';
      case RequestStatus.expired: 
        return 'Sua identificação digital venceu (365 dias). Nossa equipe já foi notificada para a renovação.';
      case RequestStatus.renewalRequested: 
        return 'Seu pedido de renovação já está com nossa equipe. A validade será estendida em breve.';
      case RequestStatus.needsAdjustment:
        return 'Sua solicitação precisa de uma correção nos dados. Clique no botão para ajustar.';
    }
  }

  // Label do Botão de Ação
  String? get userActionLabel {
    switch (status) {
      case RequestStatus.pending: return 'Acompanhar';
      case RequestStatus.waitingDocument: return 'Enviar Documentos';
      case RequestStatus.approved: return 'Ver Carteirinha';
      case RequestStatus.rejected: return 'Ver Motivo';
      case RequestStatus.suspended: return 'Pedir Revisão';
      case RequestStatus.expired: return 'Solicitar Renovação';
      case RequestStatus.renewalRequested: return 'Acompanhar';
      case RequestStatus.needsAdjustment: return 'Corrigir Agora';
    }
  }

  // Ícone do Botão de Ação (Ícone representativo)
  IconData? get userActionIcon {
    switch (status) {
      case RequestStatus.pending: return Icons.visibility_outlined;
      case RequestStatus.waitingDocument: return Icons.upload_file_rounded;
      case RequestStatus.approved: return Icons.badge_outlined;
      case RequestStatus.rejected: return Icons.error_outline_rounded;
      case RequestStatus.suspended: return Icons.gavel_rounded;
      case RequestStatus.expired: return Icons.history_rounded;
      case RequestStatus.renewalRequested: return Icons.sync_rounded;
      case RequestStatus.needsAdjustment: return Icons.edit_note_rounded;
    }
  }

  // Label para o Administrador
  String get adminStatusLabel {
    switch (status) {
      case RequestStatus.pending: return 'Pendente';
      case RequestStatus.waitingDocument: return 'Aguardando documentação';
      case RequestStatus.approved: return 'Aprovada';
      case RequestStatus.rejected: return 'Reprovada';
      case RequestStatus.suspended: return 'Suspensa';
      case RequestStatus.expired: return 'Vencida';
      case RequestStatus.renewalRequested: return 'Renovação';
      case RequestStatus.needsAdjustment: return 'Aguardando correção';
    }
  }

  // Cor para o Status
  Color get statusColor {
    switch (status) {
      case RequestStatus.pending: return const Color(0xFFFFB020); // Amarelo
      case RequestStatus.waitingDocument: return const Color(0xFF1E63D8); // Azul Vivo
      case RequestStatus.approved: return const Color(0xFF10B981); // Verde
      case RequestStatus.rejected: return const Color(0xFFEF4444); // Vermelho
      case RequestStatus.suspended: return Colors.black; // Preto
      case RequestStatus.expired: return const Color(0xFFF97316); // Laranja
      case RequestStatus.renewalRequested: return const Color(0xFF8A44E8); // Roxo
      case RequestStatus.needsAdjustment: return const Color(0xFFF97316); // Laranja
    }
  }

  // Ícone para o Status (Ícone claro)
  IconData get statusIcon {
    switch (status) {
      case RequestStatus.pending: return Icons.access_time_filled_rounded;
      case RequestStatus.waitingDocument: return Icons.file_present_rounded;
      case RequestStatus.approved: return Icons.check_circle_rounded;
      case RequestStatus.rejected: return Icons.cancel_rounded;
      case RequestStatus.suspended: return Icons.block_rounded;
      case RequestStatus.expired: return Icons.event_busy_rounded;
      case RequestStatus.renewalRequested: return Icons.autorenew_rounded;
      case RequestStatus.needsAdjustment: return Icons.warning_amber_rounded;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'applicant_name': applicantName,
      'birth_date': birthDate,
      'city': city,
      'institution': institution,
      'rg_cpf': rgCpf,
      'phone': phone,
      'status': statusToString(status),
      'admin_notes': adminNotes,
      'card_number': cardNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'photo_url': photoUrl,
      'drive_link': driveLink,
    };
  }

  static String statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return 'pending';
      case RequestStatus.waitingDocument: return 'waiting_document';
      case RequestStatus.approved: return 'approved';
      case RequestStatus.rejected: return 'rejected';
      case RequestStatus.suspended: return 'suspended';
      case RequestStatus.expired: return 'expired';
      case RequestStatus.renewalRequested: return 'renewal_requested';
      case RequestStatus.needsAdjustment: return 'needs_adjustment';
    }
  }
}

