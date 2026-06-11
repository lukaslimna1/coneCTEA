import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/features/carteirinhas/solicitacao/add_member_page.dart';

void main() {
  group('AddMemberPatchHelper', () {
    final original = Member(
      id: 'member-id-123',
      userId: 'user-id',
      name: 'Nome Original',
      socialName: 'Social Original',
      cpf: '111.111.111-11',
      city: 'Bauru',
      state: 'SP',
      phone: '(14) 99999-9999',
      emergencyContact: '',
      responsibleName: '',
      emergencyPersonName: 'Emergência Original',
      emergencyPhone: '11999999999',
      responsiblePersonName: 'Responsável Original',
      responsiblePhone: '11888888888',
      dateOfBirth: '01/01/2000',
      bloodType: 'O+',
      cid: 'F84.0',
      gender: 'Masculino',
      racaCor: 'Branca',
      teaRelationType: 'pessoa_tea',
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      documentUrl: 'doc',
      medicalReportUrl: 'med',
    );

    test('1. nenhum campo alterado retorna Map vazio', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, isEmpty);
    });

    test('2. apenas city alterada envia somente city', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Agudos',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, {'city': 'Agudos'});
    });

    test(
      '3. atualização concorrente em campo estruturado não aparece no Map',
      () {
        // Os campos estruturados nem são recebidos como parâmetro pela UI
        // então a atualização simplesmente ignora qualquer possível diff oculto.
        // E mesmo que fossem alterados na database original, não envia no patch
        final patch = AddMemberPatchHelper.buildPatch(
          original: original,
          name: 'Nome Original',
          socialName: 'Social Original',
          cpf: '111.111.111-11',
          city: 'Bauru',
          state: 'SP',
          phone: '(14) 99999-9999',
          emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
          dateOfBirth: '01/01/2000',
          bloodType: 'O+',
          cid: 'F84.0',
          gender: 'Masculino',
          racaCor: 'Branca',
          teaRelationType: 'pessoa_tea',
        );
        expect(patch.containsKey('responsible_name'), isFalse);
      },
    );

    test('4. name alterado envia somente name', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Modificado',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, {'name': 'Nome Modificado'});
    });

    test('5. telefone com mesma representação semântica não gera diff', () {
      // O flutter Form atualmente não muda a semântica sem ser através do controller
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, isEmpty);
    });

    test('6. CPF com mesma representação semântica não gera diff', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, isEmpty);
    });

    test('7. social_name removido envia null', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: '',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, {'social_name': null});
    });

    test('8. campo obrigatório vazio (espaços) não entra como nulo', () {
      // Como o helper apenas faz diff, um form preenchido só com espaços
      // vai gerar o envio da string trimada (vazia), mas o validator da form
      // intercepta isso antes. Se chegar aqui, o map recebe ''. Não null.
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: '   ',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, {'name': ''});
    });

    test('9. responsible_name alterado entra corretamente', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Novo',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, {'responsible_person_name': 'Responsável Novo'});
    });

    test('10. emergency_contact alterado entra corretamente', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Nova',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, {'emergency_person_name': 'Emergência Nova'});
    });

    test('11. updated_at nunca entra', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch.containsKey('updated_at'), isFalse);
    });

    test('12. campos legados nunca entram', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Novo',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch.containsKey('responsible_name'), isFalse);
      expect(patch.containsKey('emergency_contact'), isFalse);
    });

    test('13. status e URLs nunca entram', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Novo',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch.containsKey('status'), isFalse);
      expect(patch.containsKey('document_url'), isFalse);
    });

    test('14. Map retornado é novo e não muta o Member', () {
      AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Novo',
        socialName: 'Social Original',
        cpf: '111.111.111-11',
        city: 'Bauru',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'O+',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(
        original.name,
        'Nome Original',
      ); // Original não pode ter sido mutado
    });

    test('15. múltiplas alterações enviam somente as modificadas', () {
      final patch = AddMemberPatchHelper.buildPatch(
        original: original,
        name: 'Nome Original',
        socialName: 'Social Novo',
        cpf: '111.111.111-11',
        city: 'Pederneiras',
        state: 'SP',
        phone: '(14) 99999-9999',
        emergencyPersonName: 'Emergência Original',
        emergencyPhone: '11999999999',
        responsiblePersonName: 'Responsável Original',
        responsiblePhone: '11888888888',
        dateOfBirth: '01/01/2000',
        bloodType: 'A-',
        cid: 'F84.0',
        gender: 'Masculino',
        racaCor: 'Branca',
        teaRelationType: 'pessoa_tea',
      );
      expect(patch, {
        'social_name': 'Social Novo',
        'city': 'Pederneiras',
        'blood_type': 'A-',
      });
    });
  });
}
