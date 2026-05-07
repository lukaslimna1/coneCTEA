import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../services/database_service.dart';
import '../../models/card_request.dart';
import '../../models/app_user.dart';
import '../../models/digital_card.dart';
import '../../models/member.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import '../../services/google_drive_service.dart';
import '../../models/notification_item.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  bool _isLoadingRequests = true;
  bool _isLoadingUsers = true;

  List<CardRequest> _allRequests = [];
  List<AppUser> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllRequests();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      _allRequests = await _databaseService.getAllCardRequests();
    } catch (e) {
      _allRequests = [];
    }
    if (mounted) setState(() => _isLoadingRequests = false);
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      _allUsers = await _databaseService.getAllProfiles();
    } catch (e) {
      _allUsers = [];
    }
    if (mounted) setState(() => _isLoadingUsers = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Painel de Gestão',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gerenciamento de solicitações e usuários',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Solicitações'),
              Tab(text: 'Usuários'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildRequestsTab(), _buildUsersTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_allRequests.isEmpty) {
      return _buildEmptyState('Nenhuma solicitação no momento.');
    }

    return RefreshIndicator(
      onRefresh: _loadAllRequests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _allRequests.length,
        itemBuilder: (context, index) {
          final request = _allRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_allUsers.isEmpty) {
      return _buildEmptyState('Nenhum usuário cadastrado.');
    }

    return RefreshIndicator(
      onRefresh: _loadAllUsers,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final user = _allUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final bool isAdmin = user.role == UserRole.admin;
    final initials = user.name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('')
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAdmin
                ? AppColors.primary
                : AppColors.purpleLight,
            radius: 24,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                color: isAdmin ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlue,
                    fontSize: 15,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isAdmin ? AppColors.primary : AppColors.textSecondary)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isAdmin ? 'ADMINISTRADOR' : 'USUÁRIO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isAdmin
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<UserRole>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (newRole) => _changeUserRole(user, newRole),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: UserRole.user,
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: !isAdmin ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Mudar para Usuário'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: UserRole.admin,
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 20,
                      color: isAdmin ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Mudar para Admin'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeUserRole(AppUser user, UserRole newRole) async {
    if (user.role == newRole) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Confirmar Alteração'),
          ],
        ),
        content: Text(
          'Deseja realmente mudar o cargo de ${user.name} para ${newRole == UserRole.admin ? "Administrador" : "Usuário"}?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Confirmar',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await _databaseService.updateUserProfileRole(user.id, newRole);
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cargo atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAllUsers();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar cargo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRequestCard(CardRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solicitação #${request.id.substring(0, 8)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlue,
                ),
              ),
              _buildStatusBadge(request.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Protocolo: ${request.protocol}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data: ${request.createdAt.day.toString().padLeft(2, '0')}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.year}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showRequestDetails(request),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Analisar / Ver Detalhes',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRequestDetails(CardRequest request) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestDetailsSheet(
        request: request,
        databaseService: _databaseService,
        onStatusChanged: _loadAllRequests,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'waiting_approval':
      case 'under_review':
      case 'em análise':
        bgColor = Colors.amber.withValues(alpha: 0.2);
        textColor = Colors.amber.shade900;
        break;
      case 'active':
      case 'approved':
      case 'aprovada':
      case 'ativa':
        bgColor = AppColors.statusGreen.withValues(alpha: 0.2);
        textColor = AppColors.statusGreen;
        break;
      case 'waiting_docs':
        bgColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue.shade900;
        break;
      case 'reviewing_data':
        bgColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange.shade900;
        break;
      case 'rejected':
      case 'rejeitada':
        bgColor = AppColors.errorRed.withValues(alpha: 0.2);
        textColor = AppColors.errorRed;
        break;
      case 'suspended':
      case 'suspensa':
        bgColor = Colors.black.withValues(alpha: 0.1);
        textColor = Colors.black87;
        break;
      case 'expired':
      case 'expirada':
        bgColor = Colors.brown.withValues(alpha: 0.2);
        textColor = Colors.brown.shade900;
        break;
      case 'renewing':
      case 'aguardando renovação':
        bgColor = Colors.purple.withValues(alpha: 0.2);
        textColor = Colors.purple.shade900;
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey.shade800;
    }

    String label = status.toUpperCase();
    switch (status.toLowerCase()) {
      case 'waiting_approval':
      case 'under_review':
        label = 'EM ANÁLISE';
        break;
      case 'approved':
      case 'active':
        label = 'ATIVA / APROVADA';
        break;
      case 'rejected':
        label = 'REJEITADA';
        break;
      case 'waiting_docs':
        label = 'AGUARDANDO DOCS';
        break;
      case 'reviewing_data':
        label = 'REVISAR DADOS';
        break;
      case 'suspended':
        label = 'SUSPENSA';
        break;
      case 'expired':
      case 'expirada':
        label = 'EXPIRADA';
        break;
      case 'renewing':
      case 'aguardando renovação':
        label = 'AGUARDANDO RENOVAÇÃO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _RequestDetailsSheet extends StatefulWidget {
  final CardRequest request;
  final DatabaseService databaseService;
  final VoidCallback onStatusChanged;

  const _RequestDetailsSheet({
    required this.request,
    required this.databaseService,
    required this.onStatusChanged,
  });

  @override
  State<_RequestDetailsSheet> createState() => _RequestDetailsSheetState();
}

