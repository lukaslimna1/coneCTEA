import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/services/device_auth_service.dart';

/// Guard visual de segurança que protege o acesso a widgets/telas específicas.
/// 
/// Intercepta a renderização caso o recurso de desbloqueio do aparelho esteja ativado
/// nas configurações locais do usuário, exibindo uma tela intermediária "Dark Glass"
/// e solicitando a biometria ou senha do dispositivo.
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
        });
      }
      return;
    }

    final isEnabled = await _deviceAuthService.isDeviceUnlockEnabled();
    final isSupported = await _deviceAuthService.isDeviceSupported();

    // Se o desbloqueio local não estiver ativo ou o dispositivo não suportar autenticação local, ignora o guard
    if (!isEnabled || !isSupported) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _needsAuth = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _needsAuth = true;
      });
    }

    // Aciona o diálogo de autenticação automaticamente ao carregar a tela pela primeira vez
    _authenticate();
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

    // Se o desbloqueio não estiver ativado ou o usuário já autenticou localmente, renderiza o child
    if (!_needsAuth || _isAuthenticated) {
      return widget.child;
    }

    // Exibe tela Dark Glass premium de bloqueio intermediário
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
