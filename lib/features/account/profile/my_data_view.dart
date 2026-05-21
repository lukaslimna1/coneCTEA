import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/edit_my_data_view.dart';
import 'package:conectea/features/account/profile/dependents_view.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MyDataView extends StatelessWidget {
  const MyDataView({super.key});

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
                    DsBotaoVoltar(
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Meus Dados',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visualize seus dados, dependentes e solicitações de correção.',
                      style: DsTipografia.body.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Meus dados cadastrados', PhosphorIconsRegular.identificationCard),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow('Nome completo', 'Nome cadastrado'),
                      _buildDataRow('Nome social', 'Não informado'),
                      _buildDataRow('Data de nascimento', '00/00/0000'),
                      _buildDataRow('Telefone', '(00) 00000-0000'),
                      _buildDataRow('Estado', 'SP'),
                      _buildDataRow('Cidade', 'Bauru'),
                      _buildDataRow('Gênero', 'Prefiro não informar'),
                      _buildDataRow('Raça / Cor', 'Prefiro não informar', isLast: true),
                    ]),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Dados protegidos', PhosphorIconsRegular.shieldCheck, color: DsCores.dadosProtegidos),
                    const SizedBox(height: 8),
                    Text(
                      'Esses dados ajudam a proteger sua conta e evitar alterações indevidas. Para corrigir, envie uma solicitação para análise da equipe.',
                      style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyCard([
                      _buildDataRow('CPF', '***.***.***-**', icon: PhosphorIconsRegular.lock),
                      _buildDataRow('E-mail', 'l***@email.com', icon: PhosphorIconsRegular.lock, isLast: true),
                    ], borderColor: DsCores.dadosProtegidos.border),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Ações', PhosphorIconsRegular.lightning),
                    const SizedBox(height: 16),
                    DsBotao(
                      label: 'Editar meus dados',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EditMyDataView()));
                      },
                      variante: DsBotaoVariante.acao,
                      token: DsCores.conta,
                      icon: PhosphorIconsRegular.pencilSimple,
                    ),
                    const SizedBox(height: 12),
                    DsBotao(
                      label: 'Solicitar correção de dados protegidos',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fluxo visual em construção.')),
                        );
                      },
                      variante: DsBotaoVariante.acao,
                      token: DsCores.correcao,
                      icon: PhosphorIconsRegular.paperPlaneRight,
                    ),

                    const SizedBox(height: 40),

                    _buildSectionTitle('Dependentes', PhosphorIconsRegular.users),
                    const SizedBox(height: 8),
                    Text(
                      'Os dependentes vinculados à sua conta aparecerão aqui.',
                      style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _buildDependentCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {DsCorVisual color = DsCores.conta}) {
    return Row(
      children: [
        DsMolduraIcone(
          icon: icon,
          accentColor: color.accent,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: DsTipografia.sectionTitle.copyWith(color: DsCores.textPrimary),
        ),
      ],
    );
  }

  Widget _buildReadOnlyCard(List<Widget> children, {Color? borderColor}) {
    return DsCard(
      padding: EdgeInsets.zero,
      borderColor: borderColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {IconData? icon, bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 14, color: DsCores.textSecondary),
              ]
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DsTipografia.body.copyWith(color: DsCores.textPrimary, fontWeight: FontWeight.w600),
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildDependentCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DependentsView()),
          );
        },
        borderRadius: BorderRadius.circular(DsRaios.lg),
        child: DsCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DsCores.dependente.softBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: DsCores.dependente.border),
                ),
                child: Icon(PhosphorIconsRegular.user, color: DsCores.dependente.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exemplo de dependente',
                      style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque para ver os dados cadastrados.',
                      style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(PhosphorIconsRegular.caretRight, color: DsCores.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
