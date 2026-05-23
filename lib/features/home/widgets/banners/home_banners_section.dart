import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/home/widgets/banners/highlight_banner.dart';

/// Bloco de banners oficiais da Família TEA Bauru.
/// Concentra os canais de comunicação externos da comunidade.
class HomeBannersSection extends StatefulWidget {
  const HomeBannersSection({super.key});

  @override
  State<HomeBannersSection> createState() => _HomeBannersSectionState();
}

class _HomeBannersSectionState extends State<HomeBannersSection> {
  final PageController _pageController = PageController(viewportFraction: 0.96);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
    final banners = [
      // 1. Seja Voluntário
      HighlightBanner(
        eyebrow: 'Voluntariado',
        title: 'Faça parte dessa\nrede de apoio',
        subtitle: 'Sua ajuda pode fortalecer ações, acolhimento e projetos da comunidade.',
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
          illustrationAssetPath: 'assets/images/voluntariado_banner_art.png',
          customIllustration: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: -20,
                child: Transform.rotate(
                  angle: -0.15,
                  child: Icon(
                    PhosphorIcons.handHeart(PhosphorIconsStyle.fill),
                    size: 160,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E7E).withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    PhosphorIcons.heart(PhosphorIconsStyle.fill),
                    size: 70,
                    color: const Color(0xFFFFB199).withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () => _launchUrl(
          context,
          'https://chat.whatsapp.com/Epty4YJ0PP9CMGJuru6Gxv',
          'Não foi possível abrir o link agora. Tente novamente.',
        ),
      ),
      // 2. Instagram
      HighlightBanner(
        eyebrow: 'Instagram Oficial',
        title: 'Veja o que acontece\nna comunidade',
        subtitle: 'Acompanhe novidades, ações e momentos da Família TEA Bauru.',
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
          customIllustration: Stack(
            children: [
              Positioned(
                right: 10,
                top: 20,
                child: Transform.rotate(
                  angle: 0.15,
                  child: Icon(
                    PhosphorIcons.instagramLogo(PhosphorIconsStyle.regular),
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                right: 90,
                bottom: 50,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    PhosphorIcons.heart(PhosphorIconsStyle.fill),
                    size: 40,
                    color: const Color(0xFFE1306C).withValues(alpha: 0.6),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: 10,
                child: Transform.rotate(
                  angle: 0.1,
                  child: Icon(
                    PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                    size: 50,
                    color: const Color(0xFFF56040).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () => _launchUrl(
          context,
          'https://www.instagram.com/familiateabauru/',
          'Não foi possível abrir o Instagram agora. Tente novamente.',
        ),
      ),
      // 3. Grupo do WhatsApp (Comunidade)
      HighlightBanner(
        eyebrow: 'Comunidade',
        title: 'Fique perto da\ncomunidade',
        subtitle: 'Entre no grupo oficial e receba avisos, trocas e novidades.',
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
          customIllustration: Stack(
            children: [
              Positioned(
                right: 20,
                top: 30,
                child: Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    width: 90,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 3,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIcons.whatsappLogo(PhosphorIconsStyle.fill),
                        size: 50,
                        color: const Color(0xFF25D366).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 80,
                bottom: 20,
                child: Transform.rotate(
                  angle: 0.15,
                  child: Icon(
                    PhosphorIcons.chatTeardropDots(PhosphorIconsStyle.fill),
                    size: 60,
                    color: const Color(0xFF128C7E).withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () => _launchUrl(
          context,
          'https://chat.whatsapp.com/Hhl4SmcahMZ3DX8GEkpQ6s?mode=ac_t',
          'Não foi possível abrir o WhatsApp agora. Tente novamente.',
        ),
      ),
      // 4. Site Oficial (Em Breve)
      HighlightBanner(
        eyebrow: 'Portal',
        title: 'Um novo portal\nestá a caminho',
        subtitle: 'Estamos preparando um espaço oficial com mais informação e conexão.',
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
          customIllustration: Stack(
            children: [
              Positioned(
                right: 30,
                top: -10,
                child: Transform.rotate(
                  angle: 0.1,
                  child: Container(
                    width: 120,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                        width: 2,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              CircleAvatar(radius: 3, backgroundColor: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(width: 4),
                              CircleAvatar(radius: 3, backgroundColor: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(width: 4),
                              CircleAvatar(radius: 3, backgroundColor: Colors.white.withValues(alpha: 0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -10,
                bottom: 20,
                child: Icon(
                  PhosphorIcons.globeHemisphereWest(PhosphorIconsStyle.light),
                  size: 110,
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 10,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    PhosphorIcons.cursor(PhosphorIconsStyle.fill),
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          // Apenas inativo - Em breve
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            padEnds: false,
            itemBuilder: (context, index) {
              // Adicionamos padding left apenas no primeiro item para alinhamento
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 20 : 0),
                child: banners[index],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Indicador de paginação (dots) e hint de swipe
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 24 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_outlined,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  'Arraste para ver mais',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
