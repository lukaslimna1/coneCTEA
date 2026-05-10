import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_hero.dart';

class InformationUsageView extends StatelessWidget {
  const InformationUsageView({super.key});

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
          'Uso das Informações',
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
              icon: PhosphorIconsRegular.eye,
              title: 'Como usamos seus dados?',
              subtitle: 'Entenda a finalidade de cada informação processada pelo ConeCTEA.',
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionBlock(
                    '1. Gestão de Conta',
                    'Seu e-mail e senha são usados exclusivamente para garantir que apenas você tenha acesso às suas informações e à sua carteirinha digital.',
                    '1',
                  ),
                  
                  _buildSectionBlock(
                    '2. Emissão e Validação',
                    'Os dados de saúde e identificação são usados para gerar o QR Code de validação da carteirinha, permitindo que autoridades e parceiros confirmem sua autenticidade.',
                    '2',
                  ),

                  _buildSectionBlock(
                    '3. Comunicação Direta',
                    'Utilizamos seus dados de contato para enviar alertas sobre prazos de renovação, atualizações no aplicativo e avisos da Família TEA Bauru.',
                    '3',
                  ),

                  _buildSectionBlock(
                    '4. Melhoria de Serviços',
                    'Dados anonimizados (sem identificação pessoal) podem ser usados para gerar estatísticas que ajudam na melhoria de políticas públicas para a comunidade autista.',
                    '4',
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

  Widget _buildSectionBlock(String title, String content, String number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D3A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumberBadge(number),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFFB8C7E6),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberBadge(String number) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.2),
            const Color(0xFF22D3EE).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          number,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF22D3EE),
          ),
        ),
      ),
    );
  }
}
