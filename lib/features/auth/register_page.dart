import 'package:flutter/material.dart';
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
import 'package:conectea/features/auth/widgets/registro/register_input_field.dart';
import 'package:conectea/features/auth/widgets/registro/register_dropdown_field.dart';
import 'package:conectea/features/auth/widgets/registro/register_terms_checkbox.dart';
import 'package:conectea/features/auth/widgets/registro/register_scrollable_dialog.dart';
import 'package:conectea/features/auth/widgets/registro/register_searchable_dropdown.dart';
import 'package:conectea/features/auth/content/register_legal_texts.dart';

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
                '🎉 Parabéns!',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Sua conta foi criada com sucesso.\nVocê já pode fazer login com seu e-mail e senha.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), height: 1.5),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
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
                              RegisterSectionTitle(icon: PhosphorIcons.user(), title: 'Dados Pessoais', iconColor: AppColors.cyan),
                              const SizedBox(height: 20),
                              RegisterInputField(
                                label: 'Nome Completo*',
                                controller: _nomeController,
                                hint: 'Digite seu nome completo',
                                icon: PhosphorIcons.user(),
                                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                              ),
                              const SizedBox(height: 20),
                              RegisterInputField(
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
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool useVerticalLayout = constraints.maxWidth < 340;

                                  if (useVerticalLayout) {
                                    return Column(
                                      children: [
                                        RegisterInputField(
                                          label: 'Telefone (WhatsApp)',
                                          controller: _telefoneController,
                                          hint: '(00) 00000-0000',
                                          icon: PhosphorIcons.phone(),
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [phoneMask],
                                          validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                                        ),
                                        const SizedBox(height: 20),
                                        RegisterInputField(
                                          label: 'Nascimento',
                                          controller: _dataNascimentoController,
                                          hint: 'DD/MM/AAAA',
                                          icon: PhosphorIcons.calendar(),
                                          keyboardType: TextInputType.datetime,
                                          inputFormatters: [dateMask],
                                          validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: RegisterInputField(
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
                                        flex: 1,
                                        child: RegisterInputField(
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
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              RegisterInputField(
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
                               RegisterSectionTitle(icon: PhosphorIcons.mapPin(), title: 'Localização', iconColor: Colors.greenAccent),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RegisterSearchableDropdown(
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
                                  RegisterSearchableDropdown(
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
                                RegisterSectionTitle(icon: PhosphorIcons.shieldCheck(), title: 'Segurança', iconColor: Colors.lightBlueAccent),
                              const SizedBox(height: 20),
                              RegisterInputField(
                                label: 'Senha*',
                                controller: _passwordController,
                                hint: 'Crie uma senha',
                                icon: PhosphorIcons.lock(),
                                obscureText: _obscurePassword,
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
                              RegisterInputField(
                                label: 'Confirmar Senha*',
                                controller: _confirmPasswordController,
                                hint: 'Repita sua senha',
                                icon: PhosphorIcons.lockKey(),
                                obscureText: _obscureConfirmPassword,
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
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                   leading: Icon(PhosphorIcons.dna(), color: Colors.white.withValues(alpha: 0.5), size: 20),
                                  children: [
                                    const SizedBox(height: 12),
                                    RegisterDropdownField<String>(
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
                                      RegisterInputField(
                                        label: 'Nome da instituição',
                                        controller: _nomeInstituicaoController,
                                        hint: 'Digite o nome da instituição',
                                        icon: PhosphorIcons.buildings(),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    RegisterInputField(
                                      label: 'Nome Social',
                                      controller: _nomeSocialController,
                                      hint: 'Como você gostaria de ser chamado(a)',
                                      icon: PhosphorIcons.identificationBadge(),
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RegisterDropdownField<String>(
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
                                        RegisterDropdownField<String>(
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
                              RegisterTermsCheckbox(
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
                                              color: AppColors.cyan,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
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
                                              color: AppColors.cyan,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
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
                              RegisterTermsCheckbox(
                                value: _autorizaDados,
                                onChanged: (v) => setState(() => _autorizaDados = v!),
                                text: Text(
                                  'Autorizo o tratamento de meus dados pessoais.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              RegisterTermsCheckbox(
                                value: _autorizaSaude,
                                onChanged: (v) => setState(() => _autorizaSaude = v!),
                                text: Text(
                                  'Autorizo o tratamento de meus dados de saúde e laudos médicos.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              const SizedBox(height: 40),
                              PremiumButton(
                                text: 'Criar minha conta',
                                onPressed: _handleRegister,
                                isLoading: _isLoading,
                                variant: PremiumButtonVariant.premiumCard,
                                colorOverride: Colors.greenAccent,
                                icon: PhosphorIcons.userCirclePlus(),
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
                                            color: AppColors.cyan,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.7),
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


  void _showTermsOfUse() {
    showDialog(
      context: context,
      builder: (context) => const RegisterScrollableDialog(
        title: 'Termos de Uso',
        content: RegisterLegalTexts.termsOfUse,
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => const RegisterScrollableDialog(
        title: 'Política de Privacidade',
        content: RegisterLegalTexts.privacyPolicy,
      ),
    );
  }

}

