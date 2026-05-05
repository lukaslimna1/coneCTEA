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
  List<IDRequest> _allRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final requests = await _db.getAllRequests();
    setState(() {
      _allRequests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _allRequests.where((r) => r.status == RequestStatus.pending).length;
    final approved = _allRequests.where((r) => r.status == RequestStatus.approved).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Stats
              Row(
                children: [
                  Expanded(child: _buildStatCard('Pendentes', pending.toString(), AppColors.pending)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Aprovadas', approved.toString(), AppColors.success)),
                ],
              ),
              const SizedBox(height: 32),
              
              Text(
                'Solicitações Recentes',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_allRequests.isEmpty)
                const Center(child: Text('Nenhuma solicitação encontrada.'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allRequests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = _allRequests[index];
                    return ListTile(
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(req.applicantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Status: ${req.statusLabel}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => RequestDetailAdmin(request: req))
                        );
                        _loadData();
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
