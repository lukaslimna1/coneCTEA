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
import 'package:conectea/core/widgets/premium_auth_background.dart';
import 'package:conectea/app/routes.dart';
import 'package:conectea/features/auth/cadastro/utils/auth_cpf_validator.dart';
import 'package:conectea/features/auth/cadastro/widgets/register_section_title.dart';
import 'package:conectea/features/auth/cadastro/widgets/register_terms_checkbox.dart';
import 'package:conectea/features/auth/cadastro/widgets/register_scrollable_dialog.dart';
import 'package:conectea/features/auth/cadastro/content/register_legal_texts.dart';
import '../../../core/design_system_v2/design_system_v2.dart';

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
  final _confirmEmailController = TextEditingController();
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

  // Termos e Consentimentos
  bool _declaraMaioridade = false;
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
        Uri.parse(
          'https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _states = data
              .map((s) => {'sigla': s['sigla'], 'nome': s['nome']})
              .toList();
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
        Uri.parse(
          'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$stateSigla/municipios?orderBy=nome',
        ),
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
    _confirmEmailController.dispose();
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
      _showRegisterFeedback('Selecione Estado e Cidade');
      return;
    }

    // 1. VALIDAÇÃO LOCAL DE MAIORIDADE MÍNIMA (18 ANOS)
    final birthStr = _dataNascimentoController.text.trim();
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(birthStr)) {
      _showRegisterFeedback(
        'Formato de data de nascimento inválido. Use DD/MM/AAAA.',
      );
      return;
    }

    final parts = birthStr.split('/');
    final day = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final year = int.tryParse(parts[2]) ?? 0;

    final birthDate = DateTime(year, month, day);

    // Validação rígida round-trip (evita datas fictícias como 31/11/2000 que viram 01/12/2000)
    if (birthDate.year != year ||
        birthDate.month != month ||
        birthDate.day != day) {
      _showRegisterFeedback(
        'Data de nascimento inválida. Use o formato DD/MM/AAAA.',
      );
      return;
    }

    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    if (age < 18) {
      _showRegisterFeedback(
        'O cadastro próprio é permitido apenas para maiores de 18 anos. Caso você seja menor de idade, peça para seu responsável legal realizar o cadastro.',
      );
      return;
    }

    // 2. CHECKBOXES E CONSENTIMENTOS OBRIGATÓRIOS
    if (!_declaraMaioridade) {
      _showRegisterFeedback(
        'Para continuar, declare que possui 18 anos ou mais e assume responsabilidade.',
      );
      return;
    }

    if (!_concordaTermos) {
      _showRegisterFeedback(
        'Você precisa concordar com os Termos de Uso e Política de Privacidade.',
      );
      return;
    }

    if (!_autorizaDados) {
      _showRegisterFeedback(
        'Você precisa autorizar o tratamento de dados pessoais comuns.',
      );
      return;
    }

    if (!_autorizaSaude) {
      _showRegisterFeedback(
        'Você precisa autorizar o tratamento de dados de saúde.',
      );
      return;
    }

    setState(() => _isLoading = true);

    AppRoutes.authNotifier.setSuppressRedirect(true);

    try {
      final authService = AuthService();

      // Metadados LGPD e consentimentos a serem gravados via trigger atômica
      final userData = {
        'name': _nomeController.text.trim(),
        'cpf': _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'phone': _telefoneController.text,
        'date_of_birth': _dataNascimentoController.text,
        'city': _selectedCity ?? '',
        'state': _selectedState ?? '',
        'institution': _indicacaoInstituicao == 'Sim'
            ? _nomeInstituicaoController.text
            : '',
        'gender': _generoSelecionado ?? '',
        'race': _racaSelecionada ?? '',
        'social_name': _nomeSocialController.text,

        // Consentimentos e declarações para fins de auditoria LGPD
        'consent_terms_accepted': _concordaTermos,
        'consent_privacy_accepted': _concordaTermos,
        'consent_personal_data_accepted': _autorizaDados,
        'consent_health_data_accepted': _autorizaSaude,
        'legal_age_declared': _declaraMaioridade,
        'consent_terms_version': '1.0',
        'consent_privacy_version': '1.0',
        'consent_source': 'register',
      };

      // Chamada atômica do Supabase Auth
      final credential = await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        data: userData,
      );

      if (credential.user != null) {
        // Desconecta do client imediatamente para limpar a sessão parcial provisória
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
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'Sua conta foi criada com sucesso.\nVocê já pode fazer login com seu e-mail e senha.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
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
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } on AuthException catch (e) {
      String friendlyMessage = e.message;

      // Mapeamento cirúrgico de erros do Postgres / Trigger / Constraints sem expor stack traces
      if (e.message.contains('profiles_cpf_unique') ||
          e.message.contains('Este CPF já está cadastrado') ||
          e.message.contains('Database error saving new user') ||
          e.message.toLowerCase().contains('database error saving new user') ||
          e.message.contains('unexpected_failure')) {
        friendlyMessage =
            'Este CPF já está associado a outra conta. Se necessário, use a Recuperação de E-mail.';
      } else if (e.message.contains(
            'duplicate key value violates unique constraint',
          ) &&
          e.message.contains('email')) {
        friendlyMessage =
            'Este e-mail já está cadastrado. Se necessário, use a Recuperação de Senha.';
      } else if (e.message.contains(
        'cadastro próprio é permitido apenas para maiores',
      )) {
        friendlyMessage =
            'O cadastro próprio é permitido apenas para maiores de 18 anos. Caso você seja menor de idade, peça para seu responsável legal realizar o cadastro.';
      } else if (e.message.contains('precisa ler e aceitar') ||
          e.message.contains('autorizar o tratamento') ||
          e.message.contains('declaração de maioridade')) {
        friendlyMessage =
            'Para continuar, aceite os termos e consentimentos obrigatórios.';
      } else if (e.message.contains('User already registered') ||
          e.message.contains('already exists')) {
        friendlyMessage =
            'Este e-mail já está cadastrado. Se necessário, use a Recuperação de Senha.';
      }

      _showRegisterFeedback(friendlyMessage);
    } catch (e) {
      _showRegisterFeedback(
        'Não foi possível concluir o cadastro agora. Tente novamente em instantes.',
      );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsEspacamentos.edge,
                  ),
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
                      const SizedBox(height: DsEspacamentos.lg),
                      Text('Criar sua conta', style: DsTipografia.pageTitle),
                      const SizedBox(height: DsEspacamentos.sm),
                      Text(
                        'Preencha seus dados para acessar\nsolicitações e sua carteirinha digital.',
                        textAlign: TextAlign.center,
                        style: DsTipografia.pageSubtitle,
                      ),
                      const SizedBox(height: DsEspacamentos.xl),
                      DsCard(
                        hasGradient: true,
                        padding: const EdgeInsets.all(DsEspacamentos.lg),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RegisterSectionTitle(
                                icon: PhosphorIcons.user(),
                                title: 'Dados Pessoais',
                                iconColor: AppColors.cyan,
                              ),
                              const SizedBox(height: 20),
                              DsInput(
                                label: 'Nome Completo*',
                                controller: _nomeController,
                                hint: 'Nome e sobrenome',
                                icon: PhosphorIcons.user(),
                                textInputAction: TextInputAction.next,
                                semanticsLabel: 'Nome completo',
                                validator: (v) =>
                                    v!.isEmpty ? 'Campo obrigatório' : null,
                              ),
                              const SizedBox(height: 20),
                              DsInput(
                                label: 'CPF*',
                                controller: _cpfController,
                                hint: '000.000.000-00',
                                icon: PhosphorIcons.identificationCard(),
                                inputFormatters: [cpfMask],
                                keyboardType: TextInputType.number,
                                helperText:
                                    'Ajuda a evitar cadastro duplicado.',
                                textInputAction: TextInputAction.next,
                                semanticsLabel: 'CPF',
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Campo obrigatório';
                                  if (!isValidAuthCpf(v)) return 'CPF inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool useVerticalLayout =
                                      constraints.maxWidth < 340;

                                  if (useVerticalLayout) {
                                    return Column(
                                      children: [
                                        DsInput(
                                          label: 'Telefone (WhatsApp)',
                                          controller: _telefoneController,
                                          hint: '(00) 00000-0000',
                                          icon: PhosphorIcons.phone(),
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [phoneMask],
                                          helperText:
                                              'Será usado para contato sobre o cadastro.',
                                          textInputAction: TextInputAction.next,
                                          semanticsLabel: 'Telefone',
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Obrigatório'
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        DsInput(
                                          label: 'Nascimento',
                                          controller: _dataNascimentoController,
                                          hint: 'DD/MM/AAAA',
                                          icon: PhosphorIcons.calendar(),
                                          keyboardType: TextInputType.datetime,
                                          inputFormatters: [dateMask],
                                          helperText:
                                              'Ajuda na identificação do cadastro.',
                                          textInputAction: TextInputAction.next,
                                          semanticsLabel: 'Data de nascimento',
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? 'Obrigatório'
                                              : null,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: DsInput(
                                          label: 'Telefone*',
                                          controller: _telefoneController,
                                          hint: '(00) 00000-0000',
                                          icon: PhosphorIcons.phone(),
                                          inputFormatters: [phoneMask],
                                          keyboardType: TextInputType.phone,
                                          helperText:
                                              'Será usado para contato sobre o cadastro.',
                                          textInputAction: TextInputAction.next,
                                          semanticsLabel: 'Telefone',
                                          validator: (v) => v!.length < 14
                                              ? 'Telefone inválido'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: DsInput(
                                          label: 'Nascimento*',
                                          controller: _dataNascimentoController,
                                          hint: 'DD/MM/AAAA',
                                          icon: PhosphorIcons.calendar(),
                                          inputFormatters: [dateMask],
                                          keyboardType: TextInputType.datetime,
                                          helperText:
                                              'Ajuda na identificação do cadastro.',
                                          textInputAction: TextInputAction.next,
                                          semanticsLabel: 'Data de nascimento',
                                          validator: (v) => v!.length < 10
                                              ? 'Data inválida'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              DsInput(
                                label: 'E-mail*',
                                controller: _emailController,
                                hint: 'seuemail@exemplo.com',
                                icon: PhosphorIcons.envelopeSimple(),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                semanticsLabel: 'E-mail',
                                helperText:
                                    'Será usado para login no aplicativo.',
                                validator: (v) {
                                  if (v!.isEmpty) return 'Campo obrigatório';
                                  if (!v.contains('@'))
                                    return 'E-mail inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              DsInput(
                                label: 'Confirmar E-mail*',
                                controller: _confirmEmailController,
                                hint: 'Repita seu e-mail',
                                icon: PhosphorIcons.envelopeSimple(),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                semanticsLabel: 'Confirmar E-mail',
                                helperText: 'Repita o e-mail para confirmação.',
                                validator: (v) {
                                  if (v!.isEmpty) return 'Campo obrigatório';
                                  if (v.trim().toLowerCase() !=
                                      _emailController.text
                                          .trim()
                                          .toLowerCase()) {
                                    return 'Os e-mails informados não conferem.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              RegisterSectionTitle(
                                icon: PhosphorIcons.mapPin(),
                                title: 'Localização',
                                iconColor: Colors.greenAccent,
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DsSearchableDropdown(
                                    label: 'Estado*',
                                    value: _selectedState,
                                    items: _states
                                        .map((s) => s['sigla'] as String)
                                        .toList(),
                                    icon: PhosphorIcons.mapTrifold(),
                                    searchHint: 'Buscar estado',
                                    semanticsLabel: 'Estado',
                                    onChanged: (v) {
                                      setState(() => _selectedState = v);
                                      if (v != null) {
                                        _fetchCities(v);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  DsSearchableDropdown(
                                    label: 'Cidade*',
                                    value: _selectedCity,
                                    items: _cities,
                                    icon: PhosphorIcons.mapPin(),
                                    hint: _isLoadingCities
                                        ? 'Buscando...'
                                        : 'Selecione',
                                    searchHint: 'Buscar cidade',
                                    semanticsLabel: 'Cidade',
                                    onChanged: (v) =>
                                        setState(() => _selectedCity = v),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ajuda na organização do atendimento regional.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              RegisterSectionTitle(
                                icon: PhosphorIcons.shieldCheck(),
                                title: 'Segurança',
                                iconColor: Colors.lightBlueAccent,
                              ),
                              const SizedBox(height: 20),
                              DsInput(
                                label: 'Senha*',
                                controller: _passwordController,
                                hint: 'Crie uma senha',
                                icon: PhosphorIcons.lock(),
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                semanticsLabel: 'Senha',
                                obscureText: _obscurePassword,
                                validator: (v) => v!.length < 6
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? PhosphorIcons.eyeSlash()
                                        : PhosphorIcons.eye(),
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DsInput(
                                label: 'Confirmar Senha*',
                                controller: _confirmPasswordController,
                                hint: 'Repita sua senha',
                                icon: PhosphorIcons.lockKey(),
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                semanticsLabel: 'Confirmar Senha',
                                obscureText: _obscureConfirmPassword,
                                validator: (v) => v != _passwordController.text
                                    ? 'Senhas não conferem'
                                    : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? PhosphorIcons.eyeSlash()
                                        : PhosphorIcons.eye(),
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    '🧬 Dados complementares (opcional)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  leading: Icon(
                                    PhosphorIcons.dna(),
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                  children: [
                                    const SizedBox(height: 12),
                                    DsDropdown(
                                      label:
                                          'Foi indicado por alguma instituição?',
                                      value: _indicacaoInstituicao,
                                      items: const ['Não', 'Sim'],
                                      icon: PhosphorIcons.bank(),
                                      onChanged: (v) => setState(
                                        () => _indicacaoInstituicao = v!,
                                      ),
                                      semanticsLabel:
                                          'Indicação por instituição',
                                    ),
                                    if (_indicacaoInstituicao == 'Sim') ...[
                                      const SizedBox(height: 16),
                                      DsInput(
                                        label: 'Nome da instituição',
                                        controller: _nomeInstituicaoController,
                                        hint: 'Digite o nome da instituição',
                                        icon: PhosphorIcons.buildings(),
                                        textInputAction: TextInputAction.next,
                                        semanticsLabel: 'Nome da instituição',
                                        helperText:
                                            'Informe se houver vínculo com uma instituição.',
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    DsInput(
                                      label: 'Nome Social',
                                      controller: _nomeSocialController,
                                      hint:
                                          'Como você gostaria de ser chamado(a)',
                                      icon: PhosphorIcons.identificationBadge(),
                                      textInputAction: TextInputAction.next,
                                      semanticsLabel: 'Nome Social',
                                      helperText:
                                          'Será usado para chamar você pelo nome correto.',
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DsDropdown(
                                          label: 'Gênero',
                                          value: _generoSelecionado,
                                          hint: 'Selecione',
                                          items: const [
                                            'Feminino',
                                            'Masculino',
                                            'Não binário',
                                            'Outro',
                                            'Prefiro não informar',
                                          ],
                                          icon: PhosphorIcons.genderIntersex(),
                                          onChanged: (v) => setState(
                                            () => _generoSelecionado = v,
                                          ),
                                          semanticsLabel: 'Gênero',
                                        ),
                                        const SizedBox(height: 16),
                                        DsDropdown(
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
                                          ],
                                          icon: PhosphorIcons.usersThree(),
                                          onChanged: (v) => setState(
                                            () => _racaSelecionada = v,
                                          ),
                                          semanticsLabel: 'Raça ou cor',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: DsEspacamentos.xxl,
                                color: Colors.white10,
                              ),
                              DsCheckbox(
                                value: _declaraMaioridade,
                                onChanged: (v) =>
                                    setState(() => _declaraMaioridade = v!),
                                label: Text(
                                  'Declaro que tenho 18 anos ou mais e sou responsável pelas informações fornecidas neste cadastro.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                token: DsCores.sucesso,
                                semanticsLabel:
                                    'Declaração de maioridade e responsabilidade pelo cadastro',
                              ),
                              const SizedBox(height: DsEspacamentos.md),
                              RegisterTermsCheckbox(
                                value: _concordaTermos,
                                onChanged: (v) =>
                                    setState(() => _concordaTermos = v!),
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
                                padding: const EdgeInsets.only(
                                  left: 36,
                                  top: 4,
                                  right: 16,
                                ),
                                child: Text(
                                  'O tratamento de dados pessoais no ConeCTEA segue a Lei Geral de Proteção de Dados (LGPD).',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: DsEspacamentos.md),
                              RegisterTermsCheckbox(
                                value: _autorizaDados,
                                onChanged: (v) =>
                                    setState(() => _autorizaDados = v!),
                                text: Text(
                                  'Autorizo o tratamento de meus dados pessoais.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(height: DsEspacamentos.sm),
                              RegisterTermsCheckbox(
                                value: _autorizaSaude,
                                onChanged: (v) =>
                                    setState(() => _autorizaSaude = v!),
                                text: Text(
                                  'Autorizo o tratamento de meus dados de saúde e laudos médicos.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(height: DsEspacamentos.xl),
                              DsBotao(
                                label: 'Criar minha conta',
                                onPressed: _handleRegister,
                                isLoading: _isLoading,
                                variante: DsBotaoVariante.acao,
                                token: DsCores.conta,
                                icon: PhosphorIcons.userCirclePlus(),
                              ),
                              const SizedBox(height: DsEspacamentos.lg),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ), // Espaço reduzido pois o rodapé agora tem espaço próprio no Column
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

  void _showRegisterFeedback(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    final accentColor = isError
        ? DsCores.perigo.accent
        : DsCores.sucesso.accent;
    final iconData = isError
        ? PhosphorIcons.warningCircle()
        : PhosphorIcons.checkCircle();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: DsCores.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: DsCores.glassStrong,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.all(16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
