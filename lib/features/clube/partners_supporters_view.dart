import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela interna informativa: Parceiros e apoiadores.
///
/// Adaptado para funcionar também como aba rolável ("Clube") na DS V2 via flag [isTab].
class PartnersSupportersView extends StatelessWidget {
  /// Se a tela está sendo exibida como aba da navbar principal.
  final bool isTab;

  const PartnersSupportersView({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    // Se estiver sendo exibida como aba, omitimos Scaffold, AppBackground e botões de fechamento.
    if (isTab) {
      return _buildTabContent(context);
    }

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
                        'Parceiros e apoiadores',
                        style: DsTipografia.pageTitle.copyWith(
                          color: DsCores.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conheça a rede de apoio comunitária ligada ao ConeCTEA.',
                        style: DsTipografia.pageSubtitle.copyWith(
                          color: DsCores.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bloco informativo inicial
                      DsCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                DsMolduraIcone(
                                  icon: PhosphorIconsRegular.handshake,
                                  accentColor: Color(
                                    0xFFA78BFA,
                                  ), // token institucional accent
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Rede de apoio',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: DsCores.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Esta área reunirá profissionais, clínicas, empresas e apoiadores que colaboram com ações, descontos, conditions especiais ou apoio à comunidade, conforme regras de cada parceiro.',
                              style: DsTipografia.body.copyWith(
                                color: DsCores.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bloco de cuidado/Importante
                      _buildWarningCard(context),
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

  /// Conteúdo adaptado para exibição como aba.
  Widget _buildTabContent(BuildContext context) {
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    const double headerVisualHeight = 64.0;
    const double headerClearance = 4.0;
    final double topPadding =
        topSafeArea + headerVisualHeight + headerClearance;

    final double bottomPadding =
        MediaQuery.paddingOf(context).bottom +
        120; // Folga adequada para o BottomNavBar do shell

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      // Espaçamento confortável de topo para a header do app e base para a navbar flutuante
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parceiros e apoiadores',
            style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Conheça a rede de apoio comunitária ligada ao ConeCTEA.',
            style: DsTipografia.pageSubtitle.copyWith(
              color: DsCores.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Bloco informativo inicial
          DsCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    DsMolduraIcone(
                      icon: PhosphorIconsRegular.handshake,
                      accentColor: Color(
                        0xFFA78BFA,
                      ), // token institucional accent
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rede de apoio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DsCores.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta área reunirá profissionais, clínicas, empresas e apoiadores que colaboram com ações, descontos, condições especiais ou apoio à comunidade, conforme regras de cada parceiro.',
                  style: DsTipografia.body.copyWith(
                    color: DsCores.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bloco de cuidado/Importante
          _buildWarningCard(context),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DsCores.alerta.softBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DsRaios.lg),
        border: Border.all(color: DsCores.alerta.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.warning,
                accentColor: DsCores.alerta.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Atenção',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A disponibilidade, condições e descontos podem variar conforme cada parceiro. A carteirinha comunitária ConeCTEA não garante benefício automático e não substitui documentos oficiais.',
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
