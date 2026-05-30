import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

class RequestUnsavedChangesDialog extends StatelessWidget {
  const RequestUnsavedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DsCores.glassStrong,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DsRaios.modal),
        side: BorderSide(
          color: DsCores.border.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      title: Text(
        'Descartar alterações?',
        style: DsTipografia.pageTitle.copyWith(fontSize: 22, letterSpacing: 0),
      ),
      content: Text(
        'Você possui alterações não salvas. Se sair agora, todos os dados modificados e novos documentos enviados nesta sessão serão perdidos definitivamente.',
        style: DsTipografia.infoBody,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsBotao(
              label: 'Sair sem Salvar',
              variante: DsBotaoVariante.perigo,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 12),
            DsBotao(
              label: 'Continuar Editando',
              variante: DsBotaoVariante.secundario,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ],
    );
  }
}
