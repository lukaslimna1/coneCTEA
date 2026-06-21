
import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/core/widgets/premium/app_background.dart';
import 'package:conectea/features/conta/perfil/email_change/email_change_form_section.dart';
import 'package:conectea/features/conta/perfil/email_change/email_change_otp_section.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/features/home/app_navigation_guard_controller.dart';
import 'package:conectea/services/auth_service.dart';

class EmailChangeFlow extends StatefulWidget {
  const EmailChangeFlow({super.key});

  @override
  State<EmailChangeFlow> createState() => _EmailChangeFlowState();
}

class _EmailChangeFlowState extends State<EmailChangeFlow> {
  int _currentStep = 1; // 1 = Form, 2 = OTP, 3 = Sucesso
  String _newEmail = '';
  String _currentPassword = '';
  String _emailMasked = '';
  int _cooldownSeconds = 60;
  int _validitySeconds = 15 * 60;
  bool _formHasChanges = false;
  bool _isResume = false;
  bool _destinationKnown = true;
  bool _isLoadingCycle = true;
  int _formNonce = 0;

  
  AppNavigationGuardController? _navigationGuardController;
  bool _isDiscardDialogOpen = false;
  bool _successCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkActiveCycle();
  }

  Future<void> _checkActiveCycle({String? typedEmail}) async {
    final result = await AuthService().getActiveEmailChangeCycle();
    if (!mounted) return;

    if (result['has_active_cycle'] == true) {
      final serverNowStr = result['server_now'];
      final expiresAtStr = result['otp_expires_at'];
      final resendAtStr = result['resend_available_at'];
      final masked = result['destination_email_masked'] as String?;
      
      int cooldownSeconds = 0;
      int validitySeconds = 0;
      bool destinationKnown = masked != null && masked.isNotEmpty;

      if (serverNowStr != null && expiresAtStr != null) {
        final serverNow = DateTime.tryParse(serverNowStr);
        final expiresAt = DateTime.tryParse(expiresAtStr);
        if (serverNow != null && expiresAt != null) {
          validitySeconds = expiresAt.difference(serverNow).inSeconds;
          if (validitySeconds < 0) validitySeconds = 0;
        }
      }

      if (serverNowStr != null && resendAtStr != null) {
        final serverNow = DateTime.tryParse(serverNowStr);
        final resendAt = DateTime.tryParse(resendAtStr);
        final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
        
        if (serverNow != null && resendAt != null) {
          if (expiresAt != null && (resendAt.isAtSameMomentAs(expiresAt) || resendAt.isAfter(expiresAt))) {
            cooldownSeconds = -1;
          } else {
            cooldownSeconds = resendAt.difference(serverNow).inSeconds;
            if (cooldownSeconds < 0) cooldownSeconds = 0;
          }
        } else {
          cooldownSeconds = -1;
        }
      } else if (resendAtStr == null || serverNowStr == null) {
        cooldownSeconds = -1;
      }

      final currentUserEmail = AuthService().currentUser?.email ?? '';
      final currentMasked = currentUserEmail.isNotEmpty 
          ? currentUserEmail.replaceRange(2, currentUserEmail.indexOf('@'), '***') 
          : '';

      setState(() {
        _newEmail = (typedEmail != null && typedEmail.isNotEmpty) ? typedEmail : (masked ?? '');
        _emailMasked = currentMasked;
        _currentPassword = '';
        _cooldownSeconds = cooldownSeconds;
        _validitySeconds = validitySeconds;
        _isResume = true;
        _destinationKnown = (typedEmail != null && typedEmail.isNotEmpty) ? true : destinationKnown;
        _currentStep = 2;
        _isLoadingCycle = false;
      });
    } else {
      setState(() {
        _isLoadingCycle = false;
      });
      if (result['reason'] == 'expired') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'O código anterior expirou. Você pode solicitar um novo código.',
                ),
                backgroundColor: DsCores.alerta.accent,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigationGuardController == null) {
      _navigationGuardController = AppNavigationGuardScope.of(context);
      _navigationGuardController!.registerGuard(_confirmDiscardGuard);
    }
  }

  @override
  void dispose() {
    if (_navigationGuardController != null) {
      _navigationGuardController!.unregisterGuard(_confirmDiscardGuard);
    }
    super.dispose();
  }

  Future<bool> _showDiscardConfirmDialog() async {
    final isStep2 = _currentStep == 2;
    
    final title = isStep2 
        ? 'Continuar mais tarde?'
        : 'Sair da alteração de e-mail?';
        
    final description = isStep2
        ? 'O código continua válido por 15 minutos. Você pode sair agora e voltar para concluir enquanto ele ainda estiver válido.'
        : 'As informações digitadas serão perdidas.';

    final result = await DsDialog.show<bool>(
      context: context,
      title: title,
      description: description,
      icon: PhosphorIconsRegular.warningCircle,
      token: DsCores.alerta,
      secondaryAction: DsDialogAction(
        label: isStep2 ? 'Depois' : 'Sair',
        value: true,
        variante: isStep2 ? DsBotaoVariante.acao : DsBotaoVariante.ghost,
        token: DsCores.alerta,
      ),
      primaryAction: DsDialogAction(
        label: 'Continuar',
        value: false,
        variante: DsBotaoVariante.acao,
        token: DsCores.sucesso,
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmDiscardGuard() async {
    if (_successCompleted) return true;
    if (_isDiscardDialogOpen) return false;
    
    if (_currentStep == 1 && !_formHasChanges) {
      return true; // allow normal exit if no changes
    }

    _isDiscardDialogOpen = true;
    final sair = await _showDiscardConfirmDialog();
    _isDiscardDialogOpen = false;

    return sair;
  }

  Future<void> _requestExit() async {
    final canExit = await _confirmDiscardGuard();
    if (canExit && mounted) {
      Navigator.pop(context);
    }
  }

  void _onCodeSent({
    required String newEmail,
    required String currentPassword,
    required String emailMasked,
    required int cooldownSeconds,
    bool isResume = false,
    bool destinationKnown = true,
  }) {
    final currentUserEmail = AuthService().currentUser?.email ?? '';
    final currentMasked = currentUserEmail.isNotEmpty 
        ? currentUserEmail.replaceRange(2, currentUserEmail.indexOf('@'), '***') 
        : '';

    setState(() {
      _newEmail = newEmail;
      _currentPassword = currentPassword;
      _emailMasked = currentMasked;
      _cooldownSeconds = cooldownSeconds;
      _validitySeconds = 15 * 60;
      _isResume = isResume;
      _destinationKnown = destinationKnown;
      _currentStep = 2;
    });
  }

  void _onCheckActiveCycleRequested(String? typedEmail) {
    setState(() {
      _isLoadingCycle = true;
    });
    _checkActiveCycle(typedEmail: typedEmail);
  }

  void _onFormChanged(bool hasChanges) {
    if (_formHasChanges != hasChanges) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _formHasChanges = hasChanges);
      });
    }
  }

  void _onSuccess() {
    setState(() {
      _currentStep = 3;
      _successCompleted = true;
    });
  }

  void _onBackToForm() {
    setState(() {
      _currentStep = 1;
      _newEmail = '';
      _currentPassword = '';
      _emailMasked = '';
      _cooldownSeconds = 60;
      _validitySeconds = 15 * 60;
      _isResume = false;
      _destinationKnown = true;
      _formHasChanges = false;
      _formNonce++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _successCompleted,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _requestExit();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: AppBackground(
          child: Column(
            children: [
              // Barra superior de navegacao
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    DsBotaoVoltar(
                      onPressed: () {
                        _requestExit();
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep != 3) ...[
                      Text(
                        'Alterar e-mail da conta',
                        style: DsTipografia.pageTitle.copyWith(
                          color: DsCores.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informe o novo e-mail e confirme com o código de segurança enviado para ele.',
                        style: DsTipografia.body.copyWith(
                          color: DsCores.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (_isLoadingCycle)
                       Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 64),
                          child: CircularProgressIndicator(color: DsCores.conta.accent),
                        ),
                      )
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentSection(),
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

  Widget _buildCurrentSection() {
    switch (_currentStep) {
      case 1:
        return EmailChangeFormSection(
          key: ValueKey('form_section_$_formNonce'),
          initialEmail: _newEmail,
          initialPassword: _currentPassword,
          onCodeSent: _onCodeSent,
          onFormChanged: _onFormChanged,
          onCheckActiveCycleRequested: _onCheckActiveCycleRequested,
        );
      case 2:
        return EmailChangeOtpSection(
          key: const ValueKey('otp_section'),
          newEmail: _newEmail,
          emailMasked: _emailMasked,
          cooldownSeconds: _cooldownSeconds,
          validitySeconds: _validitySeconds,
          isResume: _isResume,
          destinationKnown: _destinationKnown,
          onSuccess: _onSuccess,
          onBackToForm: _onBackToForm,
        );
      case 3:
        return _buildSuccessSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSuccessSection() {
    return Center(
      key: const ValueKey('success_section'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DsCores.sucesso.softBackground,
                shape: BoxShape.circle,
                border: Border.all(color: DsCores.sucesso.border, width: 2),
              ),
              child: Icon(
                PhosphorIconsRegular.checkCircle,
                size: 64,
                color: DsCores.sucesso.accent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'E-mail alterado',
              style: DsTipografia.pageTitle.copyWith(color: DsCores.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'A partir de agora, use o novo e-mail para acessar sua conta.',
                style: DsTipografia.body.copyWith(
                  color: DsCores.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            DsBotao(
              label: 'Concluir',
              onPressed: () async {
                // Ao alterar e-mail (credencial sensível), é mais seguro deslogar localmente.
                // A revogação global de todas as sessões em todos os dispositivos requer backend/admin e deve ser feita em microfrente futura.
                await AuthService().signOut();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              variante: DsBotaoVariante.acao,
              token: DsCores.sucesso,
              icon: PhosphorIconsRegular.arrowRight,
            ),
          ],
        ),
      ),
    );
  }
}
