import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/home/widgets/banners/home_campaign_banner.dart';

class WhatsAppBanner extends StatelessWidget {
  const WhatsAppBanner({super.key});

  Future<void> _launchUrl(BuildContext context, String url, String errorMessage) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        _showError(context, errorMessage);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, errorMessage);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DsCores.alerta.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeCampaignBanner(
      eyebrow: 'Comunidade',
      eyebrowIcon: PhosphorIcons.whatsappLogo(PhosphorIconsStyle.fill),
      title: 'Fique por dentro\nde tudo',
      subtitle: 'Entre no grupo oficial para receber avisos, trocas e novidades.',
      ctaLabel: 'Entrar no grupo',
      semanticToken: DsCores.comunicacao,
      theme: BannerTheme(
        backgroundColors: const [
          Color(0xFF093123), // Verde muito escuro
          Color(0xFF0A2530), // Teal escuro
          Color(0xFF071221), // Night Blue base
        ],
        primaryGlowColors: [
          const Color(0xFF25D366).withValues(alpha: 0.25),
          const Color(0xFF25D366).withValues(alpha: 0),
        ],
        secondaryGlowColors: [
          const Color(0xFF128C7E).withValues(alpha: 0.2),
          const Color(0xFF128C7E).withValues(alpha: 0),
        ],
        ctaColor: const Color(0xFF25D366).withValues(alpha: 0.2),
        ctaTextColor: const Color(0xFF69F0AE),
        illustrationAssetPath: 'assets/images/whatsapp_banner_art.png',
        illustrationWidthFactor: 0.60,
        illustrationRightOffset: -32,
        illustrationOpacity: 0.45, // Ajuste para 0.40 a 0.50
        illustrationFit: BoxFit.fitHeight,
        illustrationAlignment: Alignment.centerRight,
      ),
      onTap: () => _launchUrl(
        context,
        'https://chat.whatsapp.com/Hhl4SmcahMZ3DX8GEkpQ6s?mode=ac_t',
        'Não foi possível abrir o WhatsApp agora. Tente novamente.',
      ),
    );
  }
}
