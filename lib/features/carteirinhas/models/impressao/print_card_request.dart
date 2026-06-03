import 'package:conectea/models/member.dart';
import 'print_card_options.dart';

/// **PrintContactInfo**
///
/// DTO simples representativo de contatos adicionados localmente na Bottom Sheet
/// de revisão que serão incluídos na versão final impressa.
class PrintContactInfo {
  final String name;
  final String phone;

  const PrintContactInfo({
    required this.name,
    required this.phone,
  });

  /// Retorna true se houver qualquer conteúdo válido.
  bool get hasAnyContent => name.trim().isNotEmpty || phone.trim().isNotEmpty;
}

/// **PrintCardRequest**
///
/// DTO estruturado de passagem em memória que reúne as escolhas da revisão,
/// overrides temporários e contatos extras locais para a geração do PDF.
class PrintCardRequest {
  final Member member;
  final PrintCardOptions options;
  final bool includeProfile;
  final List<PrintContactInfo> extraResponsibles;
  final List<PrintContactInfo> extraEmergencyContacts;

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
  });
}
