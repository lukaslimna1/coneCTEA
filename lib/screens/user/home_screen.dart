import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/id_request.dart';
import '../../core/app_theme.dart';
import 'request_id_screen.dart';
import 'my_id_screen.dart';
import 'terms_screen.dart';
import '../../widgets/support_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.currentProfile;
    final userId = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ConeCTEA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: const SupportButton(),
      body: StreamBuilder<List<IDRequest>>(
        stream: userId != null ? _db.streamUserRequests(userId) : Stream.value([]),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting && requests.isEmpty;

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Streams update automatically, but this allows manual pull-to-refresh feel
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${profile?.fullName ?? "Usuário"}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text('Acompanhe suas solicitações ou visualize sua carteirinha.'),
                  const SizedBox(height: 32),
                  
                  // Action Cards
                  _buildActionCard(
                    context,
                    title: 'Minha Carteirinha',
                    subtitle: 'Visualize seu documento digital',
                    icon: Icons.badge_outlined,
                    color: AppColors.primary,
                    onTap: () {
                      final approved = requests.where((r) => r.status == RequestStatus.approved).toList();
                      if (approved.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MyIDScreen(request: approved.first)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Você ainda não possui uma carteirinha aprovada.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    title: 'Nova Solicitação',
                    subtitle: 'Solicite uma nova carteirinha',
                    icon: Icons.add_card_outlined,
                    color: AppColors.secondary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestIDScreen())),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildActionCard(
                    context,
                    title: 'Termos e Privacidade',
                    subtitle: 'Saiba como cuidamos dos seus dados',
                    icon: Icons.shield_outlined,
                    color: AppColors.textSecondary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                  ),
                  
                  const SizedBox(height: 40),
                  Text(
                    'Minhas Solicitações',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  
                  if (isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ))
                  else if (requests.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('Nenhuma solicitação encontrada.'),
                    ))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return _buildRequestItem(req);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(IDRequest req) {
    Color statusColor;
    switch (req.status) {
      case RequestStatus.approved: statusColor = AppColors.success; break;
      case RequestStatus.pending: statusColor = AppColors.pending; break;
      case RequestStatus.rejected: statusColor = AppColors.error; break;
      default: statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Solicitada em ${_formatDate(req.createdAt)}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              req.statusLabel,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
