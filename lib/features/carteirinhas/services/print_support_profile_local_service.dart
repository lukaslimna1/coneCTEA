import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// **PrintSupportProfileDraft**
/// Modelo de dados local para o Perfil de Apoio TEA.
///
/// **Importante:**
/// - Este rascunho de dados é persistido estritamente de forma local no aparelho.
/// - Não é sincronizado ou enviado para o Supabase/bancos remotos.
/// - Contém informações sensíveis de saúde preenchidas voluntariamente pelo responsável.
/// - Por razões de privacidade (LGPD), não deve ser exibido em logs de console.
class PrintSupportProfileDraft {
  final String memberId;
  final String updatedAt;
  final String preferredName;
  final String about;
  
  // Opções de comunicação
  final bool commSpeech;
  final bool commGestures;
  final bool commPictograms;
  final bool commApps;
  final String communicationNotes;

  // Listas dinâmicas de textos
  final List<String> likes;
  final List<String> irritations;
  final List<String> abilities;
  final List<String> supportTips;
  final List<String> medications;
  final List<String> allergies;
  
  final String otherImportantInfo;

  PrintSupportProfileDraft({
    required this.memberId,
    required this.updatedAt,
    required this.preferredName,
    required this.about,
    required this.commSpeech,
    required this.commGestures,
    required this.commPictograms,
    required this.commApps,
    required this.communicationNotes,
    required this.likes,
    required this.irritations,
    required this.abilities,
    required this.supportTips,
    required this.medications,
    required this.allergies,
    required this.otherImportantInfo,
  });

  /// Instância inicial em branco de um rascunho de Perfil de Apoio para um membro.
  factory PrintSupportProfileDraft.empty(String memberId) {
    return PrintSupportProfileDraft(
      memberId: memberId,
      updatedAt: '',
      preferredName: '',
      about: '',
      commSpeech: false,
      commGestures: false,
      commPictograms: false,
      commApps: false,
      communicationNotes: '',
      likes: const [],
      irritations: const [],
      abilities: const [],
      supportTips: const [],
      medications: const [],
      allergies: const [],
      otherImportantInfo: '',
    );
  }

  /// Instancia o rascunho a partir de um mapa JSON obtido localmente.
  factory PrintSupportProfileDraft.fromJson(Map<String, dynamic> json) {
    return PrintSupportProfileDraft(
      memberId: json['member_id']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      preferredName: json['preferred_name']?.toString() ?? '',
      about: json['about']?.toString() ?? '',
      commSpeech: json['comm_speech'] == true,
      commGestures: json['comm_gestures'] == true,
      commPictograms: json['comm_pictograms'] == true,
      commApps: json['comm_apps'] == true,
      communicationNotes: json['communication_notes']?.toString() ?? '',
      likes: _toListString(json['likes']),
      irritations: _toListString(json['irritations']),
      abilities: _toListString(json['abilities']),
      supportTips: _toListString(json['support_tips']),
      medications: _toListString(json['medications']),
      allergies: _toListString(json['allergies']),
      otherImportantInfo: json['other_important_info']?.toString() ?? '',
    );
  }

