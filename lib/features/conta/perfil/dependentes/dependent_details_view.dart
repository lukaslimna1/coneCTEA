import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';

import 'package:conectea/features/conta/perfil/dependentes/dependent_correction_view.dart';
import 'package:conectea/features/conta/perfil/dependentes/dependent_cpf_change_flow.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:conectea/models/member.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:conectea/services/database_service.dart';


/// Tela visual de Dados do Dependente dentro de Meus Dados.
///
/// Exibe dados reais recebidos pelo Member.
class DependentDetailsView extends StatefulWidget {
  final Member member;

  const DependentDetailsView({super.key, required this.member});

  @override
  State<DependentDetailsView> createState() => _DependentDetailsViewState();
}

class _DependentDetailsViewState extends State<DependentDetailsView> {
  bool _isOwnerCpfLoading = true;
  bool _ownerCpfLoadFailed = false;
  String? _ownerCpf;

  @override
  void initState() {
    super.initState();
    _loadOwnerCpf();
  }

  Future<void> _loadOwnerCpf() async {
    setState(() {
      _isOwnerCpfLoading = true;
      _ownerCpfLoadFailed = false;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await DatabaseService().getUserProfile(userId);
        if (profile != null) {
          final clean = profile.cpf.replaceAll(RegExp(r'[^0-9]'), '');
          if (clean.length == 11) {
            _ownerCpf = profile.cpf;
          } else {
            _ownerCpfLoadFailed = true;
          }
        } else {
          _ownerCpfLoadFailed = true;
        }
      } else {
        _ownerCpfLoadFailed = true;
      }
    } catch (_) {
      _ownerCpfLoadFailed = true;
    } finally {
      if (mounted) {
        setState(() {
          _isOwnerCpfLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: DsLoadingOverlay(
        isLoading: _isOwnerCpfLoading,
        message: 'Conferindo dados da conta...',
        child: AppBackground(
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
                      'Dados do dependente',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confira os dados cadastrais vinculados a este dependente.',
                      style: DsTipografia.body.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Seção 1 — Beneficiário / Dados principais
                    _buildSectionTitle(
                      'Beneficiário',
                      PhosphorIconsRegular.identificationCard,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow(
                        'Nome social',
                        _val(widget.member.socialName),
                      ),
                      _buildDataRow('Nome completo', _val(widget.member.name)),
                      CampoCpfProtegido(
                        valorVisivel: _formatCpf(widget.member.cpf),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      _buildDataRow(
                        'Data de nascimento',
                        _formatDateString(widget.member.dateOfBirth),
                      ),
                      _buildDataRow(
                        'Telefone',
                        _val(widget.member.phone),
                        isLast: true,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // Seção 2 — Localização
                    _buildSectionTitle(
                      'Localização',
                      PhosphorIconsRegular.mapPin,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow('Estado', _val(widget.member.state)),
                      _buildDataRow(
                        'Cidade',
                        _val(widget.member.city),
                        isLast: true,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // Seção 3 — Responsável
                    _buildSectionTitle(
                      'Responsável',
                      PhosphorIconsRegular.users,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow(
                        'Nome do responsável',
                        _val(widget.member.responsiblePersonName),
                      ),
                      _buildDataRow(
                        'Telefone do responsável',
                        _val(widget.member.responsiblePhone),
                        isLast: true,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // Seção 4 — Contato de emergência
                    _buildSectionTitle(
                      'Contato de emergência',
                      PhosphorIconsRegular.firstAid,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow(
                        'Nome do contato',
                        _val(widget.member.emergencyPersonName),
                      ),
                      _buildDataRow(
                        'Telefone do contato',
                        _val(widget.member.emergencyPhone),
                        isLast: true,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // Seção 5 — Dados complementares
                    _buildSectionTitle(
                      'Dados complementares',
                      PhosphorIconsRegular.listPlus,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow('Gênero', _val(widget.member.gender)),
                      _buildDataRow('Raça / Cor', _val(widget.member.racaCor)),
                      _buildDataRow(
                        'Tipo sanguíneo',
                        _val(widget.member.bloodType),
                      ),
                      CampoCidProtegido(valorVisivel: _val(widget.member.cid)),
                    ]),

                    const SizedBox(height: 40),

                    // Seção de ações: Alterações da carteirinha
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alterações da carteirinha',
                          style: DsTipografia.sectionTitle.copyWith(
                            color: DsCores.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Escolha o tipo de alteração que deseja fazer para este dependente.',
                          style: DsTipografia.bodySmall.copyWith(
                            color: DsCores.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Card 1: Alterar dados comuns
                        DsCard(
                          accentColor: DsCores.correcao.accent,
                          borderColor: DsCores.correcao.border,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DsMolduraIcone(
                                    icon: PhosphorIconsRegular.pencilSimpleLine,
                                    accentColor: DsCores.correcao.accent,
                                    size: 32,
                                    iconSize: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Alterar dados comuns',
                                      style: DsTipografia.cardTitle.copyWith(
                                        color: DsCores.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Atualize informações como nome, telefone, localização, responsáveis, contato de emergência e dados complementares.',
                                style: DsTipografia.body.copyWith(
                                  color: DsCores.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              DsBotao(
                                label: 'Alterar dados',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DependentCorrectionView(
                                        member: widget.member,
                                      ),
                                    ),
                                  );
                                },
                                variante: DsBotaoVariante.acao,
                                token: DsCores.correcao,
                                icon: PhosphorIconsRegular.paperPlaneRight,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Card 2: Alterar CPF da carteirinha
                        DsCard(
                          accentColor: DsCores.dadosProtegidos.accent,
                          borderColor: DsCores.dadosProtegidos.border,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DsMolduraIcone(
                                    icon: PhosphorIconsRegular.shieldCheck,
                                    accentColor: DsCores.dadosProtegidos.accent,
                                    size: 32,
                                    iconSize: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Alterar CPF da carteirinha',
                                      style: DsTipografia.cardTitle.copyWith(
                                        color: DsCores.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'O CPF é um dado protegido. Essa alteração terá um fluxo próprio com análise da equipe e envio de documento.',
                                style: DsTipografia.body.copyWith(
                                  color: DsCores.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              DsBotao(
                                label: 'Solicitar alteração',
                                onPressed: _isOwnerCpfLoading
                                    ? null
                                    : () {
                                        if (_ownerCpfLoadFailed ||
                                            _ownerCpf == null) {
                                          DsDialog.show<void>(
                                            context: context,
                                            title: 'Não foi possível conferir',
                                            description:
                                                'Não foi possível conferir os dados da conta agora. Tente novamente em instantes.',
                                            icon: PhosphorIconsRegular.warningCircle,
                                            token: DsCores.alerta,
                                            primaryAction: const DsDialogAction(
                                              label: 'Entendido',
                                              value: null,
                                              variante: DsBotaoVariante.acao,
                                              token: DsCores.sucesso,
                                            ),
                                          );
                                          return;
                                        }

                                        final cleanDep = widget.member.cpf
                                            .replaceAll(RegExp(r'[^0-9]'), '');
                                        final cleanOwner = _ownerCpf!
                                            .replaceAll(RegExp(r'[^0-9]'), '');
                                        if (cleanDep == cleanOwner) {
                                          DsDialog.show<void>(
                                            context: context,
                                            title: 'Use o fluxo da conta',
                                            description:
                                                'CPF vinculado à conta. Altere pelo fluxo de CPF da conta.',
                                            icon: PhosphorIconsRegular.warningCircle,
                                            token: DsCores.alerta,
                                            primaryAction: const DsDialogAction(
                                              label: 'Entendido',
                                              value: null,
                                              variante: DsBotaoVariante.acao,
                                              token: DsCores.sucesso,
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DependentCpfChangeFlow(
                                                member: widget.member,
                                                ownerCpf: _ownerCpf!,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                variante: DsBotaoVariante.acao,
                                token: DsCores.dadosProtegidos,
                                icon: PhosphorIconsRegular.lockKey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Título de seção com moldura de ícone.
  /// [color] padrão é DsCores.dependente; use DsCores.dadosProtegidos para seções sensíveis.
  Widget _buildSectionTitle(
    String title,
    IconData icon, {
    DsCorVisual color = DsCores.dependente,
  }) {
    return Row(
      children: [
        DsMolduraIcone(
          icon: icon,
          accentColor: color.accent,
          size: 32,
          iconSize: 18,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: DsTipografia.sectionTitle.copyWith(color: DsCores.textPrimary),
        ),
      ],
    );
  }

  /// Card de dados somente leitura, padrão Night Blue / Dark Glass.
  Widget _buildReadOnlyCard(List<Widget> children) {
    return DsCard(
      accentColor: DsCores.dependente.accent,
      borderColor: DsCores.dependente.border,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(children: children),
      ),
    );
  }

  /// Linha de dado rotulado.
  Widget _buildDataRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: DsTipografia.bodySmall.copyWith(
                  color: DsCores.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DsTipografia.body.copyWith(
              color: DsCores.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          ],
        ],
      ),
    );
  }

  String _val(String? val) {
    if (val == null || val.trim().isEmpty) return 'Não informado';
    return val;
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Não informado';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatCpf(String? cpf) {
    if (cpf == null || cpf.trim().isEmpty) return 'Não informado';
    final numeric = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.length != 11) return cpf;
    return '${numeric.substring(0, 3)}.${numeric.substring(3, 6)}.${numeric.substring(6, 9)}-${numeric.substring(9)}';
  }
}