class _RequestDetailsSheetState extends State<_RequestDetailsSheet> {
  bool _isLoading = true;
  AppUser? _requester;
  Member? _member;
  final _notesController = TextEditingController();
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.request.adminNotes;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final user = await widget.databaseService.getUserProfile(
      widget.request.userId,
    );
    final member = await widget.databaseService.getMemberById(
      widget.request.memberId,
    );

    if (mounted) {
      setState(() {
        _requester = user;
        _member = member;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus, String notes) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      debugPrint('Updating request ${widget.request.id} to $newStatus');
      await widget.databaseService.updateCardRequestStatus(
        widget.request.id,
        newStatus,
        adminNotes: notes.trim(),
      );

      if (newStatus == 'approved' && _member != null) {
        final now = DateTime.now();
        final String cardNumber =
            'CTEA-${now.year}-${const Uuid().v4().substring(0, 8).toUpperCase()}';

        final digitalCard = DigitalCard(
          id: '',
          memberId: _member!.id,
          userId: widget.request.userId,
          cardNumber: cardNumber,
          status: 'active',
          validUntil: DateTime(now.year + 5, now.month, now.day),
          issuedAt: now,
          frontData: {
            'name': _member!.name,
            'cpf': _member!.cpf,
            'bloodType': _member!.bloodType,
            'cid': _member!.cid,
          },
          backData: {'emergencyContact': _member!.emergencyContact},
          qrValidationUrl: 'https://conectea.app/validate/$cardNumber',
          createdAt: now,
          updatedAt: now,
        );

        await widget.databaseService.createDigitalCard(digitalCard);
      }

      // Sincronizar o status do Membro com o status da Solicitação
      if (_member != null) {
        final updatedMember = _member!.copyWith(
          status: newStatus == 'approved' ? 'active' : newStatus,
          updatedAt: DateTime.now(),
        );
        await widget.databaseService.updateMember(updatedMember);
      }

      // Criar Notificação para o Usuário
      final String notificationTitle = _getNotificationTitle(newStatus);
      final String notificationMessage = _getNotificationMessage(newStatus, notes);
      
      final notification = NotificationItem(
        id: '',
        userId: widget.request.userId,
        memberId: widget.request.memberId,
        title: notificationTitle,
        message: notificationMessage,
        type: 'card_status_update',
        isRead: false,
        actionLabel: 'Ver Carteirinha',
        actionRoute: '/home',
        createdAt: DateTime.now(),
      );

      await widget.databaseService.createNotification(notification);

      if (mounted) {
        Navigator.of(context).pop(); // Fecha o carregamento
        Navigator.of(context).pop(); // Fecha a aba de detalhes
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Análise de Solicitação',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Dados da Solicitação'),
                        _buildDetailRow('Protocolo', widget.request.protocol),
                        _buildDetailRow(
                          'Tipo', 
                          (widget.request.type == 'new_card' || widget.request.type == 'Primeira via' || widget.request.type == 'Emissão Digital') 
                              ? 'Emissão Digital' 
                              : widget.request.type
                        ),
                        _buildDetailRow('Status Atual', _getStatusDisplay(widget.request.status)),
                        _buildDetailRow(
                          'Data',
                          '${widget.request.createdAt.day}/${widget.request.createdAt.month}/${widget.request.createdAt.year}',
                        ),

                        const SizedBox(height: 24),
                        _buildSectionTitle('Documentação Enviada'),
                        const SizedBox(height: 8),
                        _buildDocumentLink(
                          'Documento com Foto',
                          widget.request.documentUrl,
                          Icons.badge_outlined,
                          'document_url',
                        ),
                        const SizedBox(height: 12),
                        _buildDocumentLink(
                          'Laudo Médico',
                          widget.request.medicalReportUrl,
                          Icons.medical_information_outlined,
                          'medical_report_url',
                        ),

                        if (widget.request.driveFolderUrl.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Link Legado (Drive)',
                            widget.request.driveFolderUrl,
                          ),
                        ],

                        const SizedBox(height: 24),
                        _buildSectionTitle('Membro (Beneficiário)'),
                        if (_member != null) ...[
                          _buildDetailRow('Nome', _member!.name),
                          _buildDetailRow('CPF', _member!.cpf),
                          _buildDetailRow('Nascimento', _member!.dateOfBirth),
                          _buildDetailRow('Localização', '${_member!.city} - ${_member!.state}'),
                          _buildDetailRow('CID', _member!.cid),
                          _buildDetailRow('Tipo Sanguíneo', _member!.bloodType),
                          _buildDetailRow(
                            'Contato Emergência',
                            _member!.emergencyContact,
                          ),
                        ] else
                          const Text('Dados do membro não encontrados.'),

                        const SizedBox(height: 24),
                        _buildSectionTitle('Usuário Solicitante'),
                        if (_requester != null) ...[
                          _buildDetailRow('Nome', _requester!.name),
                          _buildDetailRow('E-mail', _requester!.email),
                          _buildDetailRow('Telefone', _requester!.phone),
                        ] else
                          const Text('Dados do usuário não encontrados.'),

                        const SizedBox(height: 24),
                        _buildSectionTitle('Anotações do Admin (Opcional)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Adicione notas sobre a análise...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        _buildStatusSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getNotificationTitle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return '🎉 Carteirinha Aprovada!';
      case 'rejected':
      case 'rejeitada':
        return '❌ Solicitação Reprovada';
      case 'suspended':
      case 'suspensa':
        return '⚠️ Carteirinha Suspensa';
      case 'waiting_docs':
        return '📄 Documentos Pendentes';
      case 'reviewing_data':
        return '✏️ Revisão de Dados Necessária';
      case 'expired':
        return '📅 Carteirinha Vencida';
      default:
        return 'Atualização na sua solicitação';
    }
  }

