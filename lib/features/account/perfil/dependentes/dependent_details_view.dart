import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/perfil/widgets/my_data_logged_header.dart';
import 'package:conectea/features/account/perfil/dependentes/dependent_correction_view.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual de Dados do Dependente dentro de Meus Dados.
///
/// Esta tela é apenas visual/mockada nesta fase.
/// Não busca dados no banco, não salva nada, não conecta com Supabase.
/// CPF e CID exibidos usando os widgets reutilizáveis CampoCpfProtegido e CampoCidProtegido.
/// Sem documentos, URL, fileId, base64, upload ou dado real.
class DependentDetailsView extends StatelessWidget {
  const DependentDetailsView({super.key});

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
                      _buildDataRow('Nome completo', 'Exemplo de dependente'),
                      const CampoCpfProtegido(),
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      _buildDataRow('Data de nascimento', 'Não informado'),
                      _buildDataRow('Telefone', 'Não informado', isLast: true),
                    ]),

                    const SizedBox(height: 32),

                    // Seção 2 — Localização
                    _buildSectionTitle(
                      'Localização',
                      PhosphorIconsRegular.mapPin,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow('Estado', 'Não informado'),
                      _buildDataRow('Cidade', 'Não informado', isLast: true),
                    ]),

                    const SizedBox(height: 32),

                    // Seção 3 — Responsável
                    _buildSectionTitle(
                      'Responsável',
                      PhosphorIconsRegular.users,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow('Nome do responsável', 'Não informado'),
                      _buildDataRow(
                        'Telefone do responsável',
                        'Não informado',
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
                      _buildDataRow('Nome do contato', 'Não informado'),
                      _buildDataRow(
                        'Telefone do contato',
                        'Não informado',
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
                      _buildDataRow('Gênero', 'Não informado'),
                      _buildDataRow('Raça / Cor', 'Não informado'),
                      _buildDataRow('Tipo sanguíneo', 'Não informado'),
                      const CampoCidProtegido(),
                    ]),

                    const SizedBox(height: 40),

                    // Ação — Solicitar correção: abre DependentCorrectionView.
                    // Coluna vertical para evitar overflow em 360dp.
                    DsBotao(
                      label: 'Solicitar correção',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DependentCorrectionView(),
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
            ),
          ],
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
}
