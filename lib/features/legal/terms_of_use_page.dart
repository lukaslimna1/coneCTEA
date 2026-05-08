import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:conectea/core/constants/colors.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Termos de Uso',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('📄 TERMOS DE USO'),
            const SizedBox(height: 8),
            _buildText('ConeCTEA'),
            _buildText('Versão: 1.0'),
            _buildText('Última atualização: Documento em elaboração'),
            _buildText('Instituição responsável: Família TEA Bauru'),
            _buildText('Contato oficial: https://www.instagram.com/familiateabauru'),
            _buildText('Cidade/Estado: Bauru — SP'),
            
            const SizedBox(height: 24),
            _buildSectionTitle('1. Sobre estes Termos'),
            _buildText(
              'Estes Termos de Uso estabelecem as regras para acesso e utilização do aplicativo ConeCTEA, incluindo suas funcionalidades, serviços, informações, solicitações, carteirinha digital, área do usuário e área administrativa.\n\n'
              'Ao criar uma conta, acessar ou utilizar o aplicativo, o usuário declara que leu, compreendeu e concorda com estes Termos de Uso, bem como com a Política de Privacidade do ConeCTEA.\n\n'
              'Caso o usuário não concorde com estes Termos, deverá interromper o uso do aplicativo.'
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('2. Sobre o ConeCTEA'),
            _buildText(
              'O ConeCTEA é um aplicativo desenvolvido para facilitar o acesso à carteirinha digital, organizar solicitações, permitir acompanhamento de status, centralizar informações importantes e melhorar a comunicação entre usuários, responsáveis e a instituição Família TEA Bauru.'
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('3. Responsabilidades do Usuário'),
            _buildText(
              '• Fornecer informações verídicas e atualizadas.\n'
              '• Manter a segurança de sua conta e senha.\n'
              '• Utilizar a carteirinha digital de forma ética e legal.\n'
              '• Não utilizar o aplicativo para fins ilícitos ou que violem direitos de terceiros.'
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('4. Propriedade Intelectual'),
            _buildText(
              'Todo o conteúdo, design, logotipos e funcionalidades do ConeCTEA são de propriedade da Família TEA Bauru ou licenciados para tal, sendo protegidos por leis de direitos autorais e propriedade intelectual.'
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('5. Alterações nos Termos'),
            _buildText(
              'A Família TEA Bauru reserva-se o direito de atualizar estes Termos a qualquer momento. Notificações sobre mudanças significativas serão enviadas através do aplicativo ou e-mail cadastrado.'
            ),

            const SizedBox(height: 48),
            Center(
              child: Text(
                '© 2024 Família TEA Bauru. Todos os direitos reservados.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
