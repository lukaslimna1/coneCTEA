import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

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
      backgroundColor: AppColors.backgroundPremium,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPremium,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF243B6B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gerenciar Consentimentos',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF243B6B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              icon: Icons.check_circle_outline_rounded,
              title: 'Seus Consentimentos',
              subtitle: 'Controle como seus dados são utilizados e quais comunicações você deseja receber.',
              iconColor: const Color(0xFF8E6FF7),
            ),
            const SizedBox(height: 32),
            
            _buildSectionTitle('DADOS E PRIVACIDADE'),
            _buildConsentCard(
              title: 'Dados de Saúde e Deficiência',
              description: 'Permite o processamento de informações sensíveis para a emissão da Carteira de Identificação do Autista (CIPTEA) e acesso a benefícios.',
              value: _healthDataConsent,
              onChanged: (val) => setState(() => _healthDataConsent = val),
              icon: Icons.monitor_heart_outlined,
              isMandatory: true,
            ),
            _buildConsentCard(
              title: 'Compartilhamento com Parceiros',
              description: 'Permite o compartilhamento de dados anônimos para fins estatísticos e melhoria de políticas públicas voltadas ao autismo.',
              value: _shareDataConsent,
              onChanged: (val) => setState(() => _shareDataConsent = val),
              icon: Icons.share_outlined,
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('COMUNICAÇÕES'),
            _buildConsentCard(
              title: 'Notificações do App',
              description: 'Receba alertas sobre o status da sua carteirinha, atualizações importantes e avisos do sistema.',
              value: _notificationConsent,
              onChanged: (val) => setState(() => _notificationConsent = val),
              icon: Icons.notifications_none_rounded,
            ),
            _buildConsentCard(
              title: 'Informativos e Eventos',
              description: 'Receba e-mails sobre eventos, palestras e novidades da comunidade Família TEA Bauru.',
              value: _marketingConsent,
              onChanged: (val) => setState(() => _marketingConsent = val),
              icon: Icons.mail_outline_rounded,
            ),
            
            const SizedBox(height: 32),
            _buildInfoBox(),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preferências de consentimento salvas com sucesso!'),
                      backgroundColor: Color(0xFF2FB171),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF243B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'SALVAR PREFERÊNCIAS',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({required IconData icon, required String title, required String subtitle, required Color iconColor}) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2E4D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6C7A96),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF6C7A96),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF243B6B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2E4D),
                          ),
                        ),
                        if (isMandatory) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE35D5D).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OBRIGATÓRIO',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE35D5D),
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
                 activeTrackColor: const Color(0xFF2FB171),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6C7A96),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2CCCD3).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2CCCD3).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2CCCD3), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Você pode revogar ou alterar seus consentimentos a qualquer momento. Algumas alterações podem levar até 24h para serem processadas em todos os nossos sistemas.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF243B6B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
