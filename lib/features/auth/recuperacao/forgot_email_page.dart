import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/premium_auth_background.dart';
import '../../../core/widgets/premium/premium_card.dart';
import '../../../core/widgets/premium/premium_button.dart';
import '../../../core/design_system_v2/design_system_v2.dart';
import '../../../services/database_service.dart';

class ForgotEmailPage extends StatefulWidget {
  const ForgotEmailPage({super.key});

  @override
  State<ForgotEmailPage> createState() => _ForgotEmailPageState();
}

class _ForgotEmailPageState extends State<ForgotEmailPage> {
  final _cpfController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoading = false;
  bool _found = false;
  String? _maskedEmail;
  bool _emailSent = false;
  String? _error;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _lookupEmail() async {
    final cpf = _cpfFormatter.getUnmaskedText();
    if (cpf.isEmpty) {
      setState(() => _error = 'Informe o CPF cadastrado para continuar.');
      return;
    }

    if (cpf.length != 11) {
      setState(() => _error = 'CPF incompleto. Verifique os dados.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _found = false;
      _maskedEmail = null;
      _emailSent = false;
    });

    try {
      final result = await DatabaseService().recoverEmailByCpf(cpf);

      if (result['found'] == true) {
        setState(() {
          _found = true;
          _maskedEmail = result['maskedEmail'];
          _emailSent = result['emailSent'] == true;
        });
      } else {
        // CPF não encontrado ou erro de RLS (que retorna found=false na Edge Function)
        setState(
          () => _error =
              'Não encontramos uma conta com esses dados. Verifique o CPF informado ou fale com o suporte.',
        );
      }
    } catch (e) {
      setState(
        () => _error =
            'Não foi possível consultar agora. Tente novamente em instantes ou fale com o suporte.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PremiumAuthBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Botão Voltar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.arrowLeft(),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Voltar',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo principal
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/conectea_logo.png',
                          width: 260,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            PhosphorIcons.infinity(PhosphorIconsStyle.fill),
                            color: AppColors.primary,
                            size: 60,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      if (!_found) ...[
                        Text(
                          'Esqueci meu e-mail',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Informe o CPF cadastrado para localizarmos seu e-mail de acesso.',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),

                        PremiumCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_error != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIcons.warningCircle(),
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              DsInput(
                                label: 'CPF',
                                controller: _cpfController,
                                hint: '000.000.000-00',
                                icon: PhosphorIcons.identificationCard(),
                                inputFormatters: [_cpfFormatter],
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.search,
                                semanticsLabel: 'CPF cadastrado',
                              ),
                              const SizedBox(height: 32),

                              PremiumButton(
                                text: 'Buscar E-mail Cadastrado',
                                onPressed: _lookupEmail,
                                isLoading: _isLoading,
                                icon: PhosphorIcons.magnifyingGlass(),
                                variant: PremiumButtonVariant.premiumCard,
                                colorOverride: Colors.greenAccent,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Estado de Sucesso com E-mail Mascarado
                        Text(
                          'E-mail Localizado',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Encontramos uma conta associada ao CPF informado.',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),

                        PremiumCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.statusGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIcons.checkCircle(
                                    PhosphorIconsStyle.fill,
                                  ),
                                  color: AppColors.statusGreen,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Encontramos um e-mail cadastrado:',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  _maskedEmail ?? '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                _emailSent
                                    ? 'Também enviamos uma mensagem para esse e-mail com instruções.'
                                    : 'Não foi possível enviar a mensagem agora. Tente novamente em instantes.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _emailSent
                                      ? AppColors.textSecondary
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 32),

                              PremiumButton(
                                text: 'Ir para o Login',
                                onPressed: () => context.pop(),
                                icon: PhosphorIcons.signIn(),
                                variant: PremiumButtonVariant.premiumCard,
                                colorOverride: AppColors.cyan,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
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
}