  String _getNotificationMessage(String status, String notes) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return 'Sua carteirinha digital foi emitida e já está disponível para uso!';
      case 'rejected':
      case 'rejeitada':
        return 'Sua solicitação foi reprovada. Motivo: $notes';
      case 'suspended':
      case 'suspensa':
        return 'Sua carteirinha foi suspensa temporariamente. Motivo: $notes';
      case 'waiting_docs':
        return 'Precisamos que você envie alguns documentos para continuar. Veja as observações.';
      case 'reviewing_data':
        return 'Alguns dados precisam ser corrigidos. Por favor, verifique sua solicitação.';
      default:
        return 'Houve uma mudança no status da sua carteirinha. Clique para ver detalhes.';
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'waiting_approval':
      case 'under_review':
        return 'Aguardando aprovação';
      case 'approved':
      case 'active':
        return 'Carteirinha Ativa';
      case 'rejected':
        return 'Reprovada';
      case 'waiting_docs':
        return 'Aguardando documentação';
      case 'reviewing_data':
        return 'Solicitando revisão de dados';
      case 'suspended':
        return 'Suspensa';
      case 'expired':
        return 'Vencida';
      case 'renewing':
        return 'Aguardando renovação';
      default:
        return status;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.darkBlue,
        ),
      ),
    );
  }

  Widget _buildDocumentLink(
    String label,
    String url,
    IconData iconData,
    String fieldKey,
  ) {
    final bool hasUrl = url.isNotEmpty && url.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: hasUrl
            ? () async {
                if (await canLaunchUrlString(url)) {
                  await launchUrlString(url);
                }
              }
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasUrl
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: hasUrl ? AppColors.primary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasUrl
                        ? 'Toque para visualizar arquivo'
                        : 'Nenhum arquivo enviado',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: hasUrl
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: hasUrl ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (hasUrl) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 22),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Deletar Arquivo?'),
                      content: const Text(
                          'Isso removerá o arquivo permanentemente do Google Drive.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Deletar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deletando arquivo...')),
                    );

                    final success = await _driveService.deleteFile(url);
                    if (success) {
                      try {
                        // Atualizar Supabase para remover a URL
                        await widget.databaseService.updateRequestFileUrl(
                          widget.request.id,
                          fieldKey,
                          '',
                        );

                        // Recarregar os detalhes e fechar o sheet para refletir a mudança
                        if (mounted) {
                          widget.onStatusChanged(); // Gatilha recarregamento na AdminView
                          Navigator.pop(context); // Fecha o sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Arquivo deletado com sucesso!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Erro ao atualizar banco: $e')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Falha ao deletar arquivo no Drive.')),
                        );
                      }
                    }
                  }
                },
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alterar Status',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBlue,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusChip('waiting_approval', '🟡 Aguardando Approval'),
            _statusChip('waiting_docs', '🔵 Docs Pendentes'),
            _statusChip('reviewing_data', '🟠 Revisar Dados'),
            _statusChip('active', '🟢 Ativar'),
            _statusChip('rejected', '🔴 Reprovar'),
            _statusChip('suspended', '⚫ Suspender'),
            _statusChip('expired', '🟤 Vencida'),
            _statusChip('renewing', '🟣 Renovação'),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String status, String label) {
    final bool isCurrent = widget.request.status == status;
    
    Color color;
    switch (status) {
      case 'waiting_approval': color = Colors.amber; break;
      case 'waiting_docs': color = Colors.blue; break;
      case 'reviewing_data': color = Colors.orange; break;
      case 'active': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      case 'suspended': color = Colors.grey[800]!; break;
      case 'expired': color = Colors.brown; break;
      case 'renewing': color = Colors.purple; break;
      default: color = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        if (!isCurrent) {
          _confirmStatusUpdate(status, label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? color : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isCurrent ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent) ...[
              const Icon(Icons.check_circle, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmStatusUpdate(String status, String label) async {
    final notesController = TextEditingController();
    
    Color color;
    switch (status) {
      case 'waiting_approval': color = Colors.amber; break;
      case 'waiting_docs': color = Colors.blue; break;
      case 'reviewing_data': color = Colors.orange; break;
      case 'active': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      case 'suspended': color = Colors.grey[800]!; break;
      case 'expired': color = Colors.brown; break;
      case 'renewing': color = Colors.purple; break;
      default: color = AppColors.primary;
    }

    List<String> options = [];
    Map<String, bool> selectedOptions = {};

    if (status == 'reviewing_data') {
      options = ['Nome Completo', 'CPF', 'Tipo Sanguíneo', 'Endereço/Cidade', 'Telefone', 'Contato de Emergência', 'Responsável'];
    } else if (status == 'waiting_docs') {
      options = ['Documento de Identidade (RG/CNH)', 'CPF', 'RG', 'CNH', 'Documento do Responsável', 'Comprovante', 'Laudo Médico (CID)'];
    }
    
    for (var opt in options) {
      selectedOptions[opt] = false;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirmar: $label',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Justificativa para o usuário:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 4,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Descreva aqui o motivo da alteração...',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                  if (options.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      status == 'reviewing_data' ? '📋 Campos para correção:' : '📄 Documentos solicitados:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: options.map((opt) => CheckboxListTile(
                          title: Text(opt, style: GoogleFonts.inter(fontSize: 13)),
                          value: selectedOptions[opt],
                          dense: true,
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          onChanged: (val) {
                            setDialogState(() => selectedOptions[opt] = val ?? false);
                            
                            String newNotes = "Pendências encontradas:\n";
                            selectedOptions.forEach((key, isSelected) {
                              if (isSelected) newNotes += "- Pendência: $key\n";
                            });
                            notesController.text = newNotes;
                          },
                        )).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (notesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Justificativa obrigatória')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await widget.databaseService.updateCardStatus(
          widget.request.id,
          status,
          notesController.text.trim(),
        );
        if (mounted) {
          widget.onStatusChanged();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status atualizado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: $e')),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
