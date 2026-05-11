import 'package:flutter/material.dart';
import 'home_section_header.dart';

/// Componente genérico para seções horizontais com título e lista de itens.
/// Substitui o antigo '_buildCarouselSection' da HomeView.
class HomeHorizontalSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final double height;
  final double titleSpacing;
  final double horizontalPadding;

  const HomeHorizontalSection({
    super.key,
    required this.title,
    required this.items,
    this.height = 185,
    this.titleSpacing = 16,
    this.horizontalPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: title,
          horizontalPadding: horizontalPadding,
          bottomSpacing: 0,
        ),
        SizedBox(height: titleSpacing),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }
}
