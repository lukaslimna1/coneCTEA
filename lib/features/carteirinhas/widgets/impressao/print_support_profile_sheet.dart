import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/features/carteirinhas/services/print_support_profile_local_service.dart';

/// **PrintSupportProfileSheet**
/// Diálogo modal bottom sheet que permite ao responsável preencher
/// visualmente as informações que constituem o Perfil de Apoio TEA.

class PrintSupportProfileResult {
  final bool continuePrint;
  final Uint8List? photoBytes;
  PrintSupportProfileResult(this.continuePrint, this.photoBytes);
}

class PrintSupportProfileSheet extends StatefulWidget {
  final Member member;

  const PrintSupportProfileSheet({super.key, required this.member});

  /// Método estático facilitador para exibir o bottom sheet.
  static Future<PrintSupportProfileResult?> show(
    BuildContext context, {
    required Member member,
  }) {
    return showModalBottomSheet<PrintSupportProfileResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrintSupportProfileSheet(member: member);
      },
    );
  }

  @override
  State<PrintSupportProfileSheet> createState() =>
      _PrintSupportProfileSheetState();
}

class _PrintSupportProfileSheetState extends State<PrintSupportProfileSheet> {
  // Controle de carregamento e servico de persistencia local
  bool _isLoading = true;
  bool _isSaving = false;
  final _localService = PrintSupportProfileLocalService();

  // Flags de inclusão
  bool _includePreferredName = false;
  bool _includeAbout = false;
  bool _includeCommunication = false;
  bool _includeLikes = false;
  bool _includeIrritations = false;
  bool _includeCuriosities = false;
  bool _includeSupportTips = false;
  bool _includeSupportLevel = false;
  bool _includeFoodLikes = false;
  bool _includeFoodDislikes = false;
  bool _includeMedications = false;
  bool _includeAllergies = false;
  bool _includeOtherImportantInfo = false;

  // Controllers locais temporarios para digitacao nos testes
  late final TextEditingController _nicknameController;
  late final TextEditingController _aboutMeController;
  late final TextEditingController _communicationObsController;
  late final TextEditingController _usefulInfoController;

  // Dropdown e novas listas
  String? _supportLevel;
  final List<TextEditingController> _foodLikesControllers = [];
  final List<TextEditingController> _foodDislikesControllers = [];

  // Listas de controllers para campos dinamicos curtos
  final List<TextEditingController> _likesControllers = [];
  final List<TextEditingController> _dislikesControllers = [];
  final List<TextEditingController> _abilitiesControllers = [];
  final List<TextEditingController> _howToHelpControllers = [];
  final List<TextEditingController> _medicationsControllers = [];
  final List<TextEditingController> _allergiesControllers = [];

  // Estado local para checkboxes de comunicacao
  bool _commSpeech = false;
  bool _commGestures = false;
  bool _commPictograms = false;
  bool _commApps = false;
  Uint8List? _supportPhotoBytes;
  String? _localPhotoPath;
  // Sinaliza que o usuário tocou em "Remover foto" nesta sessão.
  // A exclusão física do arquivo só ocorre ao confirmar (Continuar).
  bool _photoRemovedByUser = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        final dir = await getApplicationSupportDirectory();
        final conecteaDir = Directory(
          '${dir.path}/conectea/print_support_profile',
        );
        if (!await conecteaDir.exists()) {
          await conecteaDir.create(recursive: true);
        }

        final newFileName = '${const Uuid().v4()}.jpg';
        final newFilePath = '${conecteaDir.path}/$newFileName';
        final savedFile = await File(pickedFile.path).copy(newFilePath);

        final oldPath = _localPhotoPath;
        if (oldPath != null && oldPath.isNotEmpty) {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }

