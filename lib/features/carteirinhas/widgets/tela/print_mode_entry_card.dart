import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintModeEntryCard**
/// Componente de entrada visual discreto e premium para o fluxo
/// de visualização/geração do PDF de impressão da carteirinha comunitária.
class PrintModeEntryCard extends StatelessWidget {
  final bool isActive;

  const PrintModeEntryCard({
    super.key,
    required this.isActive,
  });

  void _showPrintModeIntroSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: DsCores.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DsRaios.card),
              topRight: Radius.circular(DsRaios.card),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alça de arraste visual (Drag Handle)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Título e Ícone
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsBold.printer,
                        color: DsCores.carteirinha.accent,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Versão para impressão',
                          style: DsTipografia.sectionTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Descrição principal (revisada para voz ativa de produto)
                  Text(
                    'Gere uma versão em PDF da carteirinha comunitária para impressão. O arquivo é gerado no seu aparelho, e a família/responsável escolhe quais informações opcionais deseja incluir.',
                    style: DsTipografia.infoBody,
                  ),
                  const SizedBox(height: 24),

                  // 4 Passos Informativos / Passo a Passo Linear
                  _buildFeatureIntroStep(
                    icon: PhosphorIconsRegular.user,
                    title: '1. Escolha a carteirinha ativa',
                    description: 'Você selecionará qual carteirinha ativa deseja preparar para impressão.',
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureIntroStep(
                    icon: PhosphorIconsRegular.clipboardText,
                    title: '2. Revise os dados',
                    description: 'Nome, TEA-ID, validade, QR Code e logos entram obrigatoriamente. Os demais dados entram apenas se forem selecionados.',
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureIntroStep(
                    icon: PhosphorIconsRegular.arrowsLeftRight,
                    title: '3. Fluxo conforme o tipo',
                    description: 'Para Rede de Apoio TEA, é gerada a carteirinha frente e verso. Para Pessoa TEA, é possível escolher se deseja incluir o Perfil de Apoio TEA.',
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureIntroStep(
                    icon: PhosphorIconsRegular.hardDrive,
                    title: '4. Conteúdo local',
                    description: 'As informações do Perfil de Apoio TEA ficam salvas apenas neste aparelho e não são enviadas para o banco de dados.',
                  ),
                  const SizedBox(height: 24),

                  // Divisória sutil
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 20),

                  // Aviso Legal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIconsRegular.shieldWarning,
                        color: DsCores.alerta.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A carteirinha é comunitária/interna e não substitui CIPTEA, RG, CPF, CNH, laudo, diagnóstico ou documento oficial.',
                          style: DsTipografia.caption.copyWith(
                            color: DsCores.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Botão de Fechamento "Entendi" (Variante contorno para ser fiel à carteirinha e não admin)
                  DsBotao(
                    label: 'Entendi',
                    variante: DsBotaoVariante.contorno,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIntroStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: DsCores.surfaceElevated.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(DsRaios.card),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: DsCores.iconFrameBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(
              icon,
              color: DsCores.carteirinha.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DsTipografia.cardTitle.copyWith(
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: DsTipografia.cardDescription.copyWith(
                    fontSize: 12.0,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsCard(
      showTopAccent: true,
      accentColor: DsCores.carteirinha.accent,
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0), // Respiro aumentado de 16 para 20
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone e Título do Card
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.printer,
                color: DsCores.carteirinha.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Versão para impressão',
                style: DsTipografia.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Descrição do Card (revisada para voz ativa de produto)
          Text(
            'Gere uma versão em PDF da carteirinha comunitária para imprimir. Você poderá escolher quais informações opcionais deseja incluir.',
            style: DsTipografia.cardDescription,
          ),
          const SizedBox(height: 20),

          // Botão e Observação do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Observação
              Expanded(
                child: Text(
                  'Disponível para carteirinhas ativas.',
                  style: DsTipografia.cardMuted,
                ),
              ),
              const SizedBox(width: 16),
              // Botão (Variante contorno para perfeita integração com a aba e sem admin roxo ou acao preto)
              DsBotao(
                label: 'Começar',
                variante: DsBotaoVariante.contorno,
                icon: PhosphorIconsRegular.caretRight,
                fullWidth: false,
                onPressed: () => _showPrintModeIntroSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
