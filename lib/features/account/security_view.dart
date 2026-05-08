import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import 'terms_view.dart';
import 'privacy_policy_view.dart';
import 'consents_view.dart';


class SecurityView extends StatefulWidget {
  const SecurityView({super.key});

  @override
  State<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends State<SecurityView> {
  bool _isResettingPassword = false;
  DateTime? _lastResetRequest;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Segurança e Privacidade',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.darkBlue),
        ),
        backgroundColor: AppColors.backgroundPremium,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('🔐 ACESSO E AUTENTICAÇÃO'),
            _buildCard([
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'E-mail de login',
                subtitle: user?.email ?? 'Não identificado',
              ),
              _buildActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Alterar senha',
                subtitle: _lastResetRequest != null ? 'E-mail enviado recentemente' : null,
                isLoading: _isResettingPassword,
                onTap: () => _handleResetPassword(context),
              ),
              _buildActionTile(
                icon: Icons.devices_rounded,
                title: 'Dispositivos conectados',
                onTap: () {}, // Implementação futura
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle('🧾 PRIVACIDADE DOS DADOS'),
            _buildCard([
              _buildActionTile(
                icon: Icons.storage_rounded,
                title: 'Dados armazenados',
                subtitle: 'Veja quais informações coletamos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyView()),
                ),
              ),
              _buildActionTile(
                icon: Icons.visibility_outlined,
                title: 'Uso das informações',
                subtitle: 'Entenda para que servem seus dados',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyView()),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle('📜 TERMOS E CONSENTIMENTOS'),
            _buildCard([
              _buildActionTile(
                icon: Icons.description_outlined,
                title: 'Termos de Uso',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsView()),
                ),
              ),
              _buildActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Política de Privacidade',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyView()),
                ),
              ),
              _buildActionTile(
                icon: Icons.fact_check_outlined,
                title: 'Meus Consentimentos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConsentsView()),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle('🗑️ CONTA'),
            _buildCard([
              _buildActionTile(
                icon: Icons.delete_forever_rounded,
                title: 'Solicitar exclusão da conta',
                titleColor: AppColors.errorRed,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ]),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'ConeCTEA v1.0.0\nProtegido por LGPD',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? titleColor,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (titleColor ?? AppColors.darkBlue).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, color: titleColor ?? AppColors.darkBlue, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.darkBlue,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.statusGreen)) : null,
      trailing: isLoading 
        ? null 
        : Icon(Icons.chevron_right_rounded, color: titleColor ?? AppColors.textSecondary),
      onTap: isLoading ? null : onTap,
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Solicitar Exclusão',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.darkBlue),
            ),
          ],
        ),
        content: Text(
          'Esta ação é irreversível. Todos os seus dados, documentos e histórico serão excluídos permanentemente de acordo com a LGPD.\n\nVocê deseja continuar com a solicitação?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Excluir Conta'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sua solicitação foi enviada para análise da nossa equipe de privacidade.'),
            backgroundColor: AppColors.darkBlue,
          ),
        );
      }
    }
  }

  Future<void> _handleResetPassword(BuildContext context) async {
    // Rate limit manual para evitar erro do Supabase (1 por minuto)
    if (_lastResetRequest != null && DateTime.now().difference(_lastResetRequest!).inMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde um momento antes de solicitar novamente. Verifique sua caixa de entrada.'),
          backgroundColor: AppColors.alertOrange,
        ),
      );
      return;
    }

    final email = AuthService().currentUser?.email;
    if (email == null) return;

    setState(() => _isResettingPassword = true);

    try {
      await AuthService().sendPasswordResetEmail(email);
      _lastResetRequest = DateTime.now();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-mail de redefinição enviado para $email'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMsg = 'Erro ao enviar e-mail de redefinição';
      if (e.toString().contains('rate_limit')) {
        errorMsg = 'Muitas solicitações. Por favor, aguarde um minuto.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

}
