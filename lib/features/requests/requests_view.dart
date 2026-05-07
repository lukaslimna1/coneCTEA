import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/card_request.dart';
import 'package:intl/intl.dart';

class RequestsView extends StatefulWidget {
  const RequestsView({super.key});

  @override
  State<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends State<RequestsView> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  List<CardRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      final requests = await _databaseService.getCardRequests(userId);
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mural de Solicitações',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acompanhe o andamento dos seus pedidos e serviços.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ))
            else if (_requests.isEmpty)
              _buildEmptyState()
            else
              ..._buildRequestList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.assignment_late_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Nenhuma solicitação encontrada',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas solicitações de carteirinha e suporte\naparecerão aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRequestList() {
    final processing = _requests.where((r) => r.status != 'completed' && r.status != 'rejected' && r.status != 'resolved').toList();
    final completed = _requests.where((r) => r.status == 'completed' || r.status == 'rejected' || r.status == 'resolved').toList();

    List<Widget> items = [];

    if (processing.isNotEmpty) {
      items.add(_buildSectionTitle('⏳ Em processamento'));
      items.add(const SizedBox(height: 16));
      items.addAll(processing.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildRequestCard(r),
      )));
    }

    if (completed.isNotEmpty) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 32));
      items.add(_buildSectionTitle('✅ Concluídos'));
      items.add(const SizedBox(height: 16));
      items.addAll(completed.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildRequestCard(r),
      )));
    }

    return items;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRequestCard(CardRequest request) {
    final ui = _getStatusUI(request.status);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(request.createdAt);
    final prefix = request.status == 'completed' || request.status == 'resolved' ? 'Finalizado em' : 'Solicitado em';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ui.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_getTypeIcon(request.type), color: ui.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeLabel(request.type),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Protocolo: ${request.protocol}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ui.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  ui.label,
                  style: GoogleFonts.inter(
                    color: ui.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(ui.progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ui.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ui.progress,
              backgroundColor: AppColors.backgroundLight,
              valueColor: AlwaysStoppedAnimation<Color>(ui.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '$prefix $dateFormatted',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _StatusUI _getStatusUI(String status) {
    switch (status) {
      case 'under_review':
        return _StatusUI('Em análise', AppColors.alertOrange, 0.4);
      case 'awaiting_docs':
        return _StatusUI('Docs pendentes', AppColors.errorRed, 0.2);
      case 'approved':
        return _StatusUI('Aprovado', AppColors.statusGreen, 0.7);
      case 'printed':
        return _StatusUI('Impressa', AppColors.statusGreen, 0.9);
      case 'completed':
      case 'resolved':
        return _StatusUI('Concluído', AppColors.statusGreen, 1.0);
      case 'rejected':
        return _StatusUI('Recusado', AppColors.errorRed, 1.0);
      default:
        return _StatusUI('Em processamento', AppColors.primary, 0.5);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'new_card':
        return Icons.badge_rounded;
      case 'update_data':
        return Icons.edit_note_rounded;
      case 'support':
        return Icons.support_agent_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'new_card':
        return 'Emissão de Carteirinha CIPTEA';
      case 'update_data':
        return 'Atualização Cadastral';
      case 'support':
        return 'Solicitação de Suporte';
      default:
        return 'Solicitação Geral';
    }
  }
}

class _StatusUI {
  final String label;
  final Color color;
  final double progress;

  _StatusUI(this.label, this.color, this.progress);
}

