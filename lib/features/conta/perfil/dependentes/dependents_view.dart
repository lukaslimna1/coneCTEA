import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/conta/perfil/dependentes/dependent_details_view.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/services/database_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela visual de Dependentes dentro de Meus Dados.
///
/// Exibe os dependentes reais da conta via DatabaseService.
class DependentsView extends StatefulWidget {
  const DependentsView({super.key});

  @override
  State<DependentsView> createState() => _DependentsViewState();
}

class _DependentsViewState extends State<DependentsView> {
  late Future<List<Member>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _membersFuture = DatabaseService().getMembers(userId);
    } else {
      _membersFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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

                    // Lista mock visual — substituída por dados reais
                    FutureBuilder<List<Member>>(
                      future: _membersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: DsLoadingSpinner(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildEmptyState('Erro ao carregar dependentes.');
                        }

                        final members = snapshot.data ?? [];
                        if (members.isEmpty) {
                          return _buildEmptyState('Você ainda não tem dependentes vinculados.');
                        }

                        return Column(
                          children: members.map((member) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildDependentCard(
                                context,
                                member: member,
                              ),
                            );
                          }).toList(),
                        );
                      },
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

  /// Estado vazio
  Widget _buildEmptyState(String message) {
    return DsCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          style: DsTipografia.body.copyWith(color: DsCores.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Card visual de dependente com dados reais (mascarados).
  ///
  /// Sem dados sensíveis no card (CPF, e-mail, laudo, CID ou documentos).
  Widget _buildDependentCard(
    BuildContext context, {
    required Member member,
  }) {
    final nome = member.displayName;

    String vinculoLabel = 'Cadastro vinculado';
    if (member.teaRelationType == 'pessoa_tea') {
      vinculoLabel = 'Pessoa TEA';
    } else if (member.teaRelationType == 'rede_apoio_tea') {
      vinculoLabel = 'Rede de apoio TEA';
    }

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
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vinculoLabel,
                        style: DsTipografia.bodySmall.copyWith(
                          color: DsCores.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: DsSelo.fromCorVisual(
              label: vinculoLabel == 'Cadastro vinculado' ? 'Cadastro vinculado' : 'Vínculo: $vinculoLabel',
              token: DsCores.conta,
              compact: true,
              uppercase: false,
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
                      builder: (context) => DependentDetailsView(member: member),
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
                      DsFeedback.showSnackBar(
                        context: context,
                        mensagem:
                            'Esse fluxo será liberado em uma próxima etapa.',
                        tipo: DsFeedbackTipo.info,
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
