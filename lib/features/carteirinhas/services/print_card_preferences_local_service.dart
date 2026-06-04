import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/impressao/print_card_options.dart';
import '../models/impressao/print_card_request.dart';

class PrintCardPreferencesDraft {
  final PrintCardOptions options;
  final List<PrintContactInfo> extraResponsibles;
  final List<PrintContactInfo> extraEmergencyContacts;
  final String? bloodTypeOverride;
  final String? phoneOverride;
  final String? cityUfOverride;
  final String? raceColorOverride;
  final String? genderOverride;
  final String? cidOverride;
  final String? responsibleNameOverride;
  final String? responsiblePhoneOverride;
  final String? emergencyNameOverride;
  final String? emergencyPhoneOverride;
  final String updatedAt;

  PrintCardPreferencesDraft({
    required this.options,
    required this.extraResponsibles,
    required this.extraEmergencyContacts,
    this.bloodTypeOverride,
    this.phoneOverride,
    this.cityUfOverride,
    this.raceColorOverride,
    this.genderOverride,
    this.cidOverride,
    this.responsibleNameOverride,
    this.responsiblePhoneOverride,
    this.emergencyNameOverride,
    this.emergencyPhoneOverride,
    required this.updatedAt,
  });

  factory PrintCardPreferencesDraft.fromJson(Map<String, dynamic> json) {
    return PrintCardPreferencesDraft(
      options: json['options'] != null
          ? PrintCardOptions.fromJson(json['options'] as Map<String, dynamic>)
          : const PrintCardOptions(
              includeBirthDateAndAge: false,
              includeMaskedCpf: false,
              includeBloodType: false,
              includeCid: false,
              includePhone: false,
              includeCityUf: false,
              includeResponsible: false,
              includeEmergencyContacts: false,
              includeRaceColor: false,
              includeGender: false,
              includeProfile: false,
            ),
      extraResponsibles: (json['extraResponsibles'] as List<dynamic>?)
              ?.map((e) => PrintContactInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extraEmergencyContacts: (json['extraEmergencyContacts'] as List<dynamic>?)
              ?.map((e) => PrintContactInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bloodTypeOverride: json['bloodTypeOverride'] as String?,
      phoneOverride: json['phoneOverride'] as String?,
      cityUfOverride: json['cityUfOverride'] as String?,
      raceColorOverride: json['raceColorOverride'] as String?,
      genderOverride: json['genderOverride'] as String?,
      cidOverride: json['cidOverride'] as String?,
      responsibleNameOverride: json['responsibleNameOverride'] as String?,
      responsiblePhoneOverride: json['responsiblePhoneOverride'] as String?,
      emergencyNameOverride: json['emergencyNameOverride'] as String?,
      emergencyPhoneOverride: json['emergencyPhoneOverride'] as String?,
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'options': options.toJson(),
      'extraResponsibles': extraResponsibles.map((e) => e.toJson()).toList(),
      'extraEmergencyContacts': extraEmergencyContacts.map((e) => e.toJson()).toList(),
      'bloodTypeOverride': bloodTypeOverride,
      'phoneOverride': phoneOverride,
      'cityUfOverride': cityUfOverride,
      'raceColorOverride': raceColorOverride,
      'genderOverride': genderOverride,
      'cidOverride': cidOverride,
      'responsibleNameOverride': responsibleNameOverride,
      'responsiblePhoneOverride': responsiblePhoneOverride,
      'emergencyNameOverride': emergencyNameOverride,
      'emergencyPhoneOverride': emergencyPhoneOverride,
      'updatedAt': updatedAt,
    };
  }
}

class PrintCardPreferencesLocalService {
  static const String _keyPrefix = 'conectea_print_card_preferences_v1_';

  String _getKey(String memberId) => '$_keyPrefix$memberId';

  Future<PrintCardPreferencesDraft?> load(String memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(memberId);
      if (!prefs.containsKey(key)) return null;

      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PrintCardPreferencesDraft.fromJson(jsonMap);
    } catch (_) {
      // Retorna silenciosamente null em caso de erro no parse (JSON corrompido, mudança de formato, etc)
      return null;
    }
  }

  Future<void> save(String memberId, PrintCardPreferencesDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(memberId);
      final jsonStr = jsonEncode(draft.toJson());
      await prefs.setString(key, jsonStr);
    } catch (_) {
      // Falhas ao salvar não devem crashar a aplicação
    }
  }

  Future<void> delete(String memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(memberId);
      await prefs.remove(key);
    } catch (_) {
      // Ignora erro
    }
  }

  Future<bool> has(String memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(memberId);
      return prefs.containsKey(key);
    } catch (_) {
      return false;
    }
  }
}
