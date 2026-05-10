import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/colors.dart';
import '../../widgets/premium_hero.dart';

class ConsentsView extends StatefulWidget {
  const ConsentsView({super.key});

  @override
  State<ConsentsView> createState() => _ConsentsViewState();
}

class _ConsentsViewState extends State<ConsentsView> {
  bool _healthDataConsent = true;
  bool _notificationConsent = true;
  bool _marketingConsent = false;
  bool _shareDataConsent = false;

  @override
  Widget build(BuildContext context) {
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
          'Consentimentos',
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
              icon: PhosphorIconsRegular.checkCircle,
              title: 'Seus Consentimentos',
              subtitle: 'Controle como seus dados são utilizados e quais comunicações você deseja receber.',
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('DADOS E PRIVACIDADE'),
                  _buildConsentCard(
                    title: 'Dados de Saúde e Deficiência',
                    description: 'Permite o processamento de informações sensíveis para a emissão da Carteira de Identificação do Autista e acesso a benefícios.',
                    value: _healthDataConsent,
                    onChanged: (val) => setState(() => _healthDataConsent = val),
                    icon: PhosphorIconsRegular.heartbeat,
                    isMandatory: true,
                  ),
                  _buildConsentCard(
                    title: 'Compartilhamento Estatístico',
                    description: 'Permite o uso de dados anonimizados para fins estatísticos e melhoria de políticas públicas voltadas ao autismo.',
                    value: _shareDataConsent,
                    onChanged: (val) => setState(() => _shareDataConsent = val),
                    icon: PhosphorIconsRegular.chartBar,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('COMUNICAÇÕES'),
                  _buildConsentCard(
                    title: 'Notificações do Sistema',
                    description: 'Receba alertas sobre o status da sua carteirinha, atualizações importantes e avisos do sistema.',
                    value: _notificationConsent,
                    onChanged: (val) => setState(() => _notificationConsent = val),
                    icon: PhosphorIconsRegular.bell,
                  ),
                  _buildConsentCard(
                    title: 'Informativos e Eventos',
                    description: 'Receba informações sobre eventos, palestras e novidades da comunidade Família TEA Bauru.',
                    value: _marketingConsent,
                    onChanged: (val) => setState(() => _marketingConsent = val),
                    icon: PhosphorIconsRegular.megaphone,
                  ),
                  
                  const SizedBox(height: 32),
                  _buildInfoBox(),
                  
                  const SizedBox(height: 32),
                  _buildSaveButton(context),
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

  Widget _buildConsentCard({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    bool isMandatory = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D3A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isMandatory) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OBRIGATÓRIO',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: isMandatory ? null : onChanged,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF22D3EE).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(PhosphorIconsRegular.info, color: Color(0xFF22D3EE), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Você pode revogar ou alterar seus consentimentos a qualquer momento. Algumas alterações podem levar até 24h para serem processadas.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFB8C7E6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Preferências salvas com sucesso!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AppColors.statusGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'SALVAR PREFERÊNCIAS',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