        if (mounted) {
          setState(() {
            _supportPhotoBytes = bytes;
            _localPhotoPath = savedFile.path;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar a imagem.')),
        );
      }
    }
  }

  Future<void> _loadExistingPhoto(String path) async {
    if (path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (mounted) {
            setState(() {
              _supportPhotoBytes = bytes;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _localPhotoPath = null;
            });
          }
        }
      } catch (_) {}
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.camera),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.image),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _aboutMeController = TextEditingController();
    _communicationObsController = TextEditingController();
    _usefulInfoController = TextEditingController();

    // Começar cada lista com 1 campo vazio
    _likesControllers.add(TextEditingController());
    _dislikesControllers.add(TextEditingController());
    _abilitiesControllers.add(TextEditingController());
    _howToHelpControllers.add(TextEditingController());
    _medicationsControllers.add(TextEditingController());
    _allergiesControllers.add(TextEditingController());
    _foodLikesControllers.add(TextEditingController());
    _foodDislikesControllers.add(TextEditingController());

    // Carrega o rascunho localmente no início
    _loadLocalDraft();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _aboutMeController.dispose();
    _communicationObsController.dispose();
    _usefulInfoController.dispose();

    // Dispose de todos os controllers das listas
    for (final c in _likesControllers) {
      c.dispose();
    }
    for (final c in _dislikesControllers) {
      c.dispose();
    }
    for (final c in _abilitiesControllers) {
      c.dispose();
    }
    for (final c in _howToHelpControllers) {
      c.dispose();
    }
    for (final c in _medicationsControllers) {
      c.dispose();
    }
    for (final c in _allergiesControllers) {
      c.dispose();
    }
    for (final c in _foodLikesControllers) {
      c.dispose();
    }
    for (final c in _foodDislikesControllers) {
      c.dispose();
    }

    super.dispose();
  }

  /// Carrega as informacoes locais salvas e preenche o formulario
  Future<void> _loadLocalDraft() async {
    try {
      final draft = await _localService.loadDraft(widget.member.id);
      if (draft != null && mounted) {
        setState(() {
          _localPhotoPath = draft.localPhotoPath;
          _nicknameController.text = draft.preferredName;
          _aboutMeController.text = draft.about;
          _commSpeech = draft.commSpeech;
          _commGestures = draft.commGestures;
          _commPictograms = draft.commPictograms;
          _commApps = draft.commApps;
          _communicationObsController.text = draft.communicationNotes;

          _includePreferredName = draft.includePreferredName;
          _includeAbout = draft.includeAbout;
          _includeCommunication = draft.includeCommunication;
          _includeLikes = draft.includeLikes;
          _includeIrritations = draft.includeIrritations;
          _includeCuriosities = draft.includeCuriosities;
          _includeSupportTips = draft.includeSupportTips;
          _includeSupportLevel = draft.includeSupportLevel;
          _includeFoodLikes = draft.includeFoodLikes;
          _includeFoodDislikes = draft.includeFoodDislikes;
          _includeMedications = draft.includeMedications;
          _includeAllergies = draft.includeAllergies;
          _includeOtherImportantInfo = draft.includeOtherImportantInfo;

          _supportLevel = draft.supportLevel.isNotEmpty
              ? draft.supportLevel
              : null;

          _fillControllers(_likesControllers, draft.likes);
          _fillControllers(_dislikesControllers, draft.irritations);
          _fillControllers(_abilitiesControllers, draft.abilities);
          _fillControllers(_howToHelpControllers, draft.supportTips);
          _fillControllers(_medicationsControllers, draft.medications);
          _fillControllers(_allergiesControllers, draft.allergies);
          _fillControllers(_foodLikesControllers, draft.foodLikes);
          _fillControllers(_foodDislikesControllers, draft.foodDislikes);

          _usefulInfoController.text = draft.otherImportantInfo;
        });
        final path = draft.localPhotoPath;
        if (path != null) {
          await _loadExistingPhoto(path);
        }
      }
    } catch (_) {
      // Captura silenciosa e segura
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Auxiliar para substituir os controllers de listas de forma segura
  void _fillControllers(List<TextEditingController> list, List<String> values) {
    for (final c in list) {
      c.dispose();
    }
    list.clear();
    if (values.isEmpty) {
      list.add(TextEditingController());
    } else {
      for (final val in values) {
        list.add(TextEditingController(text: val));
      }
    }
  }

  /// Constroi um objeto de rascunho com o estado atual do formulario.
  /// Se o usuário removeu a foto nesta sessão, localPhotoPath é enviado como
  /// null para que o draft salvo não referencie o arquivo anterior.
  PrintSupportProfileDraft _buildDraftFromCurrentForm() {
    return PrintSupportProfileDraft(
      memberId: widget.member.id,
      updatedAt: '', // Atualizado internamente no servico
      preferredName: _nicknameController.text,
      about: _aboutMeController.text,
      includePreferredName: _includePreferredName,
      includeAbout: _includeAbout,
      includeCommunication: _includeCommunication,
      includeLikes: _includeLikes,
      includeIrritations: _includeIrritations,
      includeCuriosities: _includeCuriosities,
      includeSupportTips: _includeSupportTips,
      includeSupportLevel: _includeSupportLevel,
      includeFoodLikes: _includeFoodLikes,
      includeFoodDislikes: _includeFoodDislikes,
      includeMedications: _includeMedications,
      includeAllergies: _includeAllergies,
      includeOtherImportantInfo: _includeOtherImportantInfo,
      commSpeech: _commSpeech,
      commGestures: _commGestures,
      commPictograms: _commPictograms,
      commApps: _commApps,
      communicationNotes: _communicationObsController.text,
      supportLevel: _supportLevel ?? '',
      foodLikes: _foodLikesControllers.map((c) => c.text).toList(),
      foodDislikes: _foodDislikesControllers.map((c) => c.text).toList(),
      likes: _likesControllers.map((c) => c.text).toList(),
      irritations: _dislikesControllers.map((c) => c.text).toList(),
      abilities: _abilitiesControllers.map((c) => c.text).toList(),
      supportTips: _howToHelpControllers.map((c) => c.text).toList(),
      medications: _medicationsControllers.map((c) => c.text).toList(),
      allergies: _allergiesControllers.map((c) => c.text).toList(),
      otherImportantInfo: _usefulInfoController.text,
      // Se o usuário removeu a foto nesta sessão, não propagar o path anterior.
      localPhotoPath: _photoRemovedByUser ? null : _localPhotoPath,
    );
  }

  /// Exclui o arquivo físico da foto anterior de forma silenciosa.
  /// Chamado somente APÓS o saveDraft/deleteDraft bem-sucedido,
  /// garantindo que o arquivo só é removido se o novo draft já foi persistido.
  Future<void> _deletePhysicalPhotoSilently(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Falha silenciosa: não bloquear o usuário e não logar o path.
    }
  }

  /// Trata a acao de salvar ou remover o rascunho antes de fechar a Bottom Sheet.
  /// Ordem transacional garantida:
  /// 1. Constrói o draft com localPhotoPath: null (se foto removida).
  /// 2. Persiste o draft.
  /// 3. Somente após persistência bem-sucedida, exclui o arquivo físico anterior.
  Future<void> _handleContinue() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // Captura o caminho anterior antes de construir o draft, para que,
    // se a persistência falhar, o arquivo físico seja preservado.
    final String? stalePhotoPath =
        _photoRemovedByUser ? _localPhotoPath : null;

    final draft = _buildDraftFromCurrentForm();
    bool success = false;

    try {
      if (draft.hasAnyContent) {
        await _localService.saveDraft(draft);
      } else {
        await _localService.deleteDraft(widget.member.id);
      }
      success = true;
    } catch (_) {
      // Falha silenciosa: sem logar dados pessoais, exibindo snackbar generica
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o rascunho local agora.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    if (success) {
      // Draft persistido com sucesso: agora é seguro limpar o estado e
      // tentar excluir o arquivo físico anterior.
      if (stalePhotoPath != null && stalePhotoPath.isNotEmpty) {
        if (mounted) {
          setState(() {
            _localPhotoPath = null;
            _photoRemovedByUser = false;
          });
        }
        await _deletePhysicalPhotoSilently(stalePhotoPath);
      }

      if (mounted) {
        Navigator.pop(
          context,
          PrintSupportProfileResult(true, _supportPhotoBytes),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      decoration: BoxDecoration(
        color: DsCores.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DsRaios.card),
          topRight: Radius.circular(DsRaios.card),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alça de arraste visual (Drag Handle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 20, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Área de Conteúdo Rolável
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho e Título
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsBold.heart,
                              color: DsCores.carteirinha.accent,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Perfil de Apoio TEA',
                                style: DsTipografia.sectionTitle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Subtítulo descritivo
                        Text(
                          'Preencha informações opcionais para ajudar escola, cuidadores, familiares, eventos ou consultas a entenderem melhor como apoiar a pessoa.',
                          style: DsTipografia.infoBody,
                        ),
                        const SizedBox(height: 16),

                        // Bloco Informativo de Privacidade e Segurança
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: DsCores.privacidade.softBackground
                                .withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(DsRaios.card),
                            border: Border.all(
                              color: DsCores.privacidade.border.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                PhosphorIconsRegular.shieldCheck,
                                color: DsCores.privacidade.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Essas informações ficam salvas apenas neste aparelho e não são enviadas para o banco de dados. Preencha apenas o que fizer sentido. Campos vazios não serão incluídos na versão impressa.',
                                  style: DsTipografia.caption.copyWith(
                                    color: DsCores.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ==========================================
                        // MOLDURA DA FOTO
                        // ==========================================
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: DsCores.surfaceElevated.withValues(
                                      alpha: 0.4,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                    image: _supportPhotoBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(
                                              _supportPhotoBytes!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _supportPhotoBytes == null
                                      ? Icon(
                                          PhosphorIconsRegular.camera,
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          size: 36,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_supportPhotoBytes == null)
                                GestureDetector(
                                  onTap: _showImagePickerOptions,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 6.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DsCores.carteirinha.accent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Adicionar Foto',
                                      style: DsTipografia.caption.copyWith(
                                        color: DsCores.carteirinha.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: _showImagePickerOptions,
                                      child: Text(
                                        'Trocar',
                                        style: DsTipografia.caption.copyWith(
                                          color: DsCores.carteirinha.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _supportPhotoBytes = null;
                                          // Marca que o usuário solicitou remoção.
                                          // O arquivo físico só será excluído ao confirmar (Continuar).
                                          _photoRemovedByUser = true;
                                        });
                                      },
                                      child: Text(
                                        'Remover',
                                        style: DsTipografia.caption.copyWith(
                                          color: DsCores.perigo.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        _buildSectionBlock(
                          isChecked: _includePreferredName,
                          onChanged: (val) => setState(
                            () => _includePreferredName = val ?? false,
                          ),
                          title: 'Como gosto de ser chamado(a)',
                          child: DsInput(
                            label: 'Nome preferido',
                            controller: _nicknameController,
                            hint: 'Ex: Dudu, Cacá, etc.',
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeSupportLevel,
                          onChanged: (val) => setState(
                            () => _includeSupportLevel = val ?? false,
                          ),
                          title: 'Nível de suporte',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecione o nível de suporte, se desejar informar.',
                                style: DsTipografia.bodySmall.copyWith(
                                  color: DsCores.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DsDropdown(
                                label: 'Nível de suporte',
                                value: _supportLevel,
                                items: const [
                                  'Não informado',
                                  'Nível 1 de suporte',
                                  'Nível 2 de suporte',
                                  'Nível 3 de suporte',
                                ],
                                onChanged: (val) => setState(
                                  () => _supportLevel = (val == 'Não informado')
                                      ? ''
                                      : (val ?? ''),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeCommunication,
                          onChanged: (val) => setState(
                            () => _includeCommunication = val ?? false,
                          ),
                          title: 'Como me comunico',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DsCheckbox(
                                value: _commSpeech,
                                onChanged: (val) =>
                                    setState(() => _commSpeech = val ?? false),
                                label: _buildCheckboxLabel('Fala'),
                                token: DsCores.sucesso,
                              ),
                              DsCheckbox(
                                value: _commGestures,
                                onChanged: (val) => setState(
                                  () => _commGestures = val ?? false,
                                ),
                                label: _buildCheckboxLabel(
                                  'Gestos / expressões',
                                ),
                                token: DsCores.sucesso,
                              ),
                              DsCheckbox(
                                value: _commPictograms,
                                onChanged: (val) => setState(
                                  () => _commPictograms = val ?? false,
                                ),
                                label: _buildCheckboxLabel(
                                  'Figuras / pictogramas',
                                ),
                                token: DsCores.sucesso,
                              ),
                              DsCheckbox(
                                value: _commApps,
                                onChanged: (val) =>
                                    setState(() => _commApps = val ?? false),
                                label: _buildCheckboxLabel(
                                  'Dispositivos / aplicativos',
                                ),
                                token: DsCores.sucesso,
                              ),
                              const SizedBox(height: 16),
                              DsInput(
                                label: 'Outras formas / observações',
                                controller: _communicationObsController,
                                hint:
                                    'Ex: usa prancha de comunicação alternativa...',
                              ),
                            ],
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeAbout,
                          onChanged: (val) =>
                              setState(() => _includeAbout = val ?? false),
                          title: 'Sobre mim',
                          child: DsInput(
                            label: 'Resumo sobre mim',
                            controller: _aboutMeController,
                            hint:
                                'Escreva um resumo sobre a personalidade e características marcantes da pessoa.',
                            maxLines: 3,
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeCuriosities,
                          onChanged: (val) => setState(
                            () => _includeCuriosities = val ?? false,
                          ),
                          title: 'Curiosidades sobre mim',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _abilitiesControllers,
                            hint:
                                'Ex: sei montar cubo mágico, adoro dinossauros...',
                            onAdd: () => setState(
                              () => _abilitiesControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _abilitiesControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeLikes,
                          onChanged: (val) =>
                              setState(() => _includeLikes = val ?? false),
                          title: 'Coisas que eu gosto',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _likesControllers,
                            hint:
                                'Ex: dinossauros, massinha, abraço apertado...',
                            onAdd: () => setState(
                              () => _likesControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _likesControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeIrritations,
                          onChanged: (val) => setState(
                            () => _includeIrritations = val ?? false,
                          ),
                          title: 'Coisas que me irritam',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _dislikesControllers,
                            hint: 'Ex: barulho alto, lugares muito cheios...',
                            onAdd: () => setState(
                              () => _dislikesControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _dislikesControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeFoodLikes,
                          onChanged: (val) =>
                              setState(() => _includeFoodLikes = val ?? false),
                          title: 'Comidas que eu gosto',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _foodLikesControllers,
                            hint: 'Use frases curtas para facilitar a leitura.',
                            onAdd: () => setState(
                              () => _foodLikesControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _foodLikesControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeFoodDislikes,
                          onChanged: (val) => setState(
                            () => _includeFoodDislikes = val ?? false,
                          ),
                          title: 'Comidas que eu não gosto / que me incomodam',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _foodDislikesControllers,
                            hint: 'Use frases curtas para facilitar a leitura.',
                            onAdd: () => setState(
                              () => _foodDislikesControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _foodDislikesControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeSupportTips,
                          onChanged: (val) => setState(
                            () => _includeSupportTips = val ?? false,
                          ),
                          title: 'Como você pode me ajudar',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _howToHelpControllers,
                            hint:
                                'Ex: fale de forma clara, evite me tocar de surpresa...',
                            onAdd: () => setState(
                              () => _howToHelpControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _howToHelpControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeMedications,
                          onChanged: (val) => setState(
                            () => _includeMedications = val ?? false,
                          ),
                          title: 'Medicações',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _medicationsControllers,
                            hint: 'Ex: Paracetamol 500mg de 8/8h...',
                            onAdd: () => setState(
                              () => _medicationsControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _medicationsControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeAllergies,
                          onChanged: (val) =>
                              setState(() => _includeAllergies = val ?? false),
                          title: 'Alergias',
                          child: _buildDynamicListSection(
                            title: '',
                            controllers: _allergiesControllers,
                            hint: 'Ex: APLV, Dipirona, poeira...',
                            onAdd: () => setState(
                              () => _allergiesControllers.add(
                                TextEditingController(),
                              ),
                            ),
                            onRemove: (idx) => setState(() {
                              final c = _allergiesControllers.removeAt(idx);
                              c.dispose();
                            }),
                          ),
                        ),

                        _buildSectionBlock(
                          isChecked: _includeOtherImportantInfo,
                          onChanged: (val) => setState(
                            () => _includeOtherImportantInfo = val ?? false,
                          ),
                          title: 'Outras informações importantes',
                          child: DsInput(
                            label: 'Observações finais',
                            controller: _usefulInfoController,
                            hint:
                                'Descreva outras recomendações importantes de cuidados diários, rotinas ou particularidades.',
                            maxLines: 4,
                          ),
                        ),
                        // Texto Inspirador final
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              '“Cada pessoa é única. Pequenas adaptações fazem uma grande diferença.”',
                              textAlign: TextAlign.center,
                              style: DsTipografia.caption.copyWith(
                                color: DsCores.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

              // ==========================================
              // BOTÕES DE AÇÃO FIXOS NO RODAPÉ
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DsBotao(
                        label: 'Voltar',
                        variante: DsBotaoVariante.secundario,
                        onPressed: (_isLoading || _isSaving)
                            ? null
                            : () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DsBotao(
                        label: 'Continuar',
                        variante: DsBotaoVariante.acao,
                        token: DsCores.sucesso,
                        onPressed: (_isLoading || _isSaving)
                            ? null
                            : _handleContinue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicListSection({
    required String title,
    required List<TextEditingController> controllers,
    required String hint,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    Color? titleColor,
    IconData? titleIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(
                        titleIcon,
                        color: titleColor ?? DsCores.textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: DsTipografia.cardTitle.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor ?? DsCores.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: DsCores.sucesso.accent,
                  size: 22,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: 'Adicionar item',
              ),
            ],
          ),
          const SizedBox(height: 8),
        ] else ...[
          // Title empty, just show Add button top right aligned
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onAdd,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: DsCores.sucesso.accent,
                size: 22,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: 'Adicionar item',
            ),
          ),
          const SizedBox(height: 8),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DsInput(
                    label: 'Item ${index + 1}',
                    controller: controllers[index],
                    hint: hint,
                    maxLines: 1,
                  ),
                ),
                // Exibe remover apenas se houver mais de 1 item
                if (controllers.length > 1) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 24.0,
                    ), // Alinha com a caixa de texto
                    child: IconButton(
                      onPressed: () => onRemove(index),
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        color: DsCores.perigo.accent,
                        size: 22,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      tooltip: 'Remover item',
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionBlock({
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isChecked
            ? DsCores.surfaceElevated.withValues(alpha: 0.25)
            : DsCores.surface,
        border: Border.all(
          color: isChecked
              ? DsCores.sucesso.accent.withValues(alpha: 0.4)
              : DsCores.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: DsCheckbox(
              value: isChecked,
              onChanged: onChanged,
              label: _buildCheckboxLabel(title),
            ),
          ),
          if (isChecked) ...[
            const Divider(height: 1, color: DsCores.border),
            Padding(padding: const EdgeInsets.all(16.0), child: child),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckboxLabel(String text) {
    return Text(
      text,
      style: DsTipografia.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: DsCores.textPrimary,
      ),
    );
  }
}
