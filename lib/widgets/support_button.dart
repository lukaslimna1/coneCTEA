import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportButton extends StatelessWidget {
  const SupportButton({super.key});

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/5514999999999'); // Substitua pelo número real da ConeCTEA Bauru
    if (!await launchUrl(url)) {
      throw Exception('Não foi possível abrir o WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _launchWhatsApp,
      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
      icon: const Icon(Icons.chat, color: Colors.white),
      label: const Text('Suporte WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
