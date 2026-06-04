import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintActionsBottomSheet**
///
/// Diálogo modal Bottom Sheet premium no estilo Night Blue / Dark Glass.
/// Permite ao usuário escolher entre Visualizar/Imprimir e Compartilhar o PDF gerado.
class PrintActionsBottomSheet extends StatelessWidget {
  final VoidCallback onPreview;
  final VoidCallback onShare;

  const PrintActionsBottomSheet({
    super.key,
    required this.onPreview,
    required this.onShare,
  });

  /// Método estático facilitador para exibir o bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onPreview,
    required VoidCallback onShare,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrintActionsBottomSheet(
          onPreview: () {
            Navigator.pop(context);
            onPreview();
          },
          onShare: () {
            Navigator.pop(context);
            onShare();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usando SafeArea para garantir visualização correta em telas com notch/gestos do Android moderno
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: DsCores.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DsRaios.modal),
            topRight: Radius.circular(DsRaios.modal),
          ),
          border: Border(
            top: BorderSide(
              color: DsCores.border,
              width: 1.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DsEspacamentos.lg,
          vertical: DsEspacamentos.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle visual deslizante superior
            Center(
              child: Container(
                width: 48,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: DsEspacamentos.md),
                decoration: BoxDecoration(
                  color: DsCores.borderStrong.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DsRaios.pill),
                ),
              ),
            ),
            const SizedBox(height: DsEspacamentos.xs),

            // Título
            Text(
              'PDF da carteirinha pronto',
              style: DsTipografia.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DsEspacamentos.sm),

            // Subtítulo
            Text(
              'Escolha como deseja usar o documento.',
              style: DsTipografia.cardDescription,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DsEspacamentos.lg),

            // Ação 1: Visualizar e imprimir
            DsBotao(
              label: 'Visualizar e imprimir',
              variante: DsBotaoVariante.acao,
              token: DsCores.carteirinha,
              icon: PhosphorIconsRegular.printer,
              onPressed: onPreview,
            ),
            const SizedBox(height: DsEspacamentos.md),

            // Ação 2: Compartilhar PDF
            DsBotao(
              label: 'Compartilhar PDF',
              variante: DsBotaoVariante.acao,
              token: DsCores.comunicacao,
              icon: PhosphorIconsRegular.shareNetwork,
              onPressed: onShare,
            ),
            const SizedBox(height: DsEspacamentos.lg),

            // Nota de Responsabilidade / LGPD
            Container(
              padding: const EdgeInsets.all(DsEspacamentos.md),
              decoration: BoxDecoration(
                color: DsCores.surfaceElevated.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(DsRaios.sm),
                border: Border.all(
                  color: DsCores.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Este PDF pode conter informações pessoais. Ao compartilhar ou imprimir, a responsabilidade pelo uso é do usuário titular, da família ou do responsável.',
                style: DsTipografia.caption.copyWith(
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: DsEspacamentos.lg),

            // Botão Fechar
            DsBotao(
              label: 'Fechar',
              variante: DsBotaoVariante.ghost,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: DsEspacamentos.xs),
          ],
        ),
      ),
    );
  }
}
