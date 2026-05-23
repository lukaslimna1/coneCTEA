import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/services/device_auth_service.dart';

/// Guard visual de segurança que protege o acesso a widgets/telas específicas.
/// 
/// Intercepta a renderização caso o recurso de desbloqueio do aparelho esteja ativado
/// nas configurações locais do usuário, exibindo uma tela intermediária "Dark Glass"
/// e solicitando a biometria ou senha do dispositivo.
///
/// Também atua de forma proativa oferecendo o convite pós-login para ativar o recurso,
/// caso o usuário preencha todos os requisitos de elegibilidade.
class DeviceAuthGuard extends StatefulWidget {
  final Widget child;

  const DeviceAuthGuard({super.key, required this.child});

  @override
  State<DeviceAuthGuard> createState() => _DeviceAuthGuardState();
}

class _DeviceAuthGuardState extends State<DeviceAuthGuard> {
  final DeviceAuthService _deviceAuthService = DeviceAuthService();
  bool _isLoading = true;
  bool _needsAuth = false;
  bool _needsOffer = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkPreference();
  }

  /// Verifica se o guard precisa ser ativado com base na preferência local do usuário.
  Future<void> _checkPreference() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _needsAuth = false;
          _needsOffer = false;
        });
      }
      return;
    }

    final isEnabled = await _deviceAuthService.isDeviceUnlockEnabled();
    final isSupported = await _deviceAuthService.isDeviceSupported();

    // Se o desbloqueio local estiver ativo e for suportado, ativa a tela de bloqueio
    if (isEnabled && isSupported) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _needsAuth = true;
          _needsOffer = false;
        });
      }
      _authenticate(); // Aciona o diálogo de autenticação automaticamente
      return;
    }

    // Se o desbloqueio local não estiver ativo, mas for elegível para o convite pós-login
    try {
      final prefs = await SharedPreferences.getInstance();
      final keepConnected = prefs.getBool('conectea_keep_connected') ?? true;
      final offerDismissed = prefs.getBool('conectea_device_unlock_offer_dismissed') ?? false;

      if (keepConnected && !offerDismissed && isSupported) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _needsAuth = false;
            _needsOffer = true;
          });
        }
        return;
      }
    } catch (_) {}

    // Caso contrário, libera a Home normalmente
    if (mounted) {
      setState(() {
        _isLoading = false;
        _needsAuth = false;
        _needsOffer = false;
      });
    }
  }

  /// Dispara a autenticação local do dispositivo.
  Future<void> _authenticate() async {
    if (kIsWeb) return;

    final success = await _deviceAuthService.authenticate();
    if (success) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    }
  }

  /// Executa a ativação e validação do desbloqueio nativo em caso de aceite do convite
  Future<void> _handleAcceptOffer() async {
    if (kIsWeb) return;

    final success = await _deviceAuthService.authenticate();
    if (success) {
      await _deviceAuthService.setDeviceUnlockEnabled(true);
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _needsOffer = false;
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
      }
    } else {
      // Se falhar a validação, garante que continue falso e mostra feedback amigável
      await _deviceAuthService.setDeviceUnlockEnabled(false);
      if (mounted) {
        setState(() {
          _needsOffer = false;
          _isAuthenticated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Você pode ativar depois em Segurança da Conta.',
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
    }
  }

  /// Trata a recusa do convite pós-login
  Future<void> _handleDeclineOffer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('conectea_device_unlock_offer_dismissed', true);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _needsOffer = false;
        _isAuthenticated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retorna fundo neutro e loader leve enquanto lê SharedPreferences no início
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: DsCores.nightGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DsCores.textSecondary),
            ),
          ),
        ),
      );
    }

    // Se o desbloqueio não for exigido e não houver necessidade de oferta, renderiza o child
    if ((!_needsAuth && !_needsOffer) || _isAuthenticated) {
      return widget.child;
    }

    if (_needsOffer) {
      // Exibe tela Dark Glass premium de convite antes de renderizar o child
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: DsCores.nightGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DsEspacamentos.edge),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(DsEspacamentos.lg),
                    decoration: BoxDecoration(
                      color: DsCores.glass,
                      borderRadius: BorderRadius.circular(DsRaios.card),
                      border: Border.all(
                        color: DsCores.border.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                      boxShadow: DsSombras.medium,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Moldura com ícone semântico de Segurança
                        Container(
                          padding: const EdgeInsets.all(DsEspacamentos.md),
                          decoration: BoxDecoration(
                            color: DsCores.seguranca.softBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DsCores.seguranca.border,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                            size: DsTamanhos.iconLg * 1.5,
                            color: DsCores.seguranca.accent,
                          ),
                        ),
                        const SizedBox(height: DsEspacamentos.lg),

                        // Rótulo/Título Principal
                        Text(
                          'Proteger acesso neste aparelho?',
                          style: DsTipografia.pageTitle.copyWith(
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DsEspacamentos.md),

                        // Descrição Acessível
                        Text(
                          'Use o desbloqueio do seu celular para abrir o ConeCTEA com mais segurança.',
                          style: DsTipografia.body.copyWith(
                            color: DsCores.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DsEspacamentos.sm),

                        // Auxiliar
                        Text(
                          'Pode ser digital, rosto, PIN, senha ou padrão, conforme o aparelho.',
                          style: DsTipografia.bodySmall.copyWith(
                            color: DsCores.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DsEspacamentos.xxl),

                        // Botões de Ação
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DsBotao(
                              label: 'Ativar agora',
                              onPressed: _handleAcceptOffer,
                              variante: DsBotaoVariante.primario,
                              token: DsCores.seguranca,
                              icon: PhosphorIcons.shieldCheck(),
                            ),
                            const SizedBox(height: DsEspacamentos.md),
                            DsBotao(
                              label: 'Agora não',
                              onPressed: _handleDeclineOffer,
                              variante: DsBotaoVariante.secundario,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Exibe tela Dark Glass premium de bloqueio intermediário (needsAuth)
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: DsCores.nightGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsEspacamentos.edge),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(DsEspacamentos.lg),
                  decoration: BoxDecoration(
                    color: DsCores.glass,
                    borderRadius: BorderRadius.circular(DsRaios.card),
                    border: Border.all(
                      color: DsCores.border.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                    boxShadow: DsSombras.medium,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Moldura com ícone semântico de Segurança
                      Container(
                        padding: const EdgeInsets.all(DsEspacamentos.md),
                        decoration: BoxDecoration(
                          color: DsCores.seguranca.softBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DsCores.seguranca.border,
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
                          size: DsTamanhos.iconLg * 1.5,
                          color: DsCores.seguranca.accent,
                        ),
                      ),
                      const SizedBox(height: DsEspacamentos.lg),

                      // Rótulo/Título Principal
                      Text(
                        'Desbloqueio do aparelho',
                        style: DsTipografia.pageTitle.copyWith(
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DsEspacamentos.sm),

                      // Descrição Acessível
                      Text(
                        'Confirme sua identidade para continuar.',
                        style: DsTipografia.bodySmall.copyWith(
                          color: DsCores.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DsEspacamentos.xxl),

                      // Botão de Interação Primário
                      DsBotao(
                        label: 'Tentar novamente',
                        onPressed: _authenticate,
                        variante: DsBotaoVariante.primario,
                        token: DsCores.seguranca,
                        icon: PhosphorIcons.fingerprint(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
