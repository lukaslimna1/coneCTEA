import 'package:conectea/models/member.dart';
import 'package:conectea/features/carteirinhas/models/fill_empty_member_optional_fields_result.dart';

/// Extension para realizar a mesclagem segura dos resultados da RPC de campos
/// opcionais sobre o modelo [Member] em memória.
extension MemberRpcMergeExtension on Member {
  /// Cria uma nova instância de [Member] com os campos consolidados do resultado da RPC.
  ///
  /// Valida que o [result.memberId] corresponde ao [id] do membro. Lança
  /// um [StateError] caso divirjam.
  /// Atualiza exatamente os sete campos preenchidos pela RPC, preservando os demais
  /// intactos (incluindo metadados como `updatedAt` e `createdAt`).
  Member mergeRpcResult(FillEmptyMemberOptionalFieldsResult result) {
    if (result.memberId != id) {
      throw StateError('ID do membro divergente no resultado da RPC.');
    }

    return Member(
      id: id,
      userId: userId,
      name: name,
      cpf: cpf,
      city: city,
      state: state,
      phone: result.phone,
      emergencyContact: result.emergencyContact,
      responsibleName: result.responsibleName,
      dateOfBirth: dateOfBirth,
      bloodType: result.bloodType,
      cid: result.cid,
      documentUrl: documentUrl,
      medicalReportUrl: medicalReportUrl,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      gender: result.gender,
      racaCor: result.racaCor,
      socialName: socialName,
      teaRelationType: teaRelationType,
      responsiblePersonName: responsiblePersonName,
      responsiblePhone: responsiblePhone,
      emergencyPersonName: emergencyPersonName,
      emergencyPhone: emergencyPhone,
    );
  }
}
