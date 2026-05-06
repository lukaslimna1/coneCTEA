import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Privacidade')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTermSection(
              context,
              icon: Icons.gavel,
              title: 'Termos de Uso',
              content: 'O aplicativo ConeCTEA destina-se a facilitar a identificação digital de pessoas autistas através de uma carteirinha digital acessível. '
                       'Os dados fornecidos são de inteira responsabilidade do usuário.',
            ),
            const SizedBox(height: 24),
            _buildTermSection(
              context,
              icon: Icons.security,
              title: 'Privacidade de Dados',
              content: 'Nós respeitamos a sua privacidade. Seus dados textuais são armazenados de forma segura no Firebase (Google Cloud) e são utilizados '
                       'exclusivamente para a geração da sua carteirinha digital e validação pela nossa equipe administrativa. '
                       'Não compartilhamos seus dados com terceiros sem o seu consentimento, exceto conforme exigido por lei.',
            ),
            const SizedBox(height: 24),
            _buildTermSection(
              context,
              icon: Icons.verified_user,
              title: 'Validação Externa',
              content: 'Toda a validação de documentos (RG, CPF, Laudo) é feita externamente via WhatsApp. O aplicativo não armazena arquivos sensíveis.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(BuildContext context, {required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
