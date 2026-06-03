import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:conectea/core/design_system_v2/design_system_v2.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/features/carteirinhas/services/print_support_profile_local_service.dart';



/// **PrintSupportProfileSheet**
/// Diálogo modal bottom sheet que permite ao responsável preencher
/// visualmente as informações que constituem o Perfil de Apoio TEA.
class PrintSupportProfileSheet extends StatefulWidget {
  final Member member;

  const PrintSupportProfileSheet({
    super.key,
    required this.member,
  });

  /// Método estático facilitador para exibir o bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required Member member,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return PrintSupportProfileSheet(member: member);
      },
    );
  }

  @override
  State<PrintSupportProfileSheet> createState() => _PrintSupportProfileSheetState();
}

class _PrintSupportProfileSheetState extends State<PrintSupportProfileSheet> {
  // Controle de carregamento e servico de persistencia local
  bool _isLoading = true;
  bool _isSaving = false;
  final _localService = PrintSupportProfileLocalService();

  // Controllers locais temporarios para digitacao nos testes
  late final TextEditingController _nicknameController;
  late final TextEditingController _aboutMeController;
  late final TextEditingController _communicationObsController;
  late final TextEditingController _usefulInfoController;

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

    super.dispose();
  }

  /// Carrega as informacoes locais salvas e preenche o formulario
  Future<void> _loadLocalDraft() async {
    try {
      final draft = await _localService.loadDraft(widget.member.id);
      if (draft != null && mounted) {
        setState(() {
          _nicknameController.text = draft.preferredName;
          _aboutMeController.text = draft.about;
          _commSpeech = draft.commSpeech;
          _commGestures = draft.commGestures;
          _commPictograms = draft.commPictograms;
          _commApps = draft.commApps;
          _communicationObsController.text = draft.communicationNotes;

          _fillControllers(_likesControllers, draft.likes);
          _fillControllers(_dislikesControllers, draft.irritations);
          _fillControllers(_abilitiesControllers, draft.abilities);
          _fillControllers(_howToHelpControllers, draft.supportTips);
          _fillControllers(_medicationsControllers, draft.medications);
          _fillControllers(_allergiesControllers, draft.allergies);

          _usefulInfoController.text = draft.otherImportantInfo;
        });
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

  /// Constroi um objeto de rascunho com o estado atual do formulario
  PrintSupportProfileDraft _buildDraftFromCurrentForm() {
    return PrintSupportProfileDraft(
      memberId: widget.member.id,
      updatedAt: '', // Atualizado internamente no servico
      preferredName: _nicknameController.text,
      about: _aboutMeController.text,
      commSpeech: _commSpeech,
      commGestures: _commGestures,
      commPictograms: _commPictograms,
      commApps: _commApps,
      communicationNotes: _communicationObsController.text,
      likes: _likesControllers.map((c) => c.text).toList(),
      irritations: _dislikesControllers.map((c) => c.text).toList(),
      abilities: _abilitiesControllers.map((c) => c.text).toList(),
      supportTips: _howToHelpControllers.map((c) => c.text).toList(),
      medications: _medicationsControllers.map((c) => c.text).toList(),
      allergies: _allergiesControllers.map((c) => c.text).toList(),
      otherImportantInfo: _usefulInfoController.text,
    );
  }

  /// Trata a acao de salvar ou remover o rascunho antes de fechar a Bottom Sheet
  Future<void> _handleContinue() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

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

    if (success && mounted) {
      Navigator.pop(context, true);
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
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
          ),
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
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: DsCores.privacidade.softBackground.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(DsRaios.card),
                          border: Border.all(
                            color: DsCores.privacidade.border.withValues(alpha: 0.1),
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
                      // MOLDURA DA FOTO (Placeholder Visual)
                      // ==========================================
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DsCores.surfaceElevated.withValues(alpha: 0.4),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                PhosphorIconsRegular.camera,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Botão/Rótulo de foto desabilitado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Adicionar Foto (Em breve)',
                                style: DsTipografia.caption.copyWith(
                                  color: DsCores.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Campo: Como gosto de ser chamado(a)
                      DsInput(
                        label: 'Como gosto de ser chamado(a)',
                        controller: _nicknameController,
                        hint: 'Ex: Dudu, Cacá, etc.',
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // BLOCO 1 — SOBRE MIM (Multilinha livre)
                      // ==========================================
                      DsCard(
                        showTopAccent: true,
                        accentColor: DsCores.conta.accent,
                        borderColor: DsCores.conta.border,
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(16.0),
                        child: DsInput(
                          label: 'Sobre mim',
                          controller: _aboutMeController,
                          hint: 'Escreva um resumo sobre a personalidade e características marcantes da pessoa.',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // BLOCO 2 — COMO ME COMUNICO
                      // ==========================================
                      DsCard(
                        showTopAccent: true,
                        accentColor: DsCores.comunicacao.accent,
                        borderColor: DsCores.comunicacao.border,
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.chatsTeardrop,
                                  color: DsCores.comunicacao.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Como me comunico',
                                  style: DsTipografia.cardTitle.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: DsCores.comunicacao.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DsCheckbox(
                              value: _commSpeech,
                              onChanged: (val) => setState(() => _commSpeech = val ?? false),
                              label: _buildCheckboxLabel('Fala'),
                              token: DsCores.sucesso,
                            ),
                            DsCheckbox(
                              value: _commGestures,
                              onChanged: (val) => setState(() => _commGestures = val ?? false),
                              label: _buildCheckboxLabel('Gestos / expressões'),
                              token: DsCores.sucesso,
                            ),
                            DsCheckbox(
                              value: _commPictograms,
                              onChanged: (val) => setState(() => _commPictograms = val ?? false),
                              label: _buildCheckboxLabel('Figuras / pictogramas'),
                              token: DsCores.sucesso,
                            ),
                            DsCheckbox(
                              value: _commApps,
                              onChanged: (val) => setState(() => _commApps = val ?? false),
                              label: _buildCheckboxLabel('Dispositivos / aplicativos'),
                              token: DsCores.sucesso,
                            ),
                            const SizedBox(height: 16),
                            DsInput(
                              label: 'Outras formas / observações',
                              controller: _communicationObsController,
                              hint: 'Ex: usa prancha de comunicação alternativa...',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // BLOCO 3 — COISAS QUE GOSTO (Lista Dinâmica)
                      // ==========================================
                      DsCard(
                        showTopAccent: true,
                        accentColor: DsCores.sucesso.accent,
                        borderColor: DsCores.sucesso.border,
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDynamicListSection(
                          title: 'Coisas que eu gosto',
                          titleColor: DsCores.sucesso.accent,
                          titleIcon: PhosphorIconsRegular.smiley,
                          controllers: _likesControllers,
                          hint: 'Ex: dinossauros, massinha, abraço apertado...',
                          onAdd: () {
                            setState(() {
                              _likesControllers.add(TextEditingController());
                            });
                          },
                          onRemove: (idx) {
                            setState(() {
                              final controller = _likesControllers.removeAt(idx);
                              controller.dispose();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // BLOCO 4 — COISAS QUE ME IRRITAM (Lista Dinâmica)
                      // ==========================================
                      DsCard(
                        showTopAccent: true,
                        accentColor: DsCores.alerta.accent,
                        borderColor: DsCores.alerta.border,
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDynamicListSection(
                          title: 'Coisas que me irritam',
                          titleColor: DsCores.alerta.accent,
                          titleIcon: PhosphorIconsRegular.smileySad,
                          controllers: _dislikesControllers,
                          hint: 'Ex: barulhos imprevistos, luz forte, ser interrompido...',
                          onAdd: () {
                            setState(() {
                              _dislikesControllers.add(TextEditingController());
                            });
                          },
                          onRemove: (idx) {
                            setState(() {
                              final controller = _dislikesControllers.removeAt(idx);
                              controller.dispose();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // BLOCO 5 — COISAS QUE POSSO FAZER (Lista Dinâmica)
                      // ==========================================
                      DsCard(
                        showTopAccent: true,
                        accentColor: DsCores.sucesso.accent,
                        borderColor: DsCores.sucesso.border,
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDynamicListSection(
                          title: 'Coisas que eu posso fazer',
                          titleColor: DsCores.sucesso.accent,
                          titleIcon: PhosphorIconsRegular.star,
                          controllers: _abilitiesControllers,
                          hint: 'Ex: ir ao banheiro sozinho, calçar sapatos...',
                          onAdd: () {
                            setState(() {
                              _abilitiesControllers.add(TextEditingController());
                            });
                          },
                          onRemove: (idx) {
                            setState(() {
                              final controller = _abilitiesControllers.removeAt(idx);
                              controller.dispose();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // BLOCO 6 — COMO ME AJUDAR (Lista Dinâmica)
                      // ==========================================
                      DsCard(
                        showTopAccent: true,
                        accentColor: DsCores.suporte.accent,
                        borderColor: DsCores.suporte.border,
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDynamicListSection(
                          title: 'Como você pode me ajudar',
                          titleColor: DsCores.suporte.accent,
                          titleIcon: Icons.favorite_border_rounded,
                          controllers: _howToHelpControllers,
                          hint: 'Ex: falar pausadamente, oferecer fone abafador...',
                          onAdd: () {
                            setState(() {
                              _howToHelpControllers.add(TextEditingController());
                            });
                          },
                          onRemove: (idx) {
                            setState(() {
                              final controller = _howToHelpControllers.removeAt(idx);
                              controller.dispose();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // BLOCO 7 — INFORMAÇÕES ÚTEIS (Reorganizado)
                      // ==========================================
                      DsCard(
                        showTopAccent: true,
                        accentColor: DsCores.dadosProtegidos.accent,
                        borderColor: DsCores.dadosProtegidos.border,
                        backgroundColor: DsCores.surfaceElevated.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.shieldWarning,
                                  color: DsCores.dadosProtegidos.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Informações úteis',
                                  style: DsTipografia.cardTitle.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: DsCores.dadosProtegidos.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                               'Exemplo: medicações, alergias, restrições, cuidados e outras informações importantes que o usuário titular, família ou responsável desejar incluir.',
                              style: DsTipografia.caption.copyWith(
                                color: DsCores.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 1. Lista Medicações
                            _buildDynamicListSection(
                              title: 'Medicações',
                              titleColor: DsCores.dadosProtegidos.accent,
                              titleIcon: PhosphorIconsRegular.pill,
                              controllers: _medicationsControllers,
                              hint: 'Ex: Paracetamol 500mg de 8/8h...',
                              onAdd: () {
                                setState(() {
                                  _medicationsControllers.add(TextEditingController());
                                });
                              },
                              onRemove: (idx) {
                                setState(() {
                                  final controller = _medicationsControllers.removeAt(idx);
                                  controller.dispose();
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // 2. Lista Alergias
                            _buildDynamicListSection(
                              title: 'Alergias',
                              titleColor: DsCores.alerta.accent,
                              titleIcon: PhosphorIconsRegular.warning,
                              controllers: _allergiesControllers,
                              hint: 'Ex: APLV, Dipirona, poeira...',
                              onAdd: () {
                                setState(() {
                                  _allergiesControllers.add(TextEditingController());
                                });
                              },
                              onRemove: (idx) {
                                setState(() {
                                  final controller = _allergiesControllers.removeAt(idx);
                                  controller.dispose();
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // 3. Outras informações (Multilinha maior)
                            DsInput(
                              label: 'Outras informações importantes',
                              controller: _usefulInfoController,
                              hint: 'Descreva outras recomendações importantes de cuidados diários, rotinas ou particularidades.',
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Texto Inspirador final
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        onPressed: (_isLoading || _isSaving) ? null : () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DsBotao(
                        label: 'Continuar',
                        variante: DsBotaoVariante.acao,
                        token: DsCores.sucesso,
                        onPressed: (_isLoading || _isSaving) ? null : _handleContinue,
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
            // Botão Adicionar Item discreto com ícone de "+"
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
                    padding: const EdgeInsets.only(top: 24.0), // Alinha com a caixa de texto
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

  Widget _buildCheckboxLabel(String text) {
    return Text(
      text,
      style: DsTipografia.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}
