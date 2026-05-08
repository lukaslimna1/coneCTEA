import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/app_user.dart';
import 'forgot_email_page.dart';

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

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, preencha todos os campos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.signInWithEmailPassword(email, password);
      
      if (response.user != null) {
        final databaseService = DatabaseService();
        final profile = await databaseService.getUserProfile(response.user!.id);
        
        if (profile == null) {
          // Se o perfil não existe (ex: conta antiga ou erro no cadastro), cria um perfil básico
          final newUser = AppUser(
            id: response.user!.id,
            name: response.user!.userMetadata?['full_name'] ?? email.split('@')[0],
            email: email,
            cpf: '',
            phone: '',
            role: UserRole.user,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          );
          await databaseService.createUserProfile(newUser);
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado ao tentar entrar.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10), // Respiro de 10px do topo
                    
                    // 1. Logo principal do ConeCTEA
                    Hero(
                      tag: 'app_logo',
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: MediaQuery.sizeOf(context).width * 0.8, // Maior conforme solicitado
                        height: screenHeight * 0.12, // Reduzido para caber melhor
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Container(
                          height: screenHeight * 0.12,
                          alignment: Alignment.center,
                          child: Text(
                            'ConeCTEA',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                
                // 2. Título de Boas-vindas bem próximo à logo
                const SizedBox(height: 4),

                // Título de Boas-vindas
                Text(
                  'Bem-vindo ao ConeCTEA',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBlue,
                    letterSpacing: -0.5,
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
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12), // Reduzido de 20


                // Card Principal de Login
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exibição de erros de autenticação
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade800, 
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Campo de entrada: E-mail
                      Text(
                        'E-mail',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBlue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Digite seu e-mail',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12), // Reduzido de 20

                      // Campo de entrada: Senha com opção de visibilidade
                      Text(
                        'Senha',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBlue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Digite sua senha',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: StatefulBuilder(
                            builder: (context, setEyeState) => IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setEyeState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                                setState(() {}); // Still call parent setState to update TextField's obscureText
                              },
                            ),
                          ),
                        ),
                      ),

                      // Links de recuperação
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotEmailPage())),
                            child: Text(
                              'Esqueci meu e-mail',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              'Esqueci minha senha',
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Reduzido de 16

                      // Botão de ação principal (Entrar)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading 
                              ? const SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botão para novos usuários
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () {
                            context.push('/register');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Primeiro acesso / Criar conta'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Box de Informação de Responsáveis (Idêntico à referência)
                      _buildInfoBox(
                        icon: Icons.info_outline,
                        text: 'Responsáveis podem acessar e alternar entre membros vinculados à conta.',
                        backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        iconColor: AppColors.primary,
                        textColor: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),


                // Ilustração da Família
                SvgPicture.asset(
                  'assets/images/family_login_Color.svg',
                  width: double.infinity,
                  height: screenHeight * 0.15, // Ajustado para visibilidade
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 20),


                // Rodapé de Segurança (Idêntico à referência: Ícone solto + Texto)
                Padding(
                  // Alinha horizontalmente com o conteúdo do _buildInfoBox (24 do card + 20 do padding interno do box = 44)
                  padding: const EdgeInsets.symmetric(horizontal: 44.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 28, color: AppColors.textSecondary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Documentos e anexos são enviados por link externo para manter o app leve e seguro.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12), // Reduzido de 24
              ],
            ),
          ),
        ),
      ],
    ),
      ),
    );
  }

  /// Helper widget para criar boxes de informação padronizados.
  /// Garante consistência visual, tamanho e alinhamento entre diferentes partes da tela.
  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28), 
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


