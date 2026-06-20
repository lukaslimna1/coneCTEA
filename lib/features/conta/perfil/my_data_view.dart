import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/conta/perfil/edit_my_data_view.dart';
import 'package:conectea/features/conta/perfil/dependentes/dependents_view.dart';
import 'package:conectea/core/campos_cadastrais/campos_cadastrais.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/features/conta/perfil/alteracoes_conta/account_changes_view.dart';

class MyDataView extends StatefulWidget {
  final ValueChanged<AppUser> onProfileUpdated;

  const MyDataView({super.key, required this.onProfileUpdated});

  @override
  State<MyDataView> createState() => _MyDataViewState();
}

class _MyDataViewState extends State<MyDataView> {
  Future<AppUser?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final userId = AuthService().currentUser?.id;
    if (userId != null) {
      _profileFuture = DatabaseService().getUserProfile(userId);
    } else {
      _profileFuture = Future.value(null);
    }
  }

  void _retryLoadProfile() {
    setState(() {
      _loadProfile();
    });
  }

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) return 'Não informado';
    return value.trim();
  }

  String _maskCpf(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.***.***-${clean.substring(9, 11)}';
    }
    return '***.***.***-**';
  }

  String _maskEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return '***@***.***';
    }
    final parts = trimmed.split('@');
    final local = parts[0];
    final domain = parts[1];

    if (local.length <= 1) {
      return '$local***@$domain';
    } else if (local.length == 2) {
      return '${local[0]}***${local[1]}@$domain';
    } else {
      return '${local[0]}***${local[local.length - 1]}@$domain';
    }
  }

  String _formatDateOfBirth(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'Não informado';

    // Se estiver no formato YYYY-MM-DD
    final regExp = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final match = regExp.firstMatch(dateStr.trim());
    if (match != null) {
      final year = match.group(1);
      final month = match.group(2);
      final day = match.group(3);
      return '$day/$month/$year';
    }

    return dateStr.trim();
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
                      'Meus Dados',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visualize seus dados, dependentes e solicitações de correção.',
                      style: DsTipografia.body.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FutureBuilder<AppUser?>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: DsCores.textSecondary,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildErrorState();
                        }

                        final user = snapshot.data;
                        if (user == null) {
                          return _buildNotFoundState();
                        }

                        return _buildSuccessState(user);
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

  Widget _buildErrorState() {
    return DsCard(
      padding: const EdgeInsets.all(24),
      borderColor: DsCores.alerta.border,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.warningCircle,
            color: DsCores.alerta.accent,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'Ops! Não conseguimos carregar seus dados',
            style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ocorreu um problema ao conectar com o servidor. Verifique sua conexão e tente novamente.',
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          DsBotao(
            label: 'Tentar novamente',
            onPressed: _retryLoadProfile,
            variante: DsBotaoVariante.acao,
            token: DsCores.alerta,
            icon: PhosphorIconsRegular.arrowClockwise,
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return DsCard(
      padding: const EdgeInsets.all(24),
      borderColor: DsCores.perigo.border,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsRegular.userFocus,
            color: DsCores.perigo.accent,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'Perfil não localizado',
            style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Seus dados cadastrais não foram encontrados no sistema. Entre em contato com o suporte da Família TEA Bauru para regularizar sua conta.',
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          DsBotao(
            label: 'Falar com o Suporte',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fluxo de suporte oficial em desenvolvimento.'),
                ),
              );
            },
            variante: DsBotaoVariante.acao,
            token: DsCores.suporte,
            icon: PhosphorIconsRegular.whatsappLogo,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Meus dados cadastrados',
          PhosphorIconsRegular.identificationCard,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyCard([
          _buildDataRow('Nome completo', _displayValue(user.name)),
          _buildDataRow('Nome social', _displayValue(user.socialName)),
          _buildDataRow(
            'Data de nascimento',
            _formatDateOfBirth(user.dateOfBirth),
          ),
          _buildDataRow('Telefone', _displayValue(user.phone)),
          _buildDataRow('Estado', _displayValue(user.state)),
          _buildDataRow('Cidade', _displayValue(user.city)),
          _buildDataRow('Gênero', _displayValue(user.gender)),
          _buildDataRow('Raça / Cor', _displayValue(user.race)),
          _buildDataRow(
            'Instituição / Origem',
            _displayValue(user.institution),
            isLast: true,
          ),
        ]),

        const SizedBox(height: 32),

        _buildSectionTitle(
          'Dados protegidos',
          PhosphorIconsRegular.shieldCheck,
          color: DsCores.dadosProtegidos,
        ),
        const SizedBox(height: 8),
        Text(
          'Alguns dados da conta têm regras diferentes de alteração. O CPF precisa de revisão da equipe. O e-mail pode ser alterado com código de segurança.',
          style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
        ),
        const SizedBox(height: 16),

        // Bloco do CPF (Fluxo Administrativo)
        _buildReadOnlyCard([
          CampoCpfProtegido(
            valorVisivel: _maskCpf(user.cpf),
            valorOculto: '***.***.***-**',
          ),
        ], borderColor: DsCores.dadosProtegidos.border),
        const SizedBox(height: 8),
        Text(
          'Use esta opção se o CPF estiver incorreto. A equipe fará a análise.',
          style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
        ),
        const SizedBox(height: 12),
        DsBotao(
          label: 'Solicitar revisão de CPF',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fluxo visual em construção.')),
            );
          },
          variante: DsBotaoVariante.acao,
          token: DsCores.correcao,
          icon: PhosphorIconsRegular.paperPlaneRight,
        ),

        const SizedBox(height: 24),

        // Bloco do E-mail (Fluxo Automático OTP)
        _buildReadOnlyCard([
          CampoEmailProtegido(
            valorVisivel: _maskEmail(user.email),
            valorOculto: '***@***.***',
          ),
        ], borderColor: DsCores.dadosProtegidos.border),
        const SizedBox(height: 8),
        Text(
          'Você receberá um código no novo e-mail para confirmar a alteração.',
          style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
        ),
        const SizedBox(height: 12),
        DsBotao(
          label: 'Alterar e-mail',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Fluxo de alteração de e-mail será aberto na próxima etapa.',
                ),
              ),
            );
          },
          variante: DsBotaoVariante.acao,
          token: DsCores.conta,
          icon: PhosphorIconsRegular.pencilSimple,
        ),

        const SizedBox(height: 32),

        DsCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountChangesView()),
            );
          },
          borderColor: DsCores.correcao.border,
          child: Row(
            children: [
              DsMolduraIcone(
                icon: PhosphorIconsRegular.clipboardText,
                accentColor: DsCores.correcao.accent,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minhas alterações de conta',
                      style: DsTipografia.cardTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acompanhe revisões de CPF e alterações de e-mail.',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: DsCores.textPrimary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        _buildSectionTitle('Ações', PhosphorIconsRegular.lightning),
        const SizedBox(height: 16),
        DsBotao(
          label: 'Editar meus dados',
          onPressed: () async {
            final updatedUser = await Navigator.of(context).push<AppUser>(
              MaterialPageRoute(
                builder: (context) => EditMyDataView(user: user),
              ),
            );
            if (updatedUser != null && mounted) {
              setState(() {
                _profileFuture = Future<AppUser?>.value(updatedUser);
              });
              widget.onProfileUpdated(updatedUser);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dados atualizados com sucesso.')),
              );
            }
          },
          variante: DsBotaoVariante.acao,
          token: DsCores.conta,
          icon: PhosphorIconsRegular.pencilSimple,
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
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon, {
    DsCorVisual color = DsCores.conta,
  }) {
    return Row(
      children: [
        DsMolduraIcone(icon: icon, accentColor: color.accent),
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
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    IconData? icon,
    bool isLast = false,
  }) {
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
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 14, color: DsCores.textSecondary),
              ],
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
                child: Icon(
                  PhosphorIconsRegular.user,
                  color: DsCores.dependente.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exemplo de dependente',
                      style: DsTipografia.cardTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque para ver os dados cadastrados.',
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                PhosphorIconsRegular.caretRight,
                color: DsCores.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
