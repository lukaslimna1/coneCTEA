import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conectea/core/constants/colors.dart';
import 'package:conectea/models/app_user.dart';
import 'package:conectea/services/database_service.dart';
import 'package:conectea/features/account/profile/widgets/profile_section_header.dart';
import 'package:conectea/features/account/profile/widgets/profile_locked_field.dart';
import 'package:conectea/features/account/profile/utils/profile_string_utils.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _databaseService = DatabaseService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false;
  AppUser? _user;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _socialNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _institutionController;

  String _hasInstitution = 'Não';
  String? _selectedGender;
  String? _selectedRace;
  String? _selectedState;
  String? _selectedCity;

  // Localização Data
  List<Map<String, dynamic>> _states = [];
  List<String> _cities = [];
  bool _isLoadingCities = false;

  // Formatadores
  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  static const List<String> _genderOptions = [
    'Feminino',
    'Masculino',
    'Não binário',
    'Outro',
    'Prefiro não informar',
  ];

  static const List<String> _raceOptions = [
    'Branca',
    'Preta',
    'Parda',
    'Amarela',
    'Indígena',
    'Prefiro não informar',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _socialNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _institutionController = TextEditingController();
    _loadProfile();
    _fetchStates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _socialNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _fetchStates() async {
    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _states = data.map((s) => {
              'sigla': s['sigla'],
              'nome': s['nome'],
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar estados: $e');
    }
  }

  Future<void> _fetchCities(String stateSigla) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
    });
    try {
      final response = await http.get(
        Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$stateSigla/municipios?orderBy=nome'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _cities = data.map((c) => c['nome'].toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar cidades: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _loadProfile() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    final profile = await _databaseService.getUserProfile(authUser.id);
    if (profile != null && mounted) {
      setState(() {
        _user = profile;
        _nameController.text = profile.name;
        _socialNameController.text = profile.socialName ?? '';
        _phoneController.text = profile.phone;
        _dobController.text = profile.dateOfBirth ?? '';
        _institutionController.text = profile.institution ?? '';
        
        _hasInstitution = (profile.institution != null && profile.institution!.isNotEmpty) ? 'Sim' : 'Não';
        _selectedGender = _genderOptions.contains(profile.gender) ? profile.gender : null;
        _selectedRace = _raceOptions.contains(profile.race) ? profile.race : null;
        _selectedState = profile.state;
        _selectedCity = profile.city;
        
        _isLoading = false;
      });
      if (_selectedState != null) _fetchCities(_selectedState!);
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showSupportDialog(String field) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.alertOrange),
            const SizedBox(width: 8),
            Text('Alterar $field', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para sua segurança, campos de identificação crítica como $field não podem ser editados diretamente no aplicativo.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Entre em contato com o suporte da ConeCTEA para solicitar esta alteração.',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fechar', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              const url = 'https://wa.me/5514997728448';
              if (await canLaunchUrlString(url)) {
                await launchUrlString(url, mode: LaunchMode.externalApplication);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
            label: const Text('Falar no WhatsApp', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEditMode() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Editar Dados Pessoais',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Text(
          'Tem certeza que deseja editar seus dados? \n\nAlterações frequentes em informações de identificação podem passar por nova análise da equipe ConeCTEA.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _isEditMode = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sim, Editar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'social_name': _socialNameController.text.trim().isEmpty ? null : _socialNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'gender': _selectedGender ?? '',
        'race': _selectedRace ?? '',
        'institution': _hasInstitution == 'Sim' ? _institutionController.text.trim() : '',
        'state': _selectedState,
        'city': _selectedCity,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _databaseService.updateAnyUserProfile(_user!.id, data);

      if (mounted) {
        setState(() => _isEditMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: AppColors.statusGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
        ),
        title: Text(
          'Dados Pessoais',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          if (!_isEditMode && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _confirmEditMode,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Editar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
        ],
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Erro ao carregar perfil.'))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditMode)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Você está no modo de edição. O CPF e E-mail permanecem bloqueados por segurança.',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── SEÇÃO: DADOS PRINCIPAIS ────────────────────────────────
            const ProfileSectionHeader(title: '👤 Dados Principais'),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _nameController,
              label: 'Nome Completo*',
              icon: Icons.person_outline,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 12),

            // CPF — SEMPRE BLOQUEADO
            ProfileLockedField(
              label: 'CPF',
              value: _user!.cpf.isNotEmpty ? ProfileStringUtils.formatCpf(_user!.cpf) : '—',
              icon: Icons.badge_outlined,
              alwaysLocked: true,
              onTap: () => _showSupportDialog('CPF'),
            ),
            const SizedBox(height: 12),

            _buildInputField(
              controller: _phoneController,
              label: 'Telefone*',
              icon: Icons.phone_outlined,
              inputFormatters: [phoneMask],
              keyboardType: TextInputType.phone,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 12),

            _buildInputField(
              controller: _dobController,
              label: 'Nascimento*',
              icon: Icons.calendar_today_outlined,
              inputFormatters: [dateMask],
              keyboardType: TextInputType.datetime,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 12),

            // E-MAIL — SEMPRE BLOQUEADO
            ProfileLockedField(
              label: 'E-mail',
              value: _user!.email,
              icon: Icons.email_outlined,
              alwaysLocked: true,
              onTap: () => _showSupportDialog('E-mail'),
            ),

            const SizedBox(height: 24),

            // ─── SEÇÃO: LOCALIZAÇÃO ─────────────────────────────────────
            const ProfileSectionHeader(title: '📍 Localização'),
            const SizedBox(height: 16),

            if (_isEditMode) ...[
              _buildSearchableDropdown(
                label: 'Estado*',
                value: _selectedState,
                items: _states.map((s) => s['sigla'] as String).toList(),
                icon: Icons.map_outlined,
                onChanged: (v) {
                  setState(() {
                    _selectedState = v;
                    _selectedCity = null;
                  });
                  _fetchCities(v!);
                },
              ),
              const SizedBox(height: 12),
              _buildSearchableDropdown(
                label: 'Cidade*',
                value: _selectedCity,
                items: _cities,
                icon: Icons.location_on_outlined,
                hint: _isLoadingCities ? 'Buscando...' : 'Selecione',
                onChanged: (v) => setState(() => _selectedCity = v),
              ),
            ] else
              Column(
                children: [
                  ProfileLockedField(
                    label: 'Estado',
                    value: _user!.state ?? '—',
                    icon: Icons.map_outlined,
                  ),
                  const SizedBox(height: 12),
                  ProfileLockedField(
                    label: 'Cidade',
                    value: _user!.city ?? '—',
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // ─── SEÇÃO: DADOS COMPLEMENTARES ────────────────────────────
            const ProfileSectionHeader(title: '🧬 Dados Complementares'),
            const SizedBox(height: 16),

            _buildDropdownField<String>(
              label: 'Indicado por instituição?',
              value: _hasInstitution,
              items: const ['Não', 'Sim'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              icon: Icons.account_balance_outlined,
              onChanged: _isEditMode ? (v) => setState(() {
                _hasInstitution = v!;
                if (v == 'Não') _institutionController.clear();
              }) : null,
            ),
            if (_hasInstitution == 'Sim') ...[
              const SizedBox(height: 12),
              _buildInputField(
                controller: _institutionController,
                label: 'Nome da Instituição',
                icon: Icons.business_outlined,
                enabled: _isEditMode,
              ),
            ],
            const SizedBox(height: 12),

            _buildInputField(
              controller: _socialNameController,
              label: 'Nome Social (opcional)',
              icon: Icons.badge_outlined,
              enabled: _isEditMode,
            ),
            const SizedBox(height: 12),

            _buildDropdownField<String>(
              label: 'Gênero',
              value: _selectedGender,
              items: _genderOptions
                  .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14))))
                  .toList(),
              icon: Icons.wc_outlined,
              onChanged: _isEditMode ? (v) => setState(() => _selectedGender = v) : null,
            ),
            const SizedBox(height: 12),
            _buildDropdownField<String>(
              label: 'Raça / Cor',
              value: _selectedRace,
              items: _raceOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14))))
                  .toList(),
              icon: Icons.groups_outlined,
              onChanged: _isEditMode ? (v) => setState(() => _selectedRace = v) : null,
            ),

            const SizedBox(height: 40),

            if (_isEditMode)
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvar Alterações',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    if (!enabled) {
      return ProfileLockedField(label: label, value: controller.text.isEmpty ? '—' : controller.text, icon: icon);
    }
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: items.any((item) => item.value == value) ? value : null,
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
      ),
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    String? hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: onChanged,
      hint: Text(hint ?? 'Selecione', style: const TextStyle(fontSize: 12)),
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

}
