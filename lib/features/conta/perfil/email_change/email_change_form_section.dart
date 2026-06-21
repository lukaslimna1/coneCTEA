import 'package:flutter/material.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmailChangeFormSection extends StatefulWidget {
  final String initialEmail;
  final String initialPassword;
  final void Function({
    required String newEmail,
    required String currentPassword,
    required String emailMasked,
    required int cooldownSeconds,
    bool isResume,
    bool destinationKnown,
  }) onCodeSent;
  
  final void Function(bool hasChanges)? onFormChanged;
  final VoidCallback? onCheckActiveCycleRequested;

  const EmailChangeFormSection({
    super.key,
    required this.initialEmail,
    required this.initialPassword,
    required this.onCodeSent,
    this.onFormChanged,
    this.onCheckActiveCycleRequested,
  });

  @override
  State<EmailChangeFormSection> createState() => _EmailChangeFormSectionState();
}

class _EmailChangeFormSectionState extends State<EmailChangeFormSection> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
    _passwordController.text = widget.initialPassword;
    _emailController.addListener(_notifyFormChanged);
    _passwordController.addListener(_notifyFormChanged);
  }

  void _notifyFormChanged() {
    final hasChanges = _emailController.text.isNotEmpty || _passwordController.text.isNotEmpty;
    widget.onFormChanged?.call(hasChanges);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
  }

  bool _validateFields() {
    _clearErrors();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;

    if (email.isEmpty) {
      setState(() {
        _emailError = 'O novo e-mail é obrigatório.';
      });
      hasError = true;
    } else {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        setState(() {
          _emailError = 'Informe um endereço de e-mail válido.';
        });
        hasError = true;
      }
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'A senha atual é obrigatória.';
      });
      hasError = true;
    }

    if (hasError) {
      // Focar no primeiro campo com erro e rolar ate ele
      if (_emailError != null) {
        _emailFocusNode.requestFocus();
        Scrollable.ensureVisible(_emailFocusNode.context!, duration: const Duration(milliseconds: 300));
      } else if (_passwordError != null) {
        _passwordFocusNode.requestFocus();
        Scrollable.ensureVisible(_passwordFocusNode.context!, duration: const Duration(milliseconds: 300));
      }
    }

    return !hasError;
  }

  Future<void> _handleSubmit() async {
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final result = await AuthService().startEmailChangeOtp(
        newEmail: email,
        currentPassword: password,
      );

      if (result.containsKey('error')) {
        final error = result['error'] as String;
        _handleApiError(error);
      } else if (result['status'] == 'otp_send_started' || result['status'] == 'success') {
        final emailMasked = result['email_masked'] as String? ?? email.replaceRange(2, email.indexOf('@'), '***');
        final cooldown = result['resend_available_in_seconds'] as int? ?? 60;

        widget.onCodeSent(
          newEmail: email,
          currentPassword: password,
          emailMasked: emailMasked,
          cooldownSeconds: cooldown,
        );
      } else {
        setState(() {
          _generalError = 'Não foi possível concluir agora. Tente novamente em alguns minutos.';
        });
      }
    } catch (_) {
      setState(() {
        _generalError = 'Não foi possível concluir agora. Tente novamente em alguns minutos.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleApiError(String errorCode) {
    switch (errorCode) {
      case 'invalid_credentials':
        setState(() {
          _passwordError = 'A senha atual informada está incorreta.';
        });
        _passwordFocusNode.requestFocus();
        break;
      case 'destination_invalid':
        setState(() {
          _emailError = 'O endereço de e-mail informado é inválido.';
        });
        _emailFocusNode.requestFocus();
        break;
      case 'destination_same_as_current':
        setState(() {
          _emailError = 'Esse já é o e-mail atual da sua conta.';
        });
        _emailFocusNode.requestFocus();
        break;
      case 'destination_conflict':
      case 'account_data_conflict':
      case 'email_unavailable':
        setState(() {
          _emailError = 'Este e-mail não pode ser usado. Informe outro e-mail.';
        });
        _emailFocusNode.requestFocus();
        break;
      case 'flow_already_exists':
        if (widget.onCheckActiveCycleRequested != null) {
          widget.onCheckActiveCycleRequested!();
        } else {
          widget.onCodeSent(
            newEmail: '',
            currentPassword: _passwordController.text,
            emailMasked: '',
            cooldownSeconds: 0,
            isResume: true,
            destinationKnown: false,
          );
        }
        break;
      case 'protocol_already_exists':
        setState(() {
          _generalError = 'Já existe uma alteração de e-mail registrada para sua conta.';
        });
        break;
      case 'attempt_in_progress':
        setState(() {
          _generalError = 'Aguarde alguns segundos e tente novamente.';
        });
        break;
      case 'try_again_later':
        setState(() {
          _generalError = 'Não foi possível enviar o código agora. Tente novamente em alguns minutos.';
        });
        break;
      case 'reauth_blocked':
        setState(() {
          _generalError = 'Muitas tentativas. Tente novamente mais tarde.';
        });
        break;
      case 'session_invalid':
      case 'unauthorized':
        setState(() {
          _generalError = 'Sua sessão expirou. Entre novamente para continuar.';
        });
        break;
      case 'invalid_request':
        setState(() {
          _generalError = 'Verifique os dados informados e tente novamente.';
        });
        break;
      case 'attempt_mismatch':
      case 'attempt_already_finalized':
      case 'attempt_expired':
        setState(() {
          _generalError = 'O processo expirou ou foi invalidado. Reinicie o fluxo.';
        });
        break;
      default:
        setState(() {
          _generalError = 'Não foi possível concluir agora. Tente novamente em alguns minutos.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(24),
      borderColor: DsCores.conta.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Novo e-mail',
            style: DsTipografia.cardTitle.copyWith(color: DsCores.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite o novo e-mail da conta e confirme sua senha atual para proteger essa alteração.',
            style: DsTipografia.bodySmall.copyWith(color: DsCores.textSecondary),
          ),
          const SizedBox(height: 24),
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
            label: 'Novo e-mail',
            controller: _emailController,
            focusNode: _emailFocusNode,
            hint: 'novoemail@exemplo.com',
            icon: PhosphorIconsRegular.envelopeSimple,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 20),
          DsInput(
            label: 'Senha atual',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hint: '••••••••',
            icon: PhosphorIconsRegular.lockSimple,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 32),
          DsBotao(
            label: 'Enviar código de segurança',
            onPressed: _isLoading ? () {} : _handleSubmit,
            variante: DsBotaoVariante.acao,
            token: DsCores.conta,
            icon: PhosphorIconsRegular.paperPlaneTilt,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
