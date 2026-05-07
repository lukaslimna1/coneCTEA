import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/id_request.dart';
import '../../models/profile.dart';
import '../../core/app_theme.dart';
import 'request_id_screen.dart';
import 'my_id_screen.dart';
import 'terms_screen.dart';
import '../../widgets/support_button.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  Stream<List<IDRequest>>? _requestsStream;
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthService>();
    final userId = auth.currentUser?.uid;
    
    if (userId != _lastUserId) {
      _lastUserId = userId;
      if (userId != null) {
        _requestsStream = _db.streamUserRequests(userId);
        // Verificar vencimentos ao entrar, de forma segura
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          try {
            await _db.checkAndProcessExpirations(userId);
          } catch (e) {
            debugPrint('Erro ao checar vencimentos: $e');
          }
        });
      } else {
        _requestsStream = Stream.value([]);
      }
    }
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    if (names.isNotEmpty && names[0].isNotEmpty) {
      initials += names[0][0];
    }
    if (names.length > 1 && names[names.length - 1].isNotEmpty) {
      initials += names[names.length - 1][0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.currentProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<IDRequest>>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.navy,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.navy, AppColors.purple],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  'Olá, ${profile?.fullName != null ? profile!.fullName.split(' ').first : "Usuário"}!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'O que vamos fazer hoje?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await auth.signOut();
                      if (!mounted) return;
                      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('SAIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row / Quick Info
                      if (requests.isNotEmpty)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Solicitações', requests.length.toString(), Icons.history),
                                _buildStatItem(
                                  'Aprovadas', 
                                  requests.where((IDRequest r) => r.status == RequestStatus.approved).length.toString(), 
                                  Icons.check_circle_outline,
                                  color: const Color(0xFF10B981),
                                ),
                              ],
                            ),
                          ),
                        ),

                      _buildSectionTitle('Serviços Principais'),
                      const SizedBox(height: 16),
                      
                      // Action Cards with Staggered Entrance feel
                      if (profile?.role == UserRole.admin) ...[
                        _buildActionCard(
                          context,
                          title: 'Painel de Gestão ConeCTEA',
                          subtitle: 'Controle de Identificações',
                          icon: Icons.admin_panel_settings_rounded,
                          color: AppColors.navy,
                          index: 0,
                          onTap: () {
                            if (!mounted) return;
                            Navigator.pushNamed(context, '/admin_dashboard');
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildActionCard(
                        context,
                        title: 'Minha Carteirinha',
                        subtitle: 'Visualize seu documento digital',
                        icon: Icons.badge_outlined,
                        color: AppColors.primary,
                        index: profile?.role == UserRole.admin ? 1 : 0,
                        onTap: () {
                          final approved = requests.where((IDRequest r) => r.status == RequestStatus.approved).toList();
                          if (approved.isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Você ainda não possui uma carteirinha aprovada.'),
                                  ],
                                ),
                              ),
                            );
                          } else if (approved.length == 1) {
                            if (!mounted) return;
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MyIDScreen(requests: approved, initialIndex: 0)));
                          } else {
                            if (!mounted) return;
                            _showCardSelector(context, approved);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _buildActionCard(
                        context,
                        title: 'Nova Solicitação',
                        subtitle: 'Solicite sua identificação',
                        icon: Icons.add_card_outlined,
                        color: AppColors.secondary,
                        index: profile?.role == UserRole.admin ? 2 : 1,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestIDScreen())),
                      ),
                      
                      const SizedBox(height: 16),
                      _buildActionCard(
                        context,
                        title: 'Termos e Privacidade',
                        subtitle: 'Saiba como cuidamos dos seus dados',
                        icon: Icons.shield_outlined,
                        color: AppColors.textSecondary,
                        index: profile?.role == UserRole.admin ? 3 : 2,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                      ),
                      
                      const SizedBox(height: 40),
                      _buildSectionTitle('Minhas Solicitações', icon: Icons.history_edu_rounded),
                      const SizedBox(height: 16),
                      
                      if (isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ))
                      else if (requests.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.note_add_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nenhuma solicitação encontrada.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return _buildRequestItem(req);
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: const SupportButton(),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color color = AppColors.primary}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int index,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 17,
                          color: AppColors.navy,
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle, 
                        style: const TextStyle(
                          color: AppColors.textSecondary, 
                          fontSize: 13,
                        )
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.2), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(IDRequest req) {
    final statusColor = req.statusColor;
    final statusIcon = req.statusIcon;
    final actionLabel = req.userActionLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.applicantName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Solicitada em ${_formatDate(req.createdAt)}', 
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      req.userStatusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            req.userStatusDescription,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _handleStatusAction(req),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (req.userActionIcon != null) ...[
                      Icon(req.userActionIcon, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      actionLabel.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1),
                    ),
                  ],
                ),
              ),
            ),
            if (req.status == RequestStatus.waitingDocument) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nenhum documento será enviado ou salvo dentro do app.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _handleStatusAction(IDRequest req) async {
    if (!mounted) return;
    switch (req.status) {
      case RequestStatus.approved:
        Navigator.push(context, MaterialPageRoute(builder: (_) => MyIDScreen(requests: [req], initialIndex: 0)));
        break;
      
      case RequestStatus.waitingDocument:
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Enviar Documentos'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A administração solicitou o envio dos seguintes documentos pelo Drive:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    req.adminNotes ?? 'Aguardando detalhamento da equipe.',
                    style: const TextStyle(fontSize: 14, color: AppColors.navy),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('VOLTAR', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  
                  if (req.driveLink != null && req.driveLink!.isNotEmpty) {
                    final uri = Uri.parse(req.driveLink!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Não foi possível abrir o link do Drive.')),
                        );
                      }
                    }
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Link do Drive não disponível. Fale com o suporte.')),
                    );
                  }
                  if (mounted) navigator.pop();
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('ABRIR DRIVE'),
              ),
            ],
          ),
        );
        break;

      case RequestStatus.needsAdjustment:
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(req.userActionIcon, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text('Correção Necessária'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verifique as observações do Centro de Gestão:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                  ),
                  child: Text(req.adminNotes ?? 'Aguardando detalhamento.'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('VOLTAR', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_document, size: 18),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RequestIDScreen(existingRequest: req)));
                },
                label: const Text('CORRIGIR DADOS'),
              ),
            ],
          ),
        );
        break;

      case RequestStatus.rejected:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: AppColors.error),
                SizedBox(width: 12),
                Text('Motivo da Reprovação'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sua solicitação não foi aprovada pelo seguinte motivo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(req.adminNotes ?? 'Nenhuma observação informada.'),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Fechar'),
              ),
            ],
          ),
        );
        break;

      case RequestStatus.suspended:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Carteirinha Suspensa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sua carteirinha foi suspensa pela administração:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(req.adminNotes ?? 'Nenhum motivo informado.'),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () async {
                  if (!mounted) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  final whatsappUrl = Uri.parse("https://wa.me/5514981156828"); // Número oficial ConeCTEA
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Não foi possível abrir o WhatsApp de suporte.')),
                      );
                    }
                  }
                  if (mounted) navigator.pop();
                },
                icon: const Icon(Icons.gavel_rounded),
                label: const Text('Revisão de Suspensão'),
              ),
            ],
          ),
        );
        break;

      case RequestStatus.expired:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.event_busy_rounded, color: AppColors.error),
                SizedBox(width: 12),
                Text('Identificação Vencida'),
              ],
            ),
            content: const Text('Sua identificação digital venceu (365 dias). O pedido de renovação já foi enviado automaticamente para nossa equipe.'),
            actions: [
              TextButton.icon(
                onPressed: () {
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Entendido'),
              ),
            ],
          ),
        );
        break;

      case RequestStatus.pending:
      case RequestStatus.renewalRequested:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Estamos analisando sua solicitação de identificação digital. Por favor, aguarde.')),
              ],
            ),
          ),
        );
        break;
    }
  }

  void _showCardSelector(BuildContext context, List<IDRequest> approvedRequests) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.people_alt_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Escolha a Carteirinha',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione qual documento você deseja visualizar agora.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: approvedRequests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = approvedRequests[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MyIDScreen(requests: approvedRequests, initialIndex: index)));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.blue, AppColors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(req.applicantName),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.applicantName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 16,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Nº ${req.cardNumber ?? '----'}',
                                    style: const TextStyle(
                                      color: AppColors.primary, 
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
