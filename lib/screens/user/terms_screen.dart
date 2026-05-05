import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Privacidade')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termos de Uso',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'O aplicativo ConeCTEA destina-se a facilitar a identificação de pessoas autistas através de uma carteirinha digital. '
              'Os dados fornecidos são de inteira responsabilidade do usuário.',
            ),
            SizedBox(height: 24),
            Text(
              'Privacidade de Dados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Nós respeitamos a sua privacidade. Seus dados textuais são armazenados de forma segura no Firebase (Google Cloud) e são utilizados '
              'exclusivamente para a geração da sua carteirinha digital e validação pela nossa equipe administrativa. '
              'Não compartilhamos seus dados com terceiros sem o seu consentimento, exceto conforme exigido por lei.',
            ),
            SizedBox(height: 24),
            Text(
              'Validação Externa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Toda a validação de documentos (RG, CPF, Laudo) é feita externamente via WhatsApp. O aplicativo não armazena arquivos sensíveis.',
            ),
          ],
        ),
      ),
    );
  }
}
