/// DTO imutável de parâmetros para a RPC `conectea_fill_empty_member_optional_fields`.
///
/// Este DTO encapsula os parâmetros cadastrais de forma tipada,
/// executando a normalização necessária no construtor para que textos
/// em branco sejam convertidos em valores nulos e removendo espaçamentos
/// em excesso.
class FillEmptyMemberOptionalFieldsParams {
  final String memberId;
  final String? bloodType;
  final String? phone;
  final String? racaCor;
  final String? gender;
  final String? cid;
  final String? responsiblePersonName;
  final String? responsiblePhone;
  final String? emergencyPersonName;
  final String? emergencyPhone;

  FillEmptyMemberOptionalFieldsParams({
    required String memberId,
    String? bloodType,
    String? phone,
    String? racaCor,
    String? gender,
    String? cid,
    String? responsiblePersonName,
    String? responsiblePhone,
    String? emergencyPersonName,
    String? emergencyPhone,
  })  : memberId = memberId.trim(),
        bloodType = _normalize(bloodType),
        phone = _normalize(phone),
        racaCor = _normalize(racaCor),
        gender = _normalize(gender),
        cid = _normalize(cid),
        responsiblePersonName = _normalize(responsiblePersonName),
        responsiblePhone = _normalize(responsiblePhone),
        emergencyPersonName = _normalize(emergencyPersonName),
        emergencyPhone = _normalize(emergencyPhone) {
    if (this.memberId.isEmpty) {
      throw ArgumentError('ID do membro inválido ou vazio.');
    }
  }

  static String? _normalize(String? val) {
    if (val == null) return null;
    final trimmed = val.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Converte a estrutura de parâmetros para o mapa esperado pela RPC do Supabase.
  Map<String, dynamic> toRpcParams() {
    return {
      'p_member_id': memberId,
      'p_blood_type': bloodType,
      'p_phone': phone,
      'p_raca_cor': racaCor,
      'p_gender': gender,
      'p_cid': cid,
      'p_responsible_person_name': responsiblePersonName,
      'p_responsible_phone': responsiblePhone,
      'p_emergency_person_name': emergencyPersonName,
      'p_emergency_phone': emergencyPhone,
    };
  }
}
