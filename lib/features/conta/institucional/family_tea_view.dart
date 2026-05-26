import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela interna informativa: Família TEA Bauru.
class FamilyTeaView extends StatelessWidget {
  const FamilyTeaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DsBotaoVoltar(
                        onPressed: () => Navigator.pop(context),
                        token: DsCores.institucional,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Família TEA Bauru',
                        style: DsTipografia.pageTitle.copyWith(
                          color: DsCores.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conheça a comunidade responsável pela iniciativa ConeCTEA.',
                        style: DsTipografia.pageSubtitle.copyWith(
                          color: DsCores.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bloco 1 — Quem somos
                      _buildBlock(
                        icon: PhosphorIconsRegular.users,
                        title: 'Quem somos',
                        text:
                            'A Família TEA Bauru é uma comunidade e rede de apoio formada por famílias, responsáveis, voluntários, profissionais e parceiros unidos por inclusão, respeito e acolhimento.',
                      ),
                      const SizedBox(height: 16),

                      // Bloco 2 — Por que existimos
                      _buildBlock(
                        icon: PhosphorIconsRegular.heart,
                        title: 'Por que existimos',
                        text:
                            'A comunidade existe para fortalecer vínculos, compartilhar informações, apoiar famílias e colaborar com ações que ampliem acolhimento, participação e inclusão.',
                      ),
                      const SizedBox(height: 16),

                      // Bloco 3 — Atuação em Bauru
                      _buildBlock(
                        icon: PhosphorIconsRegular.mapPin,
                        title: 'Atuação em Bauru',
                        text:
                            'A atuação principal acontece em Bauru/SP, com ações de apoio, informação, acolhimento e articulação comunitária.',
                      ),
                      const SizedBox(height: 16),

                      // Bloco 4 — Canais oficiais
                      _buildChannelsBlock(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Botão final
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: DsBotao(
                    label: 'Entendi',
                    onPressed: () => Navigator.pop(context),
                    variante: DsBotaoVariante.acao,
                    token: DsCores.institucional,
                    icon: PhosphorIconsRegular.check,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: icon,
                accentColor: const Color(
                  0xFFA78BFA,
                ), // token institucional accent
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: DsTipografia.body.copyWith(
              color: DsCores.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsBlock() {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsMolduraIcone(
                icon: PhosphorIconsRegular.headset,
                accentColor: Color(0xFFA78BFA),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Canais oficiais',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChannelItem(
            PhosphorIconsRegular.instagramLogo,
            'Instagram',
            'instagram.com/familiateabauru',
          ),
          const SizedBox(height: 12),
          _buildChannelItem(
            PhosphorIconsRegular.whatsappLogo,
            'Grupo comunitário oficial',
            'chat.whatsapp.com/Hhl4SmcahMZ3DX8GEkpQ6s',
          ),
          const SizedBox(height: 12),
          _buildChannelItem(
            PhosphorIconsRegular.envelope,
            'E-mail principal',
            'familiateabauru@gmail.com',
          ),
          const SizedBox(height: 12),
          _buildChannelItem(
            PhosphorIconsRegular.envelope,
            'E-mail secundário',
            'conecteabauru@gmail.com',
          ),
          const SizedBox(height: 12),
          _buildChannelItem(
            PhosphorIconsRegular.phone,
            'WhatsApp oficial',
            '+55 14 99101-2961 — Renata Ferreguti',
          ),
          const SizedBox(height: 12),
          _buildChannelItem(
            PhosphorIconsRegular.globe,
            'Site oficial',
            'Em breve',
          ),
        ],
      ),
    );
  }

  Widget _buildChannelItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DsCores.institucional.accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: DsTipografia.bodySmall.copyWith(
                color: DsCores.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            value,
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
