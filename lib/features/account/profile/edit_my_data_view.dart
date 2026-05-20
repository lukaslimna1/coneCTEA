import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EditMyDataView extends StatelessWidget {
  const EditMyDataView({super.key});

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
                      'Editar meus dados',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atualize as informações permitidas do seu cadastro.',
                      style: DsTipografia.body.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DsCores.seguranca.softBackground,
                        borderRadius: BorderRadius.circular(DsRaios.md),
                        border: Border.all(color: DsCores.seguranca.border),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.shieldCheck, color: DsCores.seguranca.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'CPF e e-mail são protegidos e precisam de solicitação para correção.',
                              style: DsTipografia.infoBody.copyWith(color: DsCores.seguranca.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Dados pessoais', PhosphorIconsRegular.identificationCard),
                    const SizedBox(height: 16),
                    _buildDsInput(label: 'Nome completo', initialValue: 'Nome cadastrado', icon: PhosphorIconsRegular.user),
                    const SizedBox(height: 12),
                    _buildDsInput(label: 'Nome social (opcional)', initialValue: '', icon: PhosphorIconsRegular.userCircle),
                    const SizedBox(height: 12),
                    _buildDsInput(label: 'Data de nascimento', initialValue: '00/00/0000', icon: PhosphorIconsRegular.calendarBlank),
                    const SizedBox(height: 12),
                    _buildDsInput(label: 'Telefone', initialValue: '(00) 00000-0000', icon: PhosphorIconsRegular.phone),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Localização', PhosphorIconsRegular.mapPin),
                    const SizedBox(height: 16),
                    _buildDsDropdown(label: 'Estado', value: 'SP', icon: PhosphorIconsRegular.mapTrifold, items: ['SP']),
                    const SizedBox(height: 12),
                    _buildDsDropdown(label: 'Cidade', value: 'Bauru', icon: PhosphorIconsRegular.buildings, items: ['Bauru']),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Dados complementares', PhosphorIconsRegular.listPlus),
                    const SizedBox(height: 16),
                    _buildDsDropdown(label: 'Gênero', value: 'Prefiro não informar', icon: PhosphorIconsRegular.genderIntersex, items: ['Feminino', 'Masculino', 'Não binário', 'Outro', 'Prefiro não informar']),
                    const SizedBox(height: 12),
                    _buildDsDropdown(label: 'Raça / Cor', value: 'Prefiro não informar', icon: PhosphorIconsRegular.users, items: ['Branca', 'Preta', 'Parda', 'Amarela', 'Indígena', 'Prefiro não informar']),
                    const SizedBox(height: 12),
                    _buildDsDropdown(label: 'Indicado por instituição?', value: 'Não', icon: PhosphorIconsRegular.bank, items: ['Não', 'Sim']),

                    const SizedBox(height: 32),

                    _buildSectionTitle('Dados protegidos', PhosphorIconsRegular.shieldCheck, color: DsCores.seguranca),
                    const SizedBox(height: 8),
                    Text(
                      'Para proteger sua conta, esses dados não são alterados diretamente por aqui.',
                      style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _buildProtectedField('CPF', '***.***.***-**'),
                    const SizedBox(height: 12),
                    _buildProtectedField('E-mail', 'l***@email.com'),
                    const SizedBox(height: 12),
                    DsBotao(
                      label: 'Solicitar correção',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fluxo visual em construção.')),
                        );
                      },
                      variante: DsBotaoVariante.acao,
                      token: DsCores.alerta,
                      icon: PhosphorIconsRegular.paperPlaneRight,
                    ),

                    const SizedBox(height: 48),

                    DsBotao(
                      label: 'Salvar alterações',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tela visual em construção. Nenhum dado foi salvo.')),
                        );
                      },
                      variante: DsBotaoVariante.acao,
                      token: DsCores.conta,
                    ),
                    const SizedBox(height: 12),
                    DsBotao(
                      label: 'Cancelar',
                      onPressed: () => Navigator.pop(context),
                      variante: DsBotaoVariante.ghost,
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

  Widget _buildDsInput({required String label, required String initialValue, required IconData icon}) {
    return DsInput(
      label: label,
      controller: TextEditingController(text: initialValue),
      icon: icon,
    );
  }

  Widget _buildDsDropdown({required String label, required String value, required IconData icon, required List<String> items}) {
    return DsDropdown(
      label: label,
      value: value,
      items: items,
      icon: icon,
      onChanged: (val) {},
    );
  }

  Widget _buildProtectedField(String label, String value) {
    return DsInput(
      label: label,
      controller: TextEditingController(text: value),
      icon: PhosphorIconsRegular.lock,
      readOnly: true,
      enabled: false,
    );
  }
}