  /// Converte o rascunho estruturado em um mapa JSON adequado para persistência local.
  /// Aplica a normalização dos dados (trim e remoção de strings vazias de listas).
  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId.trim(),
      'updated_at': updatedAt,
      'preferred_name': preferredName.trim(),
      'about': about.trim(),
      'comm_speech': commSpeech,
      'comm_gestures': commGestures,
      'comm_pictograms': commPictograms,
      'comm_apps': commApps,
      'communication_notes': communicationNotes.trim(),
      'likes': _normalizeList(likes),
      'irritations': _normalizeList(irritations),
      'abilities': _normalizeList(abilities),
      'support_tips': _normalizeList(supportTips),
      'medications': _normalizeList(medications),
      'allergies': _normalizeList(allergies),
      'other_important_info': otherImportantInfo.trim(),
    };
  }

  /// Verifica se há algum conteúdo voluntário inserido além do identificador do membro.
  bool get hasAnyContent {
    return preferredName.trim().isNotEmpty ||
        about.trim().isNotEmpty ||
        commSpeech ||
        commGestures ||
        commPictograms ||
        commApps ||
        communicationNotes.trim().isNotEmpty ||
        _normalizeList(likes).isNotEmpty ||
        _normalizeList(irritations).isNotEmpty ||
        _normalizeList(abilities).isNotEmpty ||
        _normalizeList(supportTips).isNotEmpty ||
        _normalizeList(medications).isNotEmpty ||
        _normalizeList(allergies).isNotEmpty ||
        otherImportantInfo.trim().isNotEmpty;
  }

  PrintSupportProfileDraft copyWith({
    String? memberId,
    String? updatedAt,
    String? preferredName,
    String? about,
    bool? commSpeech,
    bool? commGestures,
    bool? commPictograms,
    bool? commApps,
    String? communicationNotes,
    List<String>? likes,
    List<String>? irritations,
    List<String>? abilities,
    List<String>? supportTips,
    List<String>? medications,
    List<String>? allergies,
    String? otherImportantInfo,
  }) {
    return PrintSupportProfileDraft(
      memberId: memberId ?? this.memberId,
      updatedAt: updatedAt ?? this.updatedAt,
      preferredName: preferredName ?? this.preferredName,
      about: about ?? this.about,
      commSpeech: commSpeech ?? this.commSpeech,
      commGestures: commGestures ?? this.commGestures,
      commPictograms: commPictograms ?? this.commPictograms,
      commApps: commApps ?? this.commApps,
      communicationNotes: communicationNotes ?? this.communicationNotes,
      likes: likes ?? this.likes,
      irritations: irritations ?? this.irritations,
      abilities: abilities ?? this.abilities,
      supportTips: supportTips ?? this.supportTips,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      otherImportantInfo: otherImportantInfo ?? this.otherImportantInfo,
    );
  }

  // Helper para conversão segura de listas dinâmicas do JSON
  static List<String> _toListString(dynamic val) {
    if (val is List) {
      return val.map((e) => e?.toString() ?? '').toList();
    }
    return const [];
  }

  // Helper para normalização e limpeza de listas antes de persistir
  List<String> _normalizeList(List<String> list) {
    return list
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

/// **PrintSupportProfileLocalService**
/// Serviço de persistência local em SharedPreferences para o rascunho do Perfil de Apoio.
///
/// **Importante:**
/// - Nenhuma informação salva aqui é enviada a servidores ou APIs externas.
/// - O tratamento de erros de leitura/gravação é silencioso e seguro para não travar a UI.
class PrintSupportProfileLocalService {
  static const String _keyPrefix = 'conectea_print_support_profile_v1_';

  /// Obtém a chave física com base no memberId do rascunho.
  String _getPrefKey(String memberId) => '$_keyPrefix$memberId';

  /// Carrega o rascunho do Perfil de Apoio TEA a partir do aparelho.
  /// Retorna null em caso de chave inexistente, erro de leitura ou JSON corrompido.
  Future<PrintSupportProfileDraft?> loadDraft(String memberId) async {
    if (memberId.trim().isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrefKey(memberId);
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return PrintSupportProfileDraft.fromJson(decoded);
    } catch (_) {
      // Captura segura e silenciosa do erro (ex: JSON corrompido)
      return null;
    }
  }

  /// Salva ou atualiza localmente o rascunho do Perfil de Apoio TEA.
  /// Aplica a normalização dos dados e atualiza a propriedade updatedAt.
  Future<void> saveDraft(PrintSupportProfileDraft draft) async {
    final mId = draft.memberId.trim();
    if (mId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrefKey(mId);

      // Instancia um clone atualizando o timestamp de modificação
      final updatedDraft = draft.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );

      final jsonString = jsonEncode(updatedDraft.toJson());
      await prefs.setString(key, jsonString);
    } catch (_) {
      // Captura silenciosa e segura sem quebrar o fluxo do app
    }
  }

  /// Exclui permanentemente o rascunho do Perfil de Apoio de um membro específico.
  Future<void> deleteDraft(String memberId) async {
    if (memberId.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrefKey(memberId);
      await prefs.remove(key);
    } catch (_) {
      // Silencioso em caso de falha de remoção
    }
  }

  /// Verifica se existe algum rascunho local persistido para o membro fornecido.
  Future<bool> hasDraft(String memberId) async {
    if (memberId.trim().isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrefKey(memberId);
      return prefs.containsKey(key);
    } catch (_) {
      return false;
    }
  }
}
