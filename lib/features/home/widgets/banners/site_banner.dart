import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/home/widgets/banners/home_campaign_banner.dart';

class SiteBanner extends StatelessWidget {
  const SiteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCampaignBanner(
      eyebrow: 'Portal',
      eyebrowIcon: PhosphorIcons.globeHemisphereWest(PhosphorIconsStyle.fill),
      title: 'Novo portal a caminho',
      subtitle:
          'Estamos preparando um espaço oficial com mais informação, conteúdo e conexão.',
      ctaLabel: 'Em breve',
      semanticToken: DsCores.institucional,
      theme: BannerTheme(
        backgroundColors: const [
          Color(0xFF0F1A42), // Azul profundo premium
          Color(0xFF091029), // Night Blue escuro
        ],
        primaryGlowColors: [
          const Color(0xFF00C6FF).withValues(alpha: 0.25),
          const Color(0xFF00C6FF).withValues(alpha: 0),
        ],
        secondaryGlowColors: [
          const Color(0xFF0072FF).withValues(alpha: 0.2),
          const Color(0xFF0072FF).withValues(alpha: 0),
        ],
        ctaColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
        ctaTextColor: const Color(0xFF80D8FF),
        illustrationAssetPath: 'assets/images/site_banner_art.webp',
        illustrationWidthFactor: 0.60,
        illustrationRightOffset: -40,
        illustrationOpacity: 0.40, // Ajuste para 0.36 a 0.46
        illustrationFit: BoxFit.fitHeight,
        illustrationAlignment: Alignment.centerRight,
      ),
      onTap: null,
    );
  }
}
