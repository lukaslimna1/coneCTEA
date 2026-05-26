import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/home/widgets/banners/home_campaign_banner.dart';

class VoluntariadoBanner extends StatelessWidget {
  const VoluntariadoBanner({super.key});

  Future<void> _launchUrl(
    BuildContext context,
    String url,
    String errorMessage,
  ) async {
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
      SnackBar(content: Text(message), backgroundColor: DsCores.alerta.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeCampaignBanner(
      eyebrow: 'Voluntariado',
      eyebrowIcon: PhosphorIcons.handHeart(PhosphorIconsStyle.fill),
      title: 'Faça parte dessa rede de apoio',
      subtitle:
          'Doe tempo, acolhimento e presença para fortalecer ações da comunidade.',
      ctaLabel: 'Quero ajudar',
      semanticToken: DsCores.institucional,
      theme: BannerTheme(
        backgroundColors: const [
          Color(0xFF2C103F), // Violeta profundo
          Color(0xFF4A154B), // Magenta escuro
          Color(0xFF1E0A2D), // Fundo Night
        ],
        primaryGlowColors: [
          const Color(0xFFFF5E7E).withValues(alpha: 0.3),
          const Color(0xFFFF5E7E).withValues(alpha: 0),
        ],
        secondaryGlowColors: [
          const Color(0xFF9D4EDD).withValues(alpha: 0.2),
          const Color(0xFF9D4EDD).withValues(alpha: 0),
        ],
        ctaColor: const Color(0xFFFF5E7E).withValues(alpha: 0.2),
        ctaTextColor: const Color(0xFFFFB199),
        illustrationAssetPath: 'assets/images/voluntariado_banner_art.webp',
        illustrationWidthFactor: 0.60,
        illustrationRightOffset: -32,
        illustrationOpacity: 0.48, // Ajuste para 0.45 a 0.52
        illustrationFit: BoxFit.fitHeight,
        illustrationAlignment: Alignment.centerRight,
      ),
      onTap: () => _launchUrl(
        context,
        'https://chat.whatsapp.com/Epty4YJ0PP9CMGJuru6Gxv',
        'Não foi possível abrir o link agora. Tente novamente.',
      ),
    );
  }
}
