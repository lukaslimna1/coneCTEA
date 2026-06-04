/// **PrintCardOptions**
///
/// DTO contendo flags booleanas das informações selecionadas na Bottom Sheet
/// de revisão para inclusão na versão impressa da carteirinha comunitária.
class PrintCardOptions {
  final bool includeBirthDateAndAge;
  final bool includeMaskedCpf;
  final bool includeBloodType;
  final bool includeCid;
  final bool includePhone;
  final bool includeCityUf;
  final bool includeResponsible;
  final bool includeEmergencyContacts;
  final bool includeRaceColor;
  final bool includeGender;
  final bool includeProfile;

  const PrintCardOptions({
    required this.includeBirthDateAndAge,
    required this.includeMaskedCpf,
    required this.includeBloodType,
    required this.includeCid,
    required this.includePhone,
    required this.includeCityUf,
    required this.includeResponsible,
    required this.includeEmergencyContacts,
    required this.includeRaceColor,
    required this.includeGender,
    required this.includeProfile,
  });

  PrintCardOptions copyWith({
    bool? includeBirthDateAndAge,
    bool? includeMaskedCpf,
    bool? includeBloodType,
    bool? includeCid,
    bool? includePhone,
    bool? includeCityUf,
    bool? includeResponsible,
    bool? includeEmergencyContacts,
    bool? includeRaceColor,
    bool? includeGender,
    bool? includeProfile,
  }) {
    return PrintCardOptions(
      includeBirthDateAndAge: includeBirthDateAndAge ?? this.includeBirthDateAndAge,
      includeMaskedCpf: includeMaskedCpf ?? this.includeMaskedCpf,
      includeBloodType: includeBloodType ?? this.includeBloodType,
      includeCid: includeCid ?? this.includeCid,
      includePhone: includePhone ?? this.includePhone,
      includeCityUf: includeCityUf ?? this.includeCityUf,
      includeResponsible: includeResponsible ?? this.includeResponsible,
      includeEmergencyContacts: includeEmergencyContacts ?? this.includeEmergencyContacts,
      includeRaceColor: includeRaceColor ?? this.includeRaceColor,
      includeGender: includeGender ?? this.includeGender,
      includeProfile: includeProfile ?? this.includeProfile,
    );
  }

  factory PrintCardOptions.fromJson(Map<String, dynamic> json) {
    return PrintCardOptions(
      includeBirthDateAndAge: json['includeBirthDateAndAge'] as bool? ?? false,
      includeMaskedCpf: json['includeMaskedCpf'] as bool? ?? false,
      includeBloodType: json['includeBloodType'] as bool? ?? false,
      includeCid: json['includeCid'] as bool? ?? false,
      includePhone: json['includePhone'] as bool? ?? false,
      includeCityUf: json['includeCityUf'] as bool? ?? false,
      includeResponsible: json['includeResponsible'] as bool? ?? false,
      includeEmergencyContacts: json['includeEmergencyContacts'] as bool? ?? false,
      includeRaceColor: json['includeRaceColor'] as bool? ?? false,
      includeGender: json['includeGender'] as bool? ?? false,
      includeProfile: json['includeProfile'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeBirthDateAndAge': includeBirthDateAndAge,
      'includeMaskedCpf': includeMaskedCpf,
      'includeBloodType': includeBloodType,
      'includeCid': includeCid,
      'includePhone': includePhone,
      'includeCityUf': includeCityUf,
      'includeResponsible': includeResponsible,
      'includeEmergencyContacts': includeEmergencyContacts,
      'includeRaceColor': includeRaceColor,
      'includeGender': includeGender,
      'includeProfile': includeProfile,
    };
  }
}
