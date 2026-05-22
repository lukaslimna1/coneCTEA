import 'package:flutter/material.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/profile/widgets/my_data_logged_header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Tela visual/mockada de Consentimentos com Switches operacionais.
///
/// Apresenta o design e a estrutura de chaves de ativar/desativar para consentimentos
/// essenciais (bloqueados e ativos por padrão) e opcionais (interativos localmente).
class ConsentsView extends StatefulWidget {
  const ConsentsView({super.key});

  @override
  State<ConsentsView> createState() => _ConsentsViewState();
}

class _ConsentsViewState extends State<ConsentsView> {
  // Estado local para chaves opcionais
  bool _programasBeneficios = true;
  bool _comunicacaoAvisos = true;
  bool _parceirosAcoes = false;

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
                      token: DsCores.privacidade,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Consentimentos',
                      style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie autorizações importantes relacionadas ao uso do app.',
                      style: DsTipografia.pageSubtitle.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // SEÇÃO 1 — Essenciais para uso do app
                    Text(
                      'ESSENCIAIS PARA USO DO APP',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.privacidade.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Algumas autorizações são necessárias para manter sua conta, acesso e recursos básicos do ConeCTEA.',
                      style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Card 1 — Conta e acesso
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.userCircle,
                      title: 'Conta e acesso',
                      description: 'Necessário para criar conta, fazer login e manter seu cadastro básico.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Sempre ativo',
                      statusColor: DsCores.sucesso,
                      onChanged: null,
                    ),
                    const SizedBox(height: 12),

                    // Card 2 — Carteirinha comunitária
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.identificationCard,
                      title: 'Carteirinha comunitária',
                      description: 'Necessário para solicitar, analisar e manter a carteirinha comunitária.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Obrigatório para carteirinha',
                      statusColor: DsCores.sucesso,
                      onChanged: null,
                    ),
                    const SizedBox(height: 12),

                    // Card 3 — Dados de dependentes
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.usersThree,
                      title: 'Dados de dependentes',
                      description: 'Necessário quando houver dependentes vinculados à sua conta.',
                      value: true,
                      isEssential: true,
                      statusLabel: 'Essencial quando aplicável',
                      statusColor: DsCores.privacidade,
                      onChanged: null,
                    ),
                    const SizedBox(height: 32),

                    // SEÇÃO 2 — Autorizações opcionais
                    Text(
                      'AUTORIZAÇÕES OPCIONAIS',
                      style: DsTipografia.caption.copyWith(
                        color: DsCores.privacidade.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Essas autorizações podem ser ajustadas. Ao desativar, alguns programas ou benefícios podem ficar indisponíveis.',
                      style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Programas e benefícios
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.gift,
                      title: 'Programas e benefícios',
                      description: 'Permite participar de programas, benefícios, descontos e ações que dependam de compartilhamento autorizado de dados.',
                      value: _programasBeneficios,
                      isEssential: false,
                      onChanged: (newValue) {
                        setState(() {
                          _programasBeneficios = newValue;
                        });
                        _showMockSnackBar(context, 'Configuração visual em construção.');
                      },
                    ),
                    const SizedBox(height: 12),

                    // Card 5 — Comunicação e avisos
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.chatCircleText,
                      title: 'Comunicação e avisos',
                      description: 'Permite receber avisos, orientações e informações importantes pelos canais disponíveis.',
                      value: _comunicacaoAvisos,
                      isEssential: false,
                      onChanged: (newValue) {
                        setState(() {
                          _comunicacaoAvisos = newValue;
                        });
                        _showMockSnackBar(context, 'Configuração visual em construção.');
                      },
                    ),
                    const SizedBox(height: 12),

                    // Card 6 — Parceiros e ações externas
                    _buildConsentSwitchCard(
                      context,
                      icon: PhosphorIconsRegular.handshake,
                      title: 'Parceiros e ações externas',
                      description: 'Permite o uso autorizado de dados em ações específicas com parceiros, quando aplicável.',
                      value: _parceirosAcoes,
                      isEssential: false,
                      onChanged: (newValue) {
                        setState(() {
                          _parceirosAcoes = newValue;
                        });
                        _showMockSnackBar(context, 'Configuração visual em construção.');
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

  /// Exibe um SnackBar mockado com mensagem de alteração visual.
  void _showMockSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
        ),
        backgroundColor: DsCores.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Construtor de card de consentimento com Switch.
  Widget _buildConsentSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required bool isEssential,
    String? statusLabel,
    DsCorVisual? statusColor,
    required ValueChanged<bool>? onChanged,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsMolduraIcone(
                icon: icon,
                accentColor: DsCores.privacidade.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
                    ),
                    if (statusLabel != null && statusColor != null) ...[
                      const SizedBox(height: 6),
                      // Selo/Badge de status visual discreto
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.softBackground,
                          borderRadius: BorderRadius.circular(DsRaios.sm),
                          border: Border.all(color: statusColor.border),
                        ),
                        child: Text(
                          statusLabel,
                          style: DsTipografia.caption.copyWith(
                            color: statusColor.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Switch visual premium customizado
              IgnorePointer(
                ignoring: isEssential,
                child: Switch(
                  value: value,
                  onChanged: onChanged ?? (_) {},
                  activeThumbColor: DsCores.privacidade.accent,
                  activeTrackColor: DsCores.privacidade.softBackground,
                  inactiveThumbColor: DsCores.textSecondary,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
          ),
        ],
      ),
    );
  }
}
