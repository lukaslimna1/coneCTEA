import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:conectea/features/home/widgets/banners/voluntariado_banner.dart';
import 'package:conectea/features/home/widgets/banners/instagram_banner.dart';
import 'package:conectea/features/home/widgets/banners/whatsapp_banner.dart';
import 'package:conectea/features/home/widgets/banners/site_banner.dart';

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

  @override
  Widget build(BuildContext context) {
    final banners = const [
      VoluntariadoBanner(),
      InstagramBanner(),
      WhatsAppBanner(),
      SiteBanner(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 304, // Altura reduzida para eliminar sobras abaixo do CTA
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
