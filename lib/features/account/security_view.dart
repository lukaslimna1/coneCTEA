import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/core/widgets/premium/premium_hero.dart';
import 'package:conectea/features/account/terms_view.dart';
import 'package:conectea/features/account/privacy_policy_view.dart';
import 'package:conectea/features/account/consents_view.dart';
import 'package:conectea/features/account/stored_data_view.dart';
import 'package:conectea/features/account/information_usage_view.dart';

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
      backgroundColor: const Color(0xFF020C1C),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF071326).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Segurança',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const PremiumHero(
              icon: PhosphorIconsRegular.shieldCheck,
              title: 'Segurança e Privacidade',
              subtitle: 'Gerencie suas configurações de acesso e proteção de dados.',
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('ACESSO E AUTENTICAÇÃO'),
                  _buildCard([
                    _buildInfoTile(
                      icon: PhosphorIconsRegular.envelope,
                      title: 'E-mail de login',
                      subtitle: user?.email ?? 'Não identificado',
                    ),
                    _buildActionTile(
                      icon: PhosphorIconsRegular.lock,
                      title: 'Alterar senha',
                      subtitle: _lastResetRequest != null ? 'E-mail enviado recentemente' : 'Redefinir sua senha de acesso',
                      isLoading: _isResettingPassword,
                      onTap: () => _handleResetPassword(context),
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('PRIVACIDADE DOS DADOS'),
                  _buildCard([
                    _buildActionTile(
                      icon: PhosphorIconsRegular.database,
                      title: 'Dados armazenados',
                      subtitle: 'Veja quais informações coletamos',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StoredDataView()),
                      ),
                    ),
                    _buildActionTile(
                      icon: PhosphorIconsRegular.eye,
                      title: 'Uso das informações',
                      subtitle: 'Entenda para que servem seus dados',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InformationUsageView()),
                      ),
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('TERMOS E CONSENTIMENTOS'),
                  _buildCard([
                    _buildActionTile(
                      icon: PhosphorIconsRegular.fileText,
                      title: 'Termos de Uso',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsView()),
                      ),
                    ),
                    _buildActionTile(
                      icon: PhosphorIconsRegular.shieldCheck,
                      title: 'Política de Privacidade',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyView()),
                      ),
                    ),
                    _buildActionTile(
                      icon: PhosphorIconsRegular.checkCircle,
                      title: 'Meus Consentimentos',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ConsentsView()),
                      ),
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('CONTA'),
                  _buildCard([
                    _buildActionTile(
                      icon: PhosphorIconsRegular.trash,
                      title: 'Solicitar exclusão da conta',
                      titleColor: AppColors.errorRed,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ConeCTEA v1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Protegido por LGPD',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D3A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.03),
                  indent: 64,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (titleColor ?? AppColors.textPrimary).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading 
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Icon(icon, color: titleColor ?? AppColors.textPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: titleColor != null ? titleColor.withValues(alpha: 0.7) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isLoading)
              Icon(
                PhosphorIconsRegular.caretRight,
                color: (titleColor ?? AppColors.textSecondary).withValues(alpha: 0.3),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D3A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.warning, color: AppColors.errorRed, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Solicitar Exclusão',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 22),
            ),
          ],
        ),
        content: Text(
          'Esta ação é irreversível. Todos os seus dados, documentos e histórico serão excluídos permanentemente de acordo com a LGPD.\n\nVocê deseja continuar com a solicitação?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Excluir Conta', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sua solicitação foi enviada para análise da nossa equipe de privacidade.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.surfaceDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleResetPassword(BuildContext context) async {
    if (_lastResetRequest != null && DateTime.now().difference(_lastResetRequest!).inMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aguarde um momento antes de solicitar novamente.'),
          backgroundColor: AppColors.alertOrange,
          behavior: SnackBarBehavior.floating,
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-mail de redefinição enviado para $email'),
          backgroundColor: AppColors.statusGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      String errorMsg = 'Erro ao enviar e-mail de redefinição';
      if (e.toString().contains('rate_limit')) {
        errorMsg = 'Muitas solicitações. Por favor, aguarde um minuto.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }
}

