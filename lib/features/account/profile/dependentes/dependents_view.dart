import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:conectea/features/account/profile/dependentes/dependent_details_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual de Dependentes dentro de Meus Dados.
///
/// Esta tela é apenas visual/mockada nesta fase.
/// Não busca dados no banco, não salva nada, não conecta com Supabase.
class DependentsView extends StatelessWidget {
  const DependentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          children: [
            const MyDataLoggedHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsBotaoVoltar(onPressed: () => Navigator.pop(context)),
                    const SizedBox(height: 24),
                    Text(
                      'Dependentes',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visualize e organize os dependentes vinculados à sua conta.',
                      style: DsTipografia.body.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bloco explicativo
                    _buildInfoCard(),
                    const SizedBox(height: 32),

                    // Lista mock visual — sem dados reais
                    _buildDependentCard(
                      context,
                      nome: 'Exemplo de dependente',
                      vinculo: 'Cadastro vinculado',
                    ),
                    const SizedBox(height: 12),
                    _buildDependentCard(
                      context,
                      nome: 'Exemplo de dependente',
                      vinculo: 'Cadastro vinculado',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bloco explicativo sobre o que são dependentes.
  Widget _buildInfoCard() {
    return DsCard(
      accentColor: DsCores.dependente.accent,
      borderColor: DsCores.dependente.border,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsMolduraIcone(
            icon: PhosphorIconsRegular.usersThree,
            accentColor: DsCores.dependente.accent,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O que são dependentes?',
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dependentes são pessoas vinculadas ao usuário. Eles aparecem aqui para facilitar a edição dos seus dados cadastrais.',
                  style: DsTipografia.bodySmall.copyWith(
                    color: DsCores.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card visual mockado de dependente.
  ///
  /// Sem dados sensíveis (CPF, e-mail, laudo, CID ou documentos).
  Widget _buildDependentCard(
    BuildContext context, {
    required String nome,
    required String vinculo,
  }) {
    return DsCard(
      accentColor: DsCores.dependente.accent,
      borderColor: DsCores.dependente.border,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do card
          Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.user,
                accentColor: DsCores.dependente.accent,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: DsTipografia.cardTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vinculo,
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badge de status visual neutro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: DsCores.dependente.softBackground,
              borderRadius: BorderRadius.circular(DsRaios.sm),
              border: Border.all(color: DsCores.dependente.border),
            ),
            child: Text(
              'Visual em construção',
              style: DsTipografia.caption.copyWith(
                color: DsCores.dependente.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Divisor
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 14),

          // Ações visuais — sem lógica real
          // Coluna vertical para evitar overflow em telas estreitas (360dp).
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DsBotao(
                label: 'Ver dados do dependente',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DependentDetailsView(),
                    ),
                  );
                },
                variante: DsBotaoVariante.acao,
                token: DsCores.dependente,
                icon: PhosphorIconsRegular.identificationCard,
              ),
              const SizedBox(height: 12),
              DsBotao(
                label: 'Remover dependente',
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (context) {
                      String texto = '';
                      return StatefulBuilder(
                        builder: (context, setState) {
                          final bool isConfirmEnabled = texto == 'REMOVER';
                          return AlertDialog(
                            backgroundColor: const Color(0xFF0B1D3A),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            title: Column(
                              children: [
                                DsMolduraIcone(
                                  icon: PhosphorIconsRegular.warning,
                                  accentColor: DsCores.perigo.accent,
                                  size: 56,
                                  iconSize: 28,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Remover dependente',
                                  style: DsTipografia.sectionTitle.copyWith(
                                    color: DsCores.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Ao remover este dependente, os dados vinculados a ele serão apagados do banco de dados operacional do ConeCTEA, incluindo informações cadastrais, solicitações e carteirinha comunitária vinculada, quando existirem. Essa ação pode ser irreversível.',
                                    style: DsTipografia.bodySmall.copyWith(
                                      color: DsCores.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  DsInput(
                                    label: 'Digite REMOVER para confirmar.',
                                    hint: 'REMOVER',
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    onChanged: (val) {
                                      setState(() {
                                        texto = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            actionsPadding: const EdgeInsets.fromLTRB(
                              24,
                              8,
                              24,
                              24,
                            ),
                            actions: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DsBotao(
                                    label: 'Confirmar remoção',
                                    onPressed: isConfirmEnabled
                                        ? () {
                                            Navigator.pop(context, true);
                                          }
                                        : null,
                                    variante: DsBotaoVariante.acao,
                                    token: DsCores.perigo,
                                    icon: PhosphorIconsRegular.trash,
                                  ),
                                  const SizedBox(height: 12),
                                  DsBotao(
                                    label: 'Cancelar',
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    variante: DsBotaoVariante.secundario,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ).then((confirmed) {
                    if (confirmed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Fluxo visual em construção.',
                            style: DsTipografia.body.copyWith(
                              color: DsCores.textPrimary,
                            ),
                          ),
                          backgroundColor: DsCores.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  });
                },
                variante: DsBotaoVariante.acao,
                token: DsCores.perigo,
                icon: PhosphorIconsRegular.trash,
              ),
              const SizedBox(height: 12),
              Text(
                'Essa ação será tratada com confirmação e segurança em uma etapa futura.',
                style: DsTipografia.caption.copyWith(color: DsCores.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
