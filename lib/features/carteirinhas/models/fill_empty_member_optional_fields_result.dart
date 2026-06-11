/// DTO imutável de resultado da RPC `conectea_fill_empty_member_optional_fields_v2`.
///
/// Este DTO representa as alterações consolidadas e salvas na tabela members,
/// além do mapeamento de quais campos foram aplicados ou preservados.
class FillEmptyMemberOptionalFieldsResult {
  final String memberId;
  final String bloodType;
  final String phone;
  final String? racaCor;
  final String? gender;
  final String cid;
  final String? responsiblePersonName;
  final String? responsiblePhone;
  final String? emergencyPersonName;
  final String? emergencyPhone;
  final List<String> appliedFields;
  final List<String> preservedFields;
  final bool changed;

  const FillEmptyMemberOptionalFieldsResult({
    required this.memberId,
    required this.bloodType,
    required this.phone,
    required this.racaCor,
    required this.gender,
    required this.cid,
    required this.responsiblePersonName,
    required this.responsiblePhone,
    required this.emergencyPersonName,
    required this.emergencyPhone,
    required this.appliedFields,
    required this.preservedFields,
    required this.changed,
  });

  /// Factory para criar uma instância a partir de uma resposta JSON/Map da RPC.
  ///
  /// Executa validações estritas de contrato (lança [FormatException] se
  /// member_id ou changed estiverem ausentes/inválidos) e filtragem defensiva
  /// de arrays contra a allowlist permitida.
  factory FillEmptyMemberOptionalFieldsResult.fromJson(
    Map<String, dynamic> json,
  ) {
    // 1. Validação estrita do member_id (obrigatório e não vazio)
    final rawMemberId = json['member_id'] ?? json['memberId'];
    if (rawMemberId == null ||
        rawMemberId is! String ||
        rawMemberId.trim().isEmpty) {
      throw const FormatException(
        'member_id inválido ou ausente no resultado da RPC.',
      );
    }
    final String memberId = rawMemberId.trim();

    // 2. Validação estrita do changed (booleano real obrigatório)
    final rawChanged = json['changed'];
    if (rawChanged is! bool) {
      throw const FormatException(
        'changed inválido ou ausente no resultado da RPC.',
      );
    }
    final bool changed = rawChanged;

    // Helpers defensivos para strings
    String parseString(dynamic val) {
      if (val == null) return '';
      return val.toString();
    }

    String? parseNullableString(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      return str.isEmpty ? null : str;
    }

    // Para os campos estruturados de contatos, a regra é estrita: aceitar null puro sem conversão para string vazia
    String? parseStrictNullableString(dynamic val) {
      if (val == null) return null;
      if (val is! String) return val.toString();
      return val;
    }

    final String bloodType = parseString(
      json['blood_type'] ?? json['bloodType'],
    );
    final String phone = parseString(json['phone']);
    final String? racaCor = parseNullableString(
      json['raca_cor'] ?? json['racaCor'],
    );
    final String? gender = parseNullableString(json['gender']);
    final String cid = parseString(json['cid']);

    final String? responsiblePersonName = parseStrictNullableString(
      json['responsible_person_name'],
    );
    final String? responsiblePhone = parseStrictNullableString(
      json['responsible_phone'],
    );
    final String? emergencyPersonName = parseStrictNullableString(
      json['emergency_person_name'],
    );
    final String? emergencyPhone = parseStrictNullableString(
      json['emergency_phone'],
    );

    // Allowlist de campos permitidos nos arrays de controle
    const Set<String> allowedFields = {
      'blood_type',
      'phone',
      'raca_cor',
      'gender',
      'cid',
      'responsible_person_name',
      'responsible_phone',
      'emergency_person_name',
      'emergency_phone',
    };

    // Helper defensivo e estrito para arrays
    List<String> parseList(dynamic val) {
      if (val is! List) {
        throw const FormatException(
          'Formato inválido nos campos de controle da RPC.',
        );
      }
      final parsedList = <String>[];
      final seen = <String>{};
      for (final item in val) {
        if (item is! String) {
          throw const FormatException(
            'Formato inválido nos campos de controle da RPC.',
          );
        }
        if (!allowedFields.contains(item)) {
          throw const FormatException(
            'Formato inválido nos campos de controle da RPC.',
          );
        }
        if (seen.contains(item)) {
          throw const FormatException(
            'Formato inválido nos campos de controle da RPC.',
          );
        }
        seen.add(item);
        parsedList.add(item);
      }
      return List.unmodifiable(parsedList);
    }

    final List<String> appliedFields = parseList(
      json['applied_fields'] ?? json['appliedFields'],
    );
    final List<String> preservedFields = parseList(
      json['preserved_fields'] ?? json['preservedFields'],
    );

    // Verificar interseção entre as duas listas
    final appliedSet = appliedFields.toSet();
    for (final field in preservedFields) {
      if (appliedSet.contains(field)) {
        throw const FormatException(
          'Formato inválido nos campos de controle da RPC.',
        );
      }
    }

    return FillEmptyMemberOptionalFieldsResult(
      memberId: memberId,
      bloodType: bloodType,
      phone: phone,
      racaCor: racaCor,
      gender: gender,
      cid: cid,
      responsiblePersonName: responsiblePersonName,
      responsiblePhone: responsiblePhone,
      emergencyPersonName: emergencyPersonName,
      emergencyPhone: emergencyPhone,
      appliedFields: appliedFields,
      preservedFields: preservedFields,
      changed: changed,
    );
  }
}
