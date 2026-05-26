import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/features/account/perfil/widgets/my_data_logged_header.dart';
import 'package:conectea/core/services/device_auth_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SecurityView extends StatefulWidget {
  const SecurityView({super.key});

  @override
  State<SecurityView> createState() => _SecurityViewState();
}

class _SecurityViewState extends State<SecurityView> {
  final DeviceAuthService _deviceAuthService = DeviceAuthService();
  bool _isDeviceUnlockEnabled = false;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceUnlockPreference();
  }

  Future<void> _loadDeviceUnlockPreference() async {
    final enabled = await _deviceAuthService.isDeviceUnlockEnabled();
    if (mounted) {
      setState(() {
        _isDeviceUnlockEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDeviceUnlock(bool value) async {
    if (_isProcessing) return;

    if (value) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Valida que o aparelho suporta e que a autenticação local é bem-sucedida
        final authenticated = await _deviceAuthService.authenticate();
        if (authenticated) {
          final success = await _deviceAuthService.setDeviceUnlockEnabled(true);
          if (success && mounted) {
            setState(() {
              _isDeviceUnlockEnabled = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Desbloqueio do aparelho ativado com sucesso!',
                  style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
                ),
                backgroundColor: DsCores.seguranca.accent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else {
            throw Exception('Falha ao salvar preferência local.');
          }
        } else {
          throw Exception('Autenticação cancelada ou não suportada.');
        }
      } catch (_) {
        // Garante que o valor local seja mantido falso em caso de qualquer falha
        await _deviceAuthService.setDeviceUnlockEnabled(false);
        if (mounted) {
          setState(() {
            _isDeviceUnlockEnabled = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Não foi possível ativar o desbloqueio do aparelho.',
                style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
              ),
              backgroundColor: DsCores.perigo.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } else {
      // Ao desativar, não exige nova autenticação do usuário
      setState(() {
        _isProcessing = true;
      });
      try {
        final success = await _deviceAuthService.setDeviceUnlockEnabled(false);
        if (success && mounted) {
          setState(() {
            _isDeviceUnlockEnabled = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Desbloqueio do aparelho desativado.',
                style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
              ),
              backgroundColor: DsCores.surfaceElevated,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          throw Exception('Falha ao desativar preferência local.');
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Não foi possível desativar o desbloqueio do aparelho.',
                style: DsTipografia.body.copyWith(color: DsCores.textPrimary),
              ),
              backgroundColor: DsCores.perigo.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
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
                      token: DsCores.seguranca,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Segurança',
                      style: DsTipografia.pageTitle.copyWith(
                        color: DsCores.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie acessos, senha e proteção da sua conta.',
                      style: DsTipografia.pageSubtitle.copyWith(
                        color: DsCores.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card 1 — Segurança da conta
                    _buildSecurityCard(
                      context,
                      icon: PhosphorIconsRegular.shieldCheck,
                      title: 'Segurança da conta',
                      description:
                          'Confira recursos relacionados ao acesso e proteção da sua conta no ConeCTEA.',
                      color: DsCores.seguranca,
                    ),
                    const SizedBox(height: 16),

                    // Card local — Desbloqueio do aparelho
                    if (!_isLoading) ...[
                      _buildDeviceUnlockCard(context),
                      const SizedBox(height: 16),
                    ],

                    // Card 2 — Alterar senha
                    _buildSecurityCard(
                      context,
                      icon: PhosphorIconsRegular.key,
                      title: 'Alterar senha',
                      description:
                          'Atualize sua senha de acesso quando necessário.',
                      actionLabel: 'Alterar senha',
                      actionIcon: PhosphorIconsRegular.lockSimple,
                      color: DsCores.seguranca,
                    ),
                    const SizedBox(height: 16),

                    // Card 3 — E-mail da conta
                    _buildSecurityCard(
                      context,
                      icon: PhosphorIconsRegular.envelope,
                      title: 'E-mail da conta',
                      description:
                          'O e-mail é usado para acesso e comunicação da conta.',
                      actionLabel: 'Solicitar alteração de e-mail',
                      actionIcon: PhosphorIconsRegular.paperPlaneRight,
                      color: DsCores.correcao,
                    ),
                    const SizedBox(height: 16),

                    // Card 4 — Acessos e sessões
                    _buildSecurityCard(
                      context,
                      icon: PhosphorIconsRegular.deviceMobile,
                      title: 'Acessos e sessões',
                      description:
                          'Gerenciamento de dispositivos e sessões será tratado em uma etapa futura.',
                      actionLabel: 'Ver acessos',
                      actionIcon: PhosphorIconsRegular.eye,
                      color: DsCores.seguranca,
                    ),
                    const SizedBox(height: 16),

                    // Card 5 — Conta e encerramento
                    _buildSecurityCard(
                      context,
                      icon: PhosphorIconsRegular.warning,
                      title: 'Conta e encerramento',
                      description:
                          'A exclusão da conta é uma ação sensível e deve ser feita com cuidado.',
                      actionLabel: 'Excluir conta',
                      actionIcon: PhosphorIconsRegular.trash,
                      color: DsCores.perigo,
                      onPressed: () {
                        showDialog<bool>(
                          context: context,
                          builder: (context) {
                            String texto = '';
                            return StatefulBuilder(
                              builder: (context, setState) {
                                final bool isConfirmEnabled =
                                    texto == 'EXCLUIR CONTA';
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF0B1D3A),
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
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
                                        'Excluir conta',
                                        style: DsTipografia.sectionTitle
                                            .copyWith(
                                              color: DsCores.textPrimary,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Ao excluir sua conta, você perde o acesso ao ConeCTEA e seus dados serão apagados do banco de dados operacional, incluindo dependentes, solicitações e carteirinhas comunitárias vinculadas, quando existirem.\n\nEssa ação não poderá ser desfeita. Registros técnicos mínimos ou mensagens já enviadas por canais externos podem não ser removidos por este processo.',
                                          style: DsTipografia.bodySmall
                                              .copyWith(
                                                color: DsCores.textSecondary,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        DsInput(
                                          label:
                                              'Digite EXCLUIR CONTA para confirmar.',
                                          hint: 'EXCLUIR CONTA',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        DsBotao(
                                          label: 'Confirmar exclusão',
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

  Widget _buildDeviceUnlockCard(BuildContext context) {
    final bool isWeb = kIsWeb;
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsMolduraIcone(
            icon: PhosphorIconsRegular.deviceMobile,
            accentColor: DsCores.seguranca.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DsSwitch(
              value: isWeb ? false : _isDeviceUnlockEnabled,
              onChanged: (isWeb || _isProcessing)
                  ? null
                  : (value) => _toggleDeviceUnlock(value),
              label: 'Desbloqueio do aparelho',
              description: isWeb
                  ? 'Indisponível no navegador. Use em um aparelho celular compatível.'
                  : 'Use a segurança do seu celular para proteger o acesso ao ConeCTEA.',
              token: DsCores.seguranca,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required DsCorVisual color,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onPressed,
  }) {
    return DsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsMolduraIcone(icon: icon, accentColor: color.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: DsTipografia.cardTitle.copyWith(
                    color: DsCores.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: DsTipografia.bodySmall.copyWith(
              color: DsCores.textSecondary,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            DsBotao(
              label: actionLabel,
              onPressed:
                  onPressed ??
                  () {
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
                  },
              variante: DsBotaoVariante.acao,
              token: color,
              icon: actionIcon,
            ),
          ],
        ],
      ),
    );
  }
}
