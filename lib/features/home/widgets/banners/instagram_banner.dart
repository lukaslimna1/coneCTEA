import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/home/widgets/banners/home_campaign_banner.dart';

class InstagramBanner extends StatelessWidget {
  const InstagramBanner({super.key});

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
      eyebrow: 'Instagram Oficial',
      eyebrowIcon: PhosphorIcons.instagramLogo(PhosphorIconsStyle.fill),
      title: 'Veja a comunidade em movimento',
      subtitle: 'Acompanhe ações, novidades e momentos da Família TEA Bauru.',
      ctaLabel: 'Ver Instagram',
      semanticToken: DsCores.institucional,
      theme: BannerTheme(
        backgroundColors: const [
          Color(0xFF38103A), // Magenta/Roxo escuro
          Color(0xFF1A0A2D), // Night Blue base
        ],
        primaryGlowColors: [
          const Color(0xFFE1306C).withValues(alpha: 0.3),
          const Color(0xFFE1306C).withValues(alpha: 0),
        ],
        secondaryGlowColors: [
          const Color(0xFFF56040).withValues(alpha: 0.2),
          const Color(0xFFF56040).withValues(alpha: 0),
        ],
        ctaColor: const Color(0xFFE1306C).withValues(alpha: 0.2),
        ctaTextColor: const Color(0xFFFFC0B3),
        illustrationAssetPath: 'assets/images/instagram_banner_art.webp',
        illustrationWidthFactor: 0.75, // Bem maior para avançar nas bordas
        illustrationRightOffset:
            -60, // Empurrado bem para a direita para respirar e cortar o lado direito
        illustrationOpacity: 0.35, // Ainda mais discreto
        illustrationFit: BoxFit.cover, // Garante que preencha bem o espaço
        illustrationAlignment: Alignment.centerRight,
      ),
      onTap: () => _launchUrl(
        context,
        'https://www.instagram.com/familiateabauru/',
        'Não foi possível abrir o Instagram agora. Tente novamente.',
      ),
    );
  }
}
