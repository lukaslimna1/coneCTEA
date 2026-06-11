import 'dart:typed_data';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/models/member.dart';
import 'print_card_options.dart';

/// **PrintContactInfo**
///
/// DTO simples representativo de contatos adicionados localmente na Bottom Sheet
/// de revisão que serão incluídos na versão final impressa.
class PrintContactInfo {
  final String name;
  final String phone;

  const PrintContactInfo({required this.name, required this.phone});

  /// Retorna true se houver qualquer conteúdo válido.
  bool get hasAnyContent => name.trim().isNotEmpty || phone.trim().isNotEmpty;

  factory PrintContactInfo.fromJson(Map<String, dynamic> json) {
    return PrintContactInfo(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone};
  }
}

/// **PrintCardRequest**
///
/// DTO estruturado de passagem em memória que reúne as escolhas da revisão,
/// overrides temporários e contatos extras locais para a geração do PDF.
class PrintCardRequest {
  final Member member;
  final DigitalCard activeCard;
  final PrintCardOptions options;
  final bool includeProfile;
  final List<PrintContactInfo> extraResponsibles;
  final List<PrintContactInfo> extraEmergencyContacts;
  final Uint8List? supportProfilePhotoBytes;

  // Informações cadastrais preenchidas temporariamente em memória na Bottom Sheet de revisão
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

  const PrintCardRequest({
    required this.member,
    required this.activeCard,
    required this.options,
    required this.includeProfile,
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
    this.supportProfilePhotoBytes,
  });

  PrintCardRequest copyWith({
    Member? member,
    DigitalCard? activeCard,
    PrintCardOptions? options,
    bool? includeProfile,
    List<PrintContactInfo>? extraResponsibles,
    List<PrintContactInfo>? extraEmergencyContacts,
    String? bloodTypeOverride,
    String? phoneOverride,
    String? cityUfOverride,
    String? raceColorOverride,
    String? genderOverride,
    String? cidOverride,
    String? responsibleNameOverride,
    String? responsiblePhoneOverride,
    String? emergencyNameOverride,
    String? emergencyPhoneOverride,
    Uint8List? supportProfilePhotoBytes,
    bool clearSupportProfilePhoto = false,
  }) {
    return PrintCardRequest(
      member: member ?? this.member,
      activeCard: activeCard ?? this.activeCard,
      options: options ?? this.options,
      includeProfile: includeProfile ?? this.includeProfile,
      extraResponsibles: extraResponsibles ?? this.extraResponsibles,
      extraEmergencyContacts:
          extraEmergencyContacts ?? this.extraEmergencyContacts,
      bloodTypeOverride: bloodTypeOverride ?? this.bloodTypeOverride,
      phoneOverride: phoneOverride ?? this.phoneOverride,
      cityUfOverride: cityUfOverride ?? this.cityUfOverride,
      raceColorOverride: raceColorOverride ?? this.raceColorOverride,
      genderOverride: genderOverride ?? this.genderOverride,
      cidOverride: cidOverride ?? this.cidOverride,
      responsibleNameOverride:
          responsibleNameOverride ?? this.responsibleNameOverride,
      responsiblePhoneOverride:
          responsiblePhoneOverride ?? this.responsiblePhoneOverride,
      emergencyNameOverride:
          emergencyNameOverride ?? this.emergencyNameOverride,
      emergencyPhoneOverride:
          emergencyPhoneOverride ?? this.emergencyPhoneOverride,
      supportProfilePhotoBytes: clearSupportProfilePhoto
          ? null
          : (supportProfilePhotoBytes ?? this.supportProfilePhotoBytes),
    );
  }
}
