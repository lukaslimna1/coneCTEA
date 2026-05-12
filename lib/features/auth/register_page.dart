import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:convert';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/services/auth_service.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/core/widgets/premium_auth_background.dart';
import 'package:conectea/core/widgets/premium/premium_button.dart';
import 'package:conectea/core/widgets/premium/premium_card.dart';
import 'package:conectea/app/routes.dart';
import 'package:conectea/features/auth/utils/auth_cpf_validator.dart';
import 'package:conectea/features/auth/widgets/registro/register_section_title.dart';

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
  final _cpfController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  // Localização
  String? _selectedState;
  String? _selectedCity;
  List<Map<String, dynamic>> _states = [];
  List<String> _cities = [];
  bool _isLoadingCities = false;

  // Vínculo
  String _indicacaoInstituicao = 'Não';
  final _nomeInstituicaoController = TextEditingController();

  // Complementares
  String? _generoSelecionado;
  String? _racaSelecionada;
  final _nomeSocialController = TextEditingController();

  // Segurança
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Termos
  bool _concordaTermos = false;
  bool _autorizaDados = false;
  bool _autorizaSaude = false;

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

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _states = data.map((s) => {
            'sigla': s['sigla'],
            'nome': s['nome'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar estados: $e');
    }
  }

  Future<void> _fetchCities(String stateSigla) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$stateSigla/municipios?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _cities = data.map((c) => c['nome'].toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar cidades: $e');
    } finally {
      setState(() => _isLoadingCities = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _dataNascimentoController.dispose();
    _nomeInstituicaoController.dispose();
    _nomeSocialController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione Estado e Cidade')),
      );
      return;
    }

    if (!_concordaTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa concordar com os Termos de Uso e Privacidade.')),
      );
      return;
    }

    if (!_autorizaDados) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa autorizar o tratamento de dados pessoais.')),
      );
      return;
    }

    if (!_autorizaSaude) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa autorizar o tratamento de dados de saúde.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    AppRoutes.authNotifier.setSuppressRedirect(true);

    try {
      final databaseService = DatabaseService();
      
      // Verifica se o e-mail já existe
      final emailExists = await databaseService.isEmailRegistered(_emailController.text.trim());
      if (emailExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este e-mail já está cadastrado.'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Verifica se o CPF já existe
      final cleanCpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cpfExists = await databaseService.isCpfRegistered(cleanCpf);
      if (cpfExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este CPF já está cadastrado.'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final authService = AuthService();
      final userData = {
        'name': _nomeController.text.trim(),
        'cpf': _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'phone': _telefoneController.text,
        'date_of_birth': _dataNascimentoController.text,
        'city': _selectedCity ?? '',
        'state': _selectedState ?? '',
        'institution': _indicacaoInstituicao == 'Sim' ? _nomeInstituicaoController.text : '',
        'gender': _generoSelecionado ?? '',
        'race': _racaSelecionada ?? '',
        'social_name': _nomeSocialController.text,
      };

      final credential = await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        data: userData,
      );

      if (credential.user != null) {
        final newUser = AppUser(
          id: credential.user!.id,
          name: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          cpf: _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          phone: _telefoneController.text,
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          dateOfBirth: _dataNascimentoController.text,
          city: _selectedCity ?? '',
          state: _selectedState ?? '',
          institution: _indicacaoInstituicao == 'Sim'
              ? _nomeInstituicaoController.text
              : '',
          gender: _generoSelecionado ?? '',
          race: _racaSelecionada ?? '',
          socialName: _nomeSocialController.text,
        );

        try {
          await databaseService.createUserProfile(newUser);
        } catch (dbError) {
          debugPrint('Erro ao salvar perfil no DB: $dbError');
        }
        
        await authService.signOut();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0C2445),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Text(
                '📧 Verifique seu e-mail',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Cadastro realizado com sucesso! 🚀\n\n'
                'Enviamos um e-mail de confirmação para você. '
                'Por favor, verifique sua caixa de entrada (e a pasta de Spam) e clique no link de validação para ativar sua conta antes de fazer o login.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Ir para Login',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800),
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
            content: const Text('Não foi possível criar sua conta agora. Verifique os dados e tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      AppRoutes.authNotifier.setSuppressRedirect(false);
      if (mounted) setState(() => _isLoading = false);
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
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Icon(PhosphorIcons.arrowLeft(), color: Colors.white, size: 20),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/conectea_logo.png',
                          width: 300, // Premium size (260-320px)
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Criar sua conta',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha seus dados para acessar\nsolicitações e sua carteirinha digital.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      PremiumCard(
                        hasGradient: true,
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RegisterSectionTitle(icon: PhosphorIcons.user(), title: 'Dados Pessoais'),
                              const SizedBox(height: 20),
                              _buildInputField(
                                label: 'Nome Completo*',
                                controller: _nomeController,
                                hint: 'Digite seu nome completo',
                                 icon: PhosphorIcons.user(),
                                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildInputField(
                                label: 'CPF*',
                                controller: _cpfController,
                                hint: '000.000.000-00',
                                 icon: PhosphorIcons.identificationCard(),
                                inputFormatters: [cpfMask],
                                keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                                    if (!isValidAuthCpf(v)) return 'CPF inválido';
                                    return null;
                                  },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Telefone*',
                                      controller: _telefoneController,
                                      hint: '(00) 00000-0000',
                                       icon: PhosphorIcons.phone(),
                                      inputFormatters: [phoneMask],
                                      keyboardType: TextInputType.phone,
                                      validator: (v) => v!.length < 14 ? 'Telefone inválido' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
                                      label: 'Nascimento*',
                                      controller: _dataNascimentoController,
                                      hint: 'DD/MM/AAAA',
                                       icon: PhosphorIcons.calendar(),
                                      inputFormatters: [dateMask],
                                      keyboardType: TextInputType.datetime,
                                      validator: (v) => v!.length < 10 ? 'Data inválida' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildInputField(
                                label: 'E-mail*',
                                controller: _emailController,
                                hint: 'Digite seu e-mail',
                                 icon: PhosphorIcons.envelopeSimple(),
                                keyboardType: TextInputType.emailAddress,
                                helper: 'Será usado para login no aplicativo.',
                                validator: (v) {
                                  if (v!.isEmpty) return 'Campo obrigatório';
                                  if (!v.contains('@')) return 'E-mail inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                               RegisterSectionTitle(icon: PhosphorIcons.mapPin(), title: 'Localização'),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSearchableDropdown(
                                    label: 'Estado*',
                                    value: _selectedState,
                                    items: _states.map((s) => s['sigla'] as String).toList(),
                                    icon: PhosphorIcons.mapTrifold(),
                                    onChanged: (v) {
                                      setState(() => _selectedState = v);
                                      _fetchCities(v);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildSearchableDropdown(
                                    label: 'Cidade*',
                                    value: _selectedCity,
                                    items: _cities,
                                    icon: PhosphorIcons.mapPin(),
                                    hint: _isLoadingCities ? 'Buscando...' : 'Selecione',
                                    onChanged: (v) => setState(() => _selectedCity = v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                                RegisterSectionTitle(icon: PhosphorIcons.shieldCheck(), title: 'Segurança'),
                              const SizedBox(height: 20),
                              _buildInputField(
                                label: 'Senha*',
                                controller: _passwordController,
                                hint: 'Crie uma senha',
                                 icon: PhosphorIcons.lock(),
                                obscure: _obscurePassword,
                                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                     _obscurePassword ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye(),
                                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildInputField(
                                label: 'Confirmar Senha*',
                                controller: _confirmPasswordController,
                                hint: 'Repita sua senha',
                                 icon: PhosphorIcons.lockKey(),
                                obscure: _obscureConfirmPassword,
                                validator: (v) => v != _passwordController.text ? 'Senhas não conferem' : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                     _obscureConfirmPassword ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye(),
                                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    '🧬 Dados complementares (opcional)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cyan,
                                    ),
                                  ),
                                   leading: Icon(PhosphorIcons.dna(), color: AppColors.cyan, size: 20),
                                  children: [
                                    const SizedBox(height: 12),
                                    _buildDropdownField<String>(
                                      label: 'Foi indicado por alguma instituição?',
                                      value: _indicacaoInstituicao,
                                      items: const ['Não', 'Sim']
                                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white))))
                                          .toList(),
                                       icon: PhosphorIcons.bank(),
                                      onChanged: (v) => setState(() => _indicacaoInstituicao = v!),
                                    ),
                                    if (_indicacaoInstituicao == 'Sim') ...[
                                      const SizedBox(height: 16),
                                      _buildInputField(
                                        label: 'Nome da instituição',
                                        controller: _nomeInstituicaoController,
                                        hint: 'Digite o nome da instituição',
                                         icon: PhosphorIcons.buildings(),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      label: 'Nome Social',
                                      controller: _nomeSocialController,
                                      hint: 'Como você gostaria de ser chamado(a)',
                                       icon: PhosphorIcons.identificationBadge(),
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDropdownField<String>(
                                          label: 'Gênero',
                                          value: _generoSelecionado,
                                          hint: 'Selecione',
                                          items: const [
                                            'Feminino',
                                            'Masculino',
                                            'Não binário',
                                            'Outro',
                                            'Prefiro não informar',
                                          ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white)))).toList(),
                                          icon: PhosphorIcons.genderIntersex(),
                                          onChanged: (v) => setState(() => _generoSelecionado = v),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDropdownField<String>(
                                          label: 'Raça / Cor',
                                          value: _racaSelecionada,
                                          hint: 'Selecione',
                                          items: const [
                                            'Branca',
                                            'Preta',
                                            'Parda',
                                            'Amarela',
                                            'Indígena',
                                            'Prefiro não informar',
                                          ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white)))).toList(),
                                          icon: PhosphorIcons.usersThree(),
                                          onChanged: (v) => setState(() => _racaSelecionada = v),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              const Divider(height: 48, color: Colors.white10),
                              _buildTermsCheckbox(
                                value: _concordaTermos,
                                onChanged: (v) => setState(() => _concordaTermos = v!),
                                text: Text.rich(
                                  TextSpan(
                                    text: 'Li e concordo com os ',
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: _showTermsOfUse,
                                          child: const Text(
                                            'Termos de Uso',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' e '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: _showPrivacyPolicy,
                                          child: const Text(
                                            'Política de Privacidade',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 36, top: 4, right: 16),
                                child: Text(
                                  'O tratamento de dados pessoais no ConeCTEA segue a Lei Geral de Proteção de Dados (LGPD).',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTermsCheckbox(
                                value: _autorizaDados,
                                onChanged: (v) => setState(() => _autorizaDados = v!),
                                text: Text(
                                  'Autorizo o tratamento de meus dados pessoais.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTermsCheckbox(
                                value: _autorizaSaude,
                                onChanged: (v) => setState(() => _autorizaSaude = v!),
                                text: Text(
                                  'Autorizo o tratamento de meus dados de saúde e laudos médicos.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              const SizedBox(height: 40),
                              PremiumButton(
                                text: 'Criar minha conta',
                                onPressed: _handleRegister,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 24),
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
                                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // Espaço reduzido pois o rodapé agora tem espaço próprio no Column
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? helper,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF071B3A).withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            errorStyle: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String) onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SearchAnchor(
          builder: (context, controller) {
            return InkWell(
              onTap: () => controller.openView(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF071B3A).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value ?? hint ?? 'Selecione',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: value == null ? AppColors.textSecondary.withValues(alpha: 0.3) : Colors.white,
                        ),
                      ),
                    ),
                    const Icon(PhosphorIconsRegular.caretDown, color: AppColors.textSecondary, size: 16),
                  ],
                ),
              ),
            );
          },
          viewBackgroundColor: const Color(0xFF071B3A),
          viewSurfaceTintColor: const Color(0xFF071B3A),
          viewHintText: 'Digite para buscar...',
          viewLeading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          suggestionsBuilder: (context, controller) {
            final keyword = controller.text.toLowerCase();
            final filtered = items.where((item) => item.toLowerCase().contains(keyword)).toList();

            return filtered.map((item) => ListTile(
              title: Text(item, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.white)),
              onTap: () {
                controller.closeView(item);
                onChanged(item);
              },
            ));
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required IconData icon,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          isExpanded: true,
          initialValue: items.any((item) => item.value == value) ? value : null,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: const Color(0xFF0C2445),
          icon: const Icon(PhosphorIconsRegular.caretDown, color: AppColors.textSecondary, size: 16),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            filled: true,
            fillColor: const Color(0xFF071B3A).withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorStyle: const TextStyle(height: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget text,
  }) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: text),
      ],
    );
  }

  void _showTermsOfUse() {
    showDialog(
      context: context,
      builder: (context) => _buildScrollableDialog(
        title: 'Termos de Uso',
        content: '''
📄 TERMOS DE USO - ConeCTEA
Versão: 1.0
Instituição responsável: Família TEA Bauru
Contato oficial: https://www.instagram.com/familiateabauru
Cidade/Estado: Bauru — SP

1. Sobre estes Termos
Estes Termos de Uso estabelecem as regras para acesso e utilização do aplicativo ConeCTEA, incluindo suas funcionalidades, serviços, informações, solicitações, carteirinha digital, área do usuário e área administrativa.
Ao criar uma conta, acessar ou utilizar o aplicativo, o usuário declara que leu, compreendeu e concorda com estes Termos de Uso, bem como com a Política de Privacidade do ConeCTEA.

2. Sobre o ConeCTEA
O ConeCTEA é um aplicativo desenvolvido para facilitar o acesso à carteirinha digital, organizar solicitações, permitir acompanhamento de status, centralizar informações importantes e melhorar a comunicação entre usuários, responsáveis e a Família TEA Bauru.

3. Responsabilidades do Usuário
- Fornecer informações verídicas e atualizadas.
- Manter a segurança de sua senha de acesso.
- Utilizar o aplicativo de forma ética e respeitosa.
- Não utilizar robôs ou scripts para automatizar processos.

4. Privacidade e Proteção de Dados
O tratamento de dados pessoais no ConeCTEA segue a Lei Geral de Proteção de Dados (LGPD). Consulte nossa Política de Privacidade para mais detalhes.

5. Limitação de Responsabilidade
A Família TEA Bauru não se responsabiliza por danos decorrentes do uso indevido do aplicativo ou por problemas técnicos fora de seu controle.

6. Alterações nos Termos
Estes termos podem ser atualizados periodicamente. O uso continuado do aplicativo após alterações constitui aceitação dos novos termos.

7. Contato
Para dúvidas ou suporte, entre em contato via Instagram: @familiateabauru
''',
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => _buildScrollableDialog(
        title: 'Política de Privacidade',
        content: '''
🛡️ POLÍTICA DE PRIVACIDADE — ConeCTEA
Versão: 1.0
Instituição responsável: Família TEA Bauru

Esta Política de Privacidade explica como o aplicativo ConeCTEA coleta, utiliza, armazena, protege e trata os dados pessoais dos usuários.

1. Sobre esta Política
O objetivo deste documento é garantir transparência sobre o uso das informações cadastradas, especialmente relacionadas à conta, solicitação de carteirinha, acompanhamento de status e comunicação com a instituição.

2. Coleta de Dados
O ConeCTEA coleta dados necessários para cadastro, autenticação e emissão da carteirinha digital, incluindo: nome completo, e-mail, telefone, cidade, estado, data de nascimento e informações de representação (para crianças e adolescentes).

3. Uso dos Dados
Seus dados são utilizados exclusivamente para:
- Criar e gerenciar sua conta.
- Solicitação e emissão da carteirinha digital.
- Acompanhamento de status e validação.
- Comunicação institucional e suporte.
- Geração de estatísticas internas para melhoria do atendimento.

4. Proteção e Segurança
Adotamos medidas administrativas e tecnológicas para proteger seus dados contra acessos não autorizados. O app prioriza uma estrutura leve e não armazena diretamente documentos pesados ou laudos sensíveis.

5. Seus Direitos (LGPD)
Você tem direito a confirmar o tratamento, acessar, corrigir ou solicitar a exclusão de seus dados a qualquer momento através dos canais oficiais.

Ao criar uma conta, acessar ou utilizar o aplicativo, o usuário declara estar ciente da Política de Privacidade do ConeCTEA.
''',
      ),
    );
  }

  Widget _buildScrollableDialog({required String title, required String content}) {
    final isTerms = title.contains('Termos');
    return AlertDialog(
      backgroundColor: const Color(0xFF0C2445),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          Icon(
            isTerms ? PhosphorIcons.fileText() : PhosphorIcons.shieldCheck(),
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: PremiumButton(
            text: 'Compreendido',
            onPressed: () => Navigator.pop(context),
            icon: PhosphorIcons.check(),
          ),
        ),
      ],
    );
  }
}

