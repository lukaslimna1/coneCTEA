import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/core/widgets/premium_auth_background.dart';
import '../../core/design_system_v2/design_system_v2.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _keepConnected = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, preencha todos os campos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.user != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('conectea_keep_connected', _keepConnected);
        } catch (_) {
          if (kDebugMode) {
            debugPrint('[Auth] Falha ao persistir a preferência local de manter conectado.');
          }
        }

        final profile = await _databaseService.getUserProfile(response.user!.id);
        if (profile != null) {
          if (!mounted) return;
          
          if (profile.role.isAdmin) {
            context.go('/home');
          } else {
            context.go('/home');
          }
        } else {
          setState(() => _errorMessage = 'Perfil não encontrado.');
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = _getAuthErrorMessage(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Por favor, confirme seu e-mail antes de acessar.';
    }
    return message;
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      
                      // 1. Logo principal do ConeCTEA
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/conectea_logo.png',
                          width: MediaQuery.sizeOf(context).width * 0.75, // Escalonamento responsivo
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                              PhosphorIcons.infinity(PhosphorIconsStyle.fill),
                              color: AppColors.primary,
                              size: 80,
                            ),
                        ),
                      ),
                  
                  const SizedBox(height: 24),

                  // Título de Boas-vindas
                  Text(
                    'Bem-vindo',
                    style: GoogleFonts.outfit(
                      fontSize: MediaQuery.sizeOf(context).width < 360 ? 28 : 32, // Fonte adaptativa
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtítulo explicativo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Acesse sua conta para acompanhar carteirinhas, solicitações e notificações.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),


                  // Card Principal de Login
                  PremiumCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exibição de erros de autenticação
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(PhosphorIcons.warningCircle(), color: Colors.redAccent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
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

                        const SizedBox(height: 24),
                        // Campo de entrada: E-mail
                        DsInput(
                          label: 'E-mail',
                          controller: _emailController,
                          hint: 'seuemail@exemplo.com',
                          icon: PhosphorIcons.envelopeSimple(),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          semanticsLabel: 'E-mail de acesso',
                        ),
                        const SizedBox(height: 20),

                        // Campo de entrada: Senha com opção de visibilidade
                        DsInput(
                          label: 'Senha',
                          controller: _passwordController,
                          hint: 'Digite sua senha',
                          icon: PhosphorIcons.lockSimple(),
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          semanticsLabel: 'Senha de acesso',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? PhosphorIcons.eye()
                                  : PhosphorIcons.eyeSlash(),
                              color: DsCores.visualizacao.accent,
                            ),
                          ),
                        ),
                        
                        // Links de recuperação de acesso (Responsivo)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isSmall = constraints.maxWidth < 300;
                            
                            if (isSmall) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextButton(
                                    onPressed: () => context.push('/forgot-email'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(
                                      'Recuperar e-mail',
                                      style: GoogleFonts.inter(
                                        color: DsCores.seguranca.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/forgot-password'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(
                                      'Recuperar senha',
                                      style: GoogleFonts.inter(
                                        color: DsCores.seguranca.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: TextButton(
                                    onPressed: () => context.push('/forgot-email'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(
                                      'Recuperar e-mail',
                                      style: GoogleFonts.inter(
                                        color: DsCores.seguranca.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(flex: 2),
                                Expanded(
                                  flex: 4,
                                  child: TextButton(
                                    onPressed: () => context.push('/forgot-password'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerRight,
                                    ),
                                    child: Text(
                                      'Recuperar senha',
                                      style: GoogleFonts.inter(
                                        color: DsCores.seguranca.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        DsCheckbox(
                          value: _keepConnected,
                          onChanged: (val) {
                            setState(() {
                              _keepConnected = val ?? true;
                            });
                          },
                          label: Text(
                            'Manter conectado',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          description: 'Ao desmarcar, você entrará novamente ao abrir o app.',
                          token: DsCores.sucesso,
                          semanticsLabel: 'Manter a conta conectada no dispositivo',
                        ),
                        const SizedBox(height: 24),

                        // Botão de ação principal (Entrar)
                        DsBotao(
                          label: 'Entrar',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                          icon: PhosphorIcons.signIn(),
                          variante: DsBotaoVariante.acao,
                          token: DsCores.sucesso,
                        ),
                        const SizedBox(height: 16),

                        // Botão para novos usuários (Outlined)
                        DsBotao(
                          label: 'Criar conta',
                          onPressed: () => context.push('/register'),
                          variante: DsBotaoVariante.acao,
                          token: DsCores.conta,
                          icon: PhosphorIcons.userPlus(),
                        ),
                        const SizedBox(height: 32),

                        // Box de Informação de Responsáveis
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DsCores.dependente.softBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: DsCores.dependente.border),
                          ),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.info(), color: DsCores.dependente.accent, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Responsáveis podem acessar e alternar entre membros vinculados à conta.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: DsCores.textSecondary,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Aviso de Segurança (Centralização Total e Flexível)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Icon(
                                PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                                color: DsCores.seguranca.accent.withValues(alpha: 0.70),
                                size: 16,
                              ),
                              Text(
                                'Ambiente seguro. Dados protegidos.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: DsCores.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Espaçamento para o conteúdo inferior do background
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
