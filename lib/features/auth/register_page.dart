import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/app_user.dart';
import '../../app/routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Principais
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  // Localização
  final _cidadeController = TextEditingController();
  String? _estadoSelecionado;

  // Vínculo
  String _indicacaoInstituicao = 'Não';
  final _nomeInstituicaoController = TextEditingController();

  // Complementares
  String? _sexoSelecionado;
  String? _racaSelecionada;
  final _nomeSocialController = TextEditingController();

  // Segurança
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Termos
  bool _concordaTermos = false;
  bool _autorizaDados = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final List<String> _estados = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _dataNascimentoController.dispose();
    _cidadeController.dispose();
    _nomeInstituicaoController.dispose();
    _nomeSocialController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_concordaTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa concordar com os Termos de Uso.'),
        ),
      );
      return;
    }

    if (!_autorizaDados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa autorizar o tratamento de dados.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Suprimir redirecionamento automático
    AppRoutes.authNotifier.setSuppressRedirect(true);

    try {
      final authService = AuthService();
      final databaseService = DatabaseService();

      // 1. Criar conta no Firebase Auth
      final credential = await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        name: _nomeController.text.trim(),
      );

      if (credential.user != null) {
        // 2. Criar perfil no banco de dados (coleção profiles)
        final newUser = AppUser(
          id: credential.user!.id,
          name: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          cpf: '', // CPF não está no formulário de registro inicial
          phone: _telefoneController.text,
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          dateOfBirth: _dataNascimentoController.text,
          city: _cidadeController.text,
          state: _estadoSelecionado,
          institution: _indicacaoInstituicao == 'Sim'
              ? _nomeInstituicaoController.text
              : null,
          gender: _sexoSelecionado,
          race: _racaSelecionada,
          socialName: _nomeSocialController.text,
        );

        try {
          await databaseService.createUserProfile(newUser);
        } catch (dbError) {
          debugPrint('Erro ao salvar perfil no DB: $dbError');
        }

        // Fazer logout IMEDIATO
        await authService.signOut();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text('🎉 Conta Criada!'),
              content: const Text(
                'Sua conta foi criada com sucesso.\n\nPor segurança, você será redirecionado para a tela de login para acessar o sistema.',
                textAlign: TextAlign.center,
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ir para Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Aguarda o evento de logout propagar no AuthNotifier
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.authNotifier.setSuppressRedirect(false);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 10), // Respiro de 10px do topo
                // Logo principal mais destacada
                Hero(
                  tag: 'app_logo',
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: screenWidth * 0.8, // Aumentado conforme solicitado
                    height: screenHeight * 0.12,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Criar sua conta',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preencha seus dados para acessar\nsolicitações e sua carteirinha digital.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Card de Cadastro
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Dados Pessoais ---
                        _buildSectionTitle('👤 Dados Pessoais'),
                        const SizedBox(height: 16),

                        _buildInputField(
                          label: 'Nome Completo*',
                          controller: _nomeController,
                          hint: 'Digite seu nome completo',
                          icon: Icons.person_outline,
                          validator: (v) =>
                              v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: (screenWidth - 48 - 24 - 12) / 2,
                              child: _buildInputField(
                                label: 'Telefone*',
                                controller: _telefoneController,
                                hint: '(00) 00000-0000',
                                icon: Icons.phone_outlined,
                                inputFormatters: [phoneMask],
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    v!.length < 14 ? 'Telefone inválido' : null,
                              ),
                            ),
                            SizedBox(
                              width: (screenWidth - 48 - 24 - 12) / 2,
                              child: _buildInputField(
                                label: 'Nascimento*',
                                controller: _dataNascimentoController,
                                hint: 'DD/MM/AAAA',
                                icon: Icons.calendar_today_outlined,
                                inputFormatters: [dateMask],
                                keyboardType: TextInputType.datetime,
                                validator: (v) =>
                                    v!.length < 10 ? 'Data inválida' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          label: 'E-mail*',
                          controller: _emailController,
                          hint: 'Digite seu e-mail',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          helper: 'Será usado para login no aplicativo.',
                          validator: (v) {
                            if (v!.isEmpty) return 'Campo obrigatório';
                            if (!v.contains('@')) return 'E-mail inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // --- Localização ---
                        _buildSectionTitle('📍 Localização'),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildInputField(
                                label: 'Cidade*',
                                controller: _cidadeController,
                                hint: 'Sua cidade',
                                icon: Icons.location_on_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Campo obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildDropdownField(
                                label: 'Estado*',
                                value: _estadoSelecionado,
                                items: _estados,
                                icon: Icons.map_outlined,
                                validator: (v) =>
                                    v == null ? 'Obrigatório' : null,
                                onChanged: (v) =>
                                    setState(() => _estadoSelecionado = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Segurança ---
                        _buildSectionTitle('🔐 Segurança'),
                        const SizedBox(height: 16),

                        _buildInputField(
                          label: 'Senha*',
                          controller: _passwordController,
                          hint: 'Crie uma senha',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          validator: (v) =>
                              v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          label: 'Confirmar Senha*',
                          controller: _confirmPasswordController,
                          hint: 'Repita sua senha',
                          icon: Icons.lock_reset_outlined,
                          obscure: _obscureConfirmPassword,
                          validator: (v) => v != _passwordController.text
                              ? 'Senhas não conferem'
                              : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Dados Complementares (Optional Accordion) ---
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              '🧬 Dados complementares (opcional)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 12),
                              // Vínculo movido para cá conforme solicitado
                              _buildDropdownField(
                                label: 'Foi indicado por alguma instituição?',
                                value: _indicacaoInstituicao,
                                items: const ['Não', 'Sim'],
                                icon: Icons.account_balance_outlined,
                                onChanged: (v) =>
                                    setState(() => _indicacaoInstituicao = v!),
                              ),
                              if (_indicacaoInstituicao == 'Sim') ...[
                                const SizedBox(height: 12),
                                _buildInputField(
                                  label: 'Nome da instituição',
                                  controller: _nomeInstituicaoController,
                                  hint: 'Digite o nome da instituição',
                                  icon: Icons.business_outlined,
                                ),
                              ],
                              const SizedBox(height: 16),
                              _buildInputField(
                                label: 'Nome Social',
                                controller: _nomeSocialController,
                                hint: 'Como você gostaria de ser chamado(a)',
                                icon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Sexo',
                                      value: _sexoSelecionado,
                                      items: const [
                                        'Feminino',
                                        'Masculino',
                                        'Não-binário',
                                        'Intersexo',
                                        'Prefiro não informar',
                                        'Outro',
                                      ],
                                      icon: Icons.wc_outlined,
                                      onChanged: (v) =>
                                          setState(() => _sexoSelecionado = v),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Raça / Cor',
                                      value: _racaSelecionada,
                                      items: const [
                                        'Branca',
                                        'Preta',
                                        'Parda',
                                        'Amarela',
                                        'Indígena',
                                        'Prefiro não informar',
                                      ],
                                      icon: Icons.groups_outlined,
                                      onChanged: (v) =>
                                          setState(() => _racaSelecionada = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        const Divider(height: 48),

                        // Termos
                        _buildTermsCheckbox(
                          value: _concordaTermos,
                          onChanged: (v) =>
                              setState(() => _concordaTermos = v!),
                          text: Text.rich(
                            TextSpan(
                              text: 'Li e concordo com os ',
                              children: [
                                TextSpan(
                                  text: 'Termos de Uso',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: ' e '),
                                TextSpan(
                                  text: 'Política de Privacidade',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTermsCheckbox(
                          value: _autorizaDados,
                          onChanged: (v) => setState(() => _autorizaDados = v!),
                          text: Text(
                            'Autorizo o tratamento de meus dados pessoais para as finalidades do aplicativo.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Botão Criar Conta
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Criar minha conta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botão Já tenho conta
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text.rich(
                              TextSpan(
                                text: 'Já tenho uma conta? ',
                                children: [
                                  TextSpan(
                                    text: 'Entrar agora',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Ilustração Familiar
                SvgPicture.asset(
                  'assets/images/family_login_Color.svg',
                  width: double.infinity,
                  height: screenHeight * 0.18,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                // Rodapé de segurança (Alinhado com o Login)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 40,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'O cadastro é simples e sem envio de documentos, para manter o app leve e seguro.',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.darkBlue,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? helper,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<dynamic>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.darkBlue,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          inputFormatters: inputFormatters != null
              ? List<TextInputFormatter>.from(inputFormatters)
              : null,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorStyle: const TextStyle(height: 0.8),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.darkBlue,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorStyle: const TextStyle(height: 0.8),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox({
    required bool value,
    required void Function(bool?) onChanged,
    required Widget text,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: text),
        ],
      ),
    );
  }
}
