import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

/// **PrintReviewExtraContactsSection**
/// Widget stateless local da funcionalidade de revisão de impressão.
/// Renderiza a seção visual de listagem dinâmica e formulários dos contatos extras
/// (responsáveis adicionais ou contatos de emergência adicionais).
class PrintReviewExtraContactsSection extends StatelessWidget {
  final String title;
  final String supportText;
  final List<Map<String, TextEditingController>> contacts;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const PrintReviewExtraContactsSection({
    super.key,
    required this.title,
    required this.supportText,
    required this.contacts,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: Colors.white.withValues(alpha: 0.05),
          height: 24,
          thickness: 1,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DsTipografia.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DsCores.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supportText,
                    style: DsTipografia.caption.copyWith(
                      color: DsCores.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: DsCores.sucesso.accent,
                size: 22,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              tooltip: 'Adicionar outro',
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.03),
              height: 1,
              thickness: 1,
            ),
          ),
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Outro contato #${index + 1}',
                        style: DsTipografia.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DsCores.textSecondary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onRemove(index),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: DsCores.perigo.accent,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        tooltip: 'Remover',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DsInput(
                    label: 'Nome completo',
                    controller: contacts[index]['name'],
                    hint: 'Ex: Maria Silva (Mãe)',
                  ),
                  const SizedBox(height: 8),
                  DsInput(
                    label: 'Telefone',
                    controller: contacts[index]['phone'],
                    hint: 'Ex: (14) 99999-9999',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
