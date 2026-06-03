import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';


/// **PrintTypeDecisionSheet**
/// Diálogo modal bottom sheet que exibe o direcionamento do Modo Impressão
/// após a seleção da carteirinha de acordo com o vínculo (Rede de Apoio vs Pessoa TEA).
class PrintTypeDecisionSheet extends StatelessWidget {
  final Member member;

  const PrintTypeDecisionSheet({
    super.key,
    required this.member,
  });

  /// Método estático facilitador para exibir o bottom sheet.
  static Future<String?> show(
    BuildContext context, {
    required Member member,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrintTypeDecisionSheet(member: member);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSupport = member.isSupportNetwork;
    final screenHeight = MediaQuery.sizeOf(context).height;

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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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

                // Cabeçalho Condicional
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: DsCores.iconFrameBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        isSupport ? PhosphorIconsBold.users : PhosphorIconsBold.heart,
                        color: DsCores.carteirinha.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSupport ? 'Carteirinha para impressão' : 'Perfil de Apoio TEA',
                            style: DsTipografia.sectionTitle,
                          ),
                          const SizedBox(height: 6),
                          // Selo de Vínculo Genérico (Conforme regra: não usar DsSeloStatus)
                          DsSelo.fromCorVisual(
                            label: isSupport ? 'Rede de Apoio TEA' : 'Pessoa TEA',
                            token: isSupport ? DsCores.institucional : DsCores.carteirinha,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nome do Membro Selecionado
                Text(
                  'Carteirinha de ${member.displayName}',
                  style: DsTipografia.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Descrição Condicional
                Text(
                  isSupport
                      ? 'Esta carteirinha é de Rede de Apoio TEA. A versão para impressão será preparada com frente e verso da carteirinha comunitária.'
                      : 'Esta carteirinha é de Pessoa TEA. Além da carteirinha frente e verso, você pode incluir um Perfil de Apoio TEA com informações úteis para escola, cuidadores, familiares, eventos ou consultas.',
                  style: DsTipografia.infoBody,
                ),
                const SizedBox(height: 20),

                // Bloco Informativo de Apoio
                Container(
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
                      Icon(
                        isSupport ? PhosphorIconsRegular.info : PhosphorIconsRegular.shieldCheck,
                        color: isSupport ? DsCores.carteirinha.accent : DsCores.privacidade.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isSupport
                              ? 'Na próxima etapa, você poderá revisar quais informações opcionais deseja incluir.'
                              : 'As informações do Perfil de Apoio TEA ficam salvas apenas neste aparelho e não são enviadas para o banco de dados.',
                          style: DsTipografia.caption.copyWith(
                            color: DsCores.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botões de Ação Condicionais (Variante contorno para ser fiel à carteirinha e não admin)
                if (isSupport)
                  // Rede de Apoio: Cancela ou Continua
                  Row(
                    children: [
                      Expanded(
                        child: DsBotao(
                          label: 'Voltar',
                          variante: DsBotaoVariante.secundario,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DsBotao(
                          label: 'Continuar',
                          variante: DsBotaoVariante.acao,
                          token: DsCores.sucesso,
                          onPressed: () => Navigator.pop(context, 'only_card'),
                        ),
                      ),
                    ],
                  )
                else
                  // Pessoa TEA: Pergunta se inclui Perfil ou Apenas Carteirinha
                  Column(
                    children: [
                      DsBotao(
                        label: 'Incluir Perfil de Apoio',
                        variante: DsBotaoVariante.acao,
                        token: DsCores.carteirinha,
                        icon: PhosphorIconsRegular.heart,
                        onPressed: () => Navigator.pop(context, 'include_profile'),
                      ),
                      const SizedBox(height: 12),
                      DsBotao(
                        label: 'Só carteirinha',
                        variante: DsBotaoVariante.acao,
                        token: DsCores.carteirinha,
                        icon: PhosphorIconsRegular.identificationCard,
                        onPressed: () => Navigator.pop(context, 'only_card'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
