import 'dart:async';

import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/services/auth_service.dart';

class EmailChangeOtpSection extends StatefulWidget {
  final String newEmail;
  final String emailMasked;
  final int cooldownSeconds;
  final int validitySeconds;
  final bool isResume;
  final bool destinationKnown;
  final VoidCallback onSuccess;
  final VoidCallback onBackToForm;

  const EmailChangeOtpSection({
    super.key,
    required this.newEmail,
    required this.emailMasked,
    required this.cooldownSeconds,
    this.validitySeconds = 15 * 60,
    this.isResume = false,
    this.destinationKnown = true,
    required this.onSuccess,
    required this.onBackToForm,
  });

  @override
  State<EmailChangeOtpSection> createState() => _EmailChangeOtpSectionState();
}

class _EmailChangeOtpSectionState extends State<EmailChangeOtpSection> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  String? _otpError;
  String? _generalError;
  bool _isLoading = false;

  int _remainingSeconds = 0;
  int _validitySeconds = 15 * 60; // 15 minutos (placeholder visual)
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.cooldownSeconds;
    _validitySeconds = widget.validitySeconds;
    if (widget.isResume) {
      if (widget.destinationKnown) {
        _generalError = 'Já existe um código enviado para este e-mail. Digite o código recebido para continuar.';
      } else {
        _generalError = null;
      }
    }
    _startCooldownTimer();
    _otpFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
        if (_validitySeconds > 0) _validitySeconds--;
      });
      if (_remainingSeconds <= 0 && _validitySeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _clearErrors() {
    setState(() {
      _otpError = null;
      _generalError = null;
    });
  }

  bool _validateOtp() {
    _clearErrors();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() {
        _otpError = 'O código de segurança é obrigatório.';
      });
      _otpFocusNode.requestFocus();
      return false;
    }

    if (otp.length != 6 || !RegExp(r'^\d+$').hasMatch(otp)) {
      setState(() {
        _otpError = 'O código de segurança deve ter exatamente 6 dígitos numéricos.';
      });
      _otpFocusNode.requestFocus();
      return false;
    }

    return true;
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    if (!_validateOtp()) return;

    final resultAction = await _showDeParaModal();
    if (resultAction == 'cancel') {
      await _executeRealCancel();
      return;
    }
    if (resultAction != 'confirm') return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _clearErrors();
    });

    final otp = _otpController.text.trim();
    final result = await AuthService().confirmEmailChangeOtp(otp: otp);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result['status'] == 'success') {
      widget.onSuccess();
    } else {
      _handleApiError(result['error']?.toString() ?? '');
    }
  }

  void _handleApiError(String errorCode) {
    switch (errorCode) {
      case 'otp_invalid':
        setState(() {
          _otpError = 'Código inválido. Confira os 6 dígitos e tente novamente.';
        });
        _otpFocusNode.requestFocus();
        break;
      case 'otp_expired':
        setState(() {
          _generalError = 'O código expirou. Será necessário solicitar um novo código.';
        });
        break;
      case 'otp_attempts_exceeded':
        setState(() {
          _generalError = 'Você atingiu o limite de tentativas deste código.';
        });
        break;
      case 'flow_not_found':
        setState(() {
          _generalError = 'Não encontramos uma alteração de e-mail ativa.';
        });
        break;
      case 'session_invalid':
      case 'unauthorized':
        setState(() {
          _generalError = 'Sua sessão expirou. Entre novamente para continuar.';
        });
        break;
      case 'destination_conflict':
        setState(() {
          _generalError = 'Este e-mail já está em uso por outra conta.';
        });
        break;
      case 'try_again_later':
        setState(() {
          _generalError = 'Não foi possível confirmar agora. Tente novamente em alguns minutos.';
        });
        break;
      default:
        setState(() {
          _generalError = 'Não foi possível confirmar a alteração agora.';
        });
        break;
    }
  }

  Future<String?> _showDeParaModal() async {
    final isIdenticalMasked = widget.isResume && widget.emailMasked == widget.newEmail;
    
    final title = widget.destinationKnown && !isIdenticalMasked
        ? 'Confirmar alteração de e-mail' 
        : (isIdenticalMasked ? 'Alteração em andamento' : 'Confirmar código?');
        
    final description = widget.destinationKnown && !isIdenticalMasked
        ? 'Você está alterando o e-mail de ${widget.emailMasked} para ${widget.newEmail}. Depois disso, será necessário entrar novamente.'
        : (isIdenticalMasked 
            ? 'Você está confirmando uma alteração de e-mail em andamento.\n\nConfira se o código recebido corresponde à alteração que você solicitou.'
            : 'Este código será usado para concluir a alteração de e-mail que já estava em andamento. Como o destino real ainda não foi recuperado pelo app, confirme apenas se você reconhece esse código.');

    final confirmLabel = (widget.destinationKnown && !isIdenticalMasked) ? 'Confirmar' : 'Confirmar código';

    final confirmed = await DsDialog.show<String>(
      context: context,
      title: title,
      description: description,
      icon: PhosphorIconsRegular.swap,
      token: DsCores.seguranca,
      secondaryAction: const DsDialogAction(
        label: 'Cancelar',
        value: 'cancel',
        variante: DsBotaoVariante.perigo,
      ),
      primaryAction: DsDialogAction(
        label: confirmLabel,
        value: 'confirm',
        variante: DsBotaoVariante.acao,
        token: DsCores.sucesso,
      ),
    );

    return confirmed;
  }

  Future<void> _executeRealCancel() async {
    setState(() {
      _isLoading = true;
      _clearErrors();
    });

    final result = await AuthService().cancelEmailChange();

    if (!mounted) return;

    if (result['status'] == 'success') {
      widget.onBackToForm();
    } else {
      setState(() {
        _isLoading = false;
        _generalError = 'Não foi possível cancelar a alteração agora. Tente novamente.';
      });
    }
  }

  Future<void> _showCancelModal() async {
    final confirmed = await DsDialog.show<bool>(
      context: context,
      title: 'Cancelar alteração de e-mail?',
      description: 'O código enviado deixará de valer e você precisará começar de novo se quiser alterar o e-mail.',
      icon: PhosphorIconsRegular.warningCircle,
      token: DsCores.perigo,
      secondaryAction: const DsDialogAction(
        label: 'Continuar',
        value: false,
        variante: DsBotaoVariante.acao,
        token: DsCores.sucesso,
      ),
      primaryAction: const DsDialogAction(
        label: 'Cancelar',
        value: true,
        variante: DsBotaoVariante.perigo,
      ),
    );

    if (confirmed == true && mounted) {
      await _executeRealCancel();
    }
  }

  Future<void> _executeRealResend() async {
    setState(() {
      _isLoading = true;
      _clearErrors();
    });

    final result = await AuthService().resendEmailChangeOtp();

    if (!mounted) return;

    if (result['status'] == 'success') {
      final availableAtIso = result['resend_available_at'] as String?;
      int newCooldown = 60;
      if (availableAtIso != null) {
        final availableAt = DateTime.tryParse(availableAtIso)?.toLocal();
        if (availableAt != null) {
          newCooldown = availableAt.difference(DateTime.now()).inSeconds;
          if (newCooldown < 0) newCooldown = 0;
        }
      }

      final expiresAtIso = result['expires_at'] as String?;
      int newValidity = 15 * 60;
      if (expiresAtIso != null) {
        final expiresAt = DateTime.tryParse(expiresAtIso)?.toLocal();
        if (expiresAt != null) {
          newValidity = expiresAt.difference(DateTime.now()).inSeconds;
          if (newValidity < 0) newValidity = 0;
        }
      }

      setState(() {
        _isLoading = false;
        _remainingSeconds = newCooldown;
        _validitySeconds = newValidity;
        _generalError = 'Um novo código foi enviado. Verifique seu e-mail.';
      });
      _startCooldownTimer();
      // Update send_sequence logic can be placed here if used by the UI in the future
      return;
    }

    setState(() {
      _isLoading = false;
    });

    final error = result['error']?.toString();
    if (error == 'cooldown_active') {
      final availableAtIso = result['resend_available_at'] as String?;
      int newCooldown = 60;
      if (availableAtIso != null) {
        final availableAt = DateTime.tryParse(availableAtIso)?.toLocal();
        if (availableAt != null) {
          newCooldown = availableAt.difference(DateTime.now()).inSeconds;
          if (newCooldown < 0) newCooldown = 0;
        }
      }
      setState(() {
        _remainingSeconds = newCooldown;
        _generalError = 'Aguarde antes de solicitar um novo reenvio.';
      });
      _startCooldownTimer();
    } else if (error == 'max_resends_reached') {
      setState(() {
        _generalError = 'Limite de reenvios atingido. Aguarde ou comece a alteração novamente se necessário.';
        _remainingSeconds = -1; // disable resend button
      });
    } else if (error == 'no_active_cycle' || error == 'expired_cycle') {
      setState(() {
        _generalError = 'Não há uma alteração de e-mail ativa para reenviar o código.';
      });
    } else if (error == 'send_failed') {
      setState(() {
        _generalError = 'Ocorreu um erro ao enviar o e-mail. Tente novamente em alguns minutos.';
      });
    } else {
      setState(() {
        _generalError = 'Não foi possível reenviar o código agora. Tente novamente.';
      });
    }
  }

  Future<void> _showResendModal() async {
    if (_remainingSeconds > 0 || _isLoading) return;

    final confirmed = await DsDialog.show<bool>(
      context: context,
      title: 'Reenviar código?',
      description: 'Vamos enviar um novo código para o e-mail informado. O código anterior deixará de funcionar.',
      icon: PhosphorIconsRegular.paperPlaneRight,
      token: DsCores.seguranca,
      secondaryAction: const DsDialogAction(
        label: 'Voltar',
        value: false,
        variante: DsBotaoVariante.secundario,
      ),
      primaryAction: const DsDialogAction(
        label: 'Reenviar',
        value: true,
        variante: DsBotaoVariante.acao,
        token: DsCores.seguranca,
      ),
    );

    if (confirmed == true && mounted) {
      await _executeRealResend();
    }
  }


  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}min ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(24),
      borderColor: DsCores.sucesso.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmar código',
            style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
          ),
          const SizedBox(height: 8),
          if (widget.destinationKnown) ...[
            Text(
              'Digite o código de 6 dígitos enviado para:',
              style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: DsCores.conta.softBackground,
                borderRadius: BorderRadius.circular(DsRaios.sm),
                border: Border.all(color: DsCores.conta.border),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.envelopeSimple, color: DsCores.conta.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.newEmail,
                      style: DsTipografia.body.copyWith(
                        color: DsCores.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: DsCores.alerta.softBackground,
                borderRadius: BorderRadius.circular(DsRaios.md),
                border: Border.all(color: DsCores.alerta.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsRegular.info, color: DsCores.alerta.accent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Alteração de e-mail em andamento',
                          style: DsTipografia.bodySmall.copyWith(
                            color: DsCores.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Existe um código de segurança já enviado para uma alteração anterior. Como o app ainda não recebeu o destino real desse ciclo, confira o e-mail que recebeu o código antes de continuar.',
                    style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          if (_generalError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: DsCores.perigo.softBackground,
                borderRadius: BorderRadius.circular(DsRaios.md),
                border: Border.all(color: DsCores.perigo.border),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.warningCircle,
                    color: DsCores.perigo.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _generalError!,
                      style: DsTipografia.bodySmall.copyWith(
                        color: DsCores.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          DsInput(
            label: 'Código de segurança',
            controller: _otpController,
            focusNode: _otpFocusNode,
            hint: '000000',
            icon: PhosphorIconsRegular.key,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            errorText: _otpError,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(DsRaios.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.timer, color: DsCores.alerta.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !widget.destinationKnown
                            ? 'O código anterior pode expirar em até 15 minutos após o envio.'
                            : (_validitySeconds > 0
                                ? 'O código expira em ${_formatDuration(_validitySeconds)}'
                                : 'O código expirou.'),
                        style: DsTipografia.bodySmall.copyWith(color: DsCores.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                Text(
                  'Não recebeu o código?',
                  style: DsTipografia.bodySmall.copyWith(color: DsCores.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Espere alguns minutos antes de pedir um novo envio.',
                  style: DsTipografia.caption.copyWith(color: DsCores.textSecondary),
                ),
                const SizedBox(height: 16),
                DsBotao(
                  label: _remainingSeconds < 0
                      ? 'Reenvio indisponível'
                      : (_remainingSeconds > 0 ? 'Reenviar em ${_formatDuration(_remainingSeconds)}' : 'Reenviar código'),
                  onPressed: _remainingSeconds == 0 ? _showResendModal : null,
                  variante: DsBotaoVariante.secundario,
                  icon: PhosphorIconsRegular.paperPlaneRight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          DsBotao(
            label: 'Confirmar alteração',
            onPressed: _isLoading ? null : _handleSubmit,
            variante: DsBotaoVariante.acao,
            token: DsCores.sucesso,
            icon: PhosphorIconsRegular.check,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          DsBotao(
            label: 'Cancelar',
            onPressed: _isLoading ? null : _showCancelModal,
            variante: DsBotaoVariante.perigo,
          ),
        ],
      ),
    );
  }
}
