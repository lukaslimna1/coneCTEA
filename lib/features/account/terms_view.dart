import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

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
          'Termos de Uso',
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
              icon: Icons.description_rounded,
              title: 'Termos de Uso',
              subtitle: 'Conheça as regras de utilização do aplicativo ConeCTEA.',
              iconColor: const Color(0xFF8E6FF7),
            ),
            const SizedBox(height: 24),
            
            _buildBlock(
              '1. Sobre estes termos',
              'Estes Termos de Uso definem as regras para acesso e utilização do aplicativo ConeCTEA. Ao utilizar o aplicativo, o usuário declara estar ciente e de acordo com as condições aqui apresentadas.',
            ),
            _buildBlock(
              '2. Finalidade do ConeCTEA',
              'O ConeCTEA foi desenvolvido para facilitar o acesso a serviços, informações e funcionalidades relacionadas à carteirinha digital, solicitações, acompanhamento de status e comunicação com a instituição responsável.',
            ),
            _buildListBlock(
              '3. Responsabilidades do usuário',
              [
                'Fornecer informações verdadeiras e atualizadas',
                'Utilizar o aplicativo de forma adequada e responsável',
                'Manter seus dados de acesso em segurança',
                'Não compartilhar a conta com terceiros',
                'Respeitar as regras e finalidades do aplicativo',
              ],
            ),
            _buildBlock(
              '4. Responsabilidades da plataforma',
              'O ConeCTEA busca oferecer uma experiência acessível, organizada e segura. A instituição responsável poderá analisar solicitações, atualizar informações e gerenciar o status da carteirinha conforme seus critérios e procedimentos internos.',
            ),
            _buildListBlock(
              '5. Condutas não permitidas',
              [
                'Utilizar dados falsos ou de terceiros sem autorização',
                'Tentar acessar áreas não autorizadas do sistema',
                'Fazer uso indevido da carteirinha digital',
                'Praticar ações que prejudiquem o funcionamento do aplicativo',
                'Utilizar o app para fins ilegais ou fraudulentos',
              ],
            ),
            _buildBlock(
              '6. Atualizações dos termos',
              'Os Termos de Uso poderão ser atualizados a qualquer momento para melhoria do serviço, adequação legal ou evolução do aplicativo. Sempre que houver alterações relevantes, o usuário poderá ser notificado.',
            ),
            
            const SizedBox(height: 12),
            _buildVersionCard('1.0', '08/05/2026'),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF243B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'ENTENDI',
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

  Widget _buildBlock(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2E4D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6C7A96),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBlock(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2E4D),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0, right: 10),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF2CCCD3)),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6C7A96),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildVersionCard(String version, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF243B6B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versão $version', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF243B6B))),
              Text('Vigência: $date', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6C7A96))),
            ],
          ),
          Text(
            'Atualizado em $date',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6C7A96)),
          ),
        ],
      ),
    );
  }
}
