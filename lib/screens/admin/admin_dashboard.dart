import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/id_request.dart';
import '../../core/app_theme.dart';
import 'request_detail_admin.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Verificar vencimentos globais ao entrar no painel
    _checkExpirations();
  }

  Future<void> _checkExpirations() async {
    await _db.checkAllExpirations();
    if (!mounted) return;
    // Forçar atualização se necessário
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<IDRequest>>(
      stream: _db.streamAllRequests(),
      builder: (context, snapshot) {
        final allRequests = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && allRequests.isEmpty;
        
        final pending = allRequests.where((r) => r.status == RequestStatus.pending).length;
        final waitingDoc = allRequests.where((r) => r.status == RequestStatus.waitingDocument).length;
        final approved = allRequests.where((r) => r.status == RequestStatus.approved).length;
        final renewal = allRequests.where((r) => r.status == RequestStatus.renewalRequested || r.status == RequestStatus.expired).length;

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Erro: ${snapshot.error}')));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Painel de Gestão', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  centerTitle: false,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.navy, Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: 'Sair do Portal',
                    onPressed: () async {
                      if (!mounted) return;
                      final auth = context.read<AuthService>();
                      final navigator = Navigator.of(context);
                      await auth.signOut();
                      if (!mounted) return;
                      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Stats
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatCard('Pendentes', pending.toString(), AppColors.pending, Icons.hourglass_empty),
                            const SizedBox(width: 12),
                            _buildStatCard('Documentação', waitingDoc.toString(), const Color(0xFF1E63D8), Icons.file_present),
                            const SizedBox(width: 12),
                            _buildStatCard('Renovação', renewal.toString(), Colors.purple, Icons.history),
                            const SizedBox(width: 12),
                            _buildStatCard('Aprovadas', approved.toString(), AppColors.success, Icons.check_circle_outline),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      const Row(
                        children: [
                          Icon(Icons.list_alt_rounded, color: AppColors.navy, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Solicitações Recentes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ))
                      else if (allRequests.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('Nenhuma solicitação encontrada.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allRequests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final req = allRequests[index];
                            return _buildAdminRequestItem(context, req, index);
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAdminRequestItem(BuildContext context, IDRequest req, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailAdmin(request: req))),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  image: req.photoUrl != null 
                    ? DecorationImage(image: NetworkImage(req.photoUrl!), fit: BoxFit.cover)
                    : null,
                ),
                child: req.photoUrl == null 
                  ? const Icon(Icons.person_rounded, color: AppColors.navy, size: 24)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.applicantName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)
                    ),
                    Text(
                      'ID: ${req.id.substring(0, 8)}... • ${req.city}', 
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: req.statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(req.statusIcon, color: req.statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      req.adminStatusLabel,
                      style: TextStyle(
                        color: req.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
