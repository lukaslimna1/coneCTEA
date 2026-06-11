import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/features/carteirinhas/services/print_support_profile_local_service.dart';

void main() {
  group('PrintSupportProfileDraft Tests (FOTO-PDF-2)', () {
    test('1. draft antigo sem localPhotoPath continua carregando', () {
      final json = {
        'member_id': '123',
        'updatedAt': '2023-01-01',
        'preferredName': 'Lucas',
        'about': 'Sobre',
        'includePreferredName': true,
        'includeAbout': true,
        'includeCommunication': false,
        'includeLikes': false,
        'includeIrritations': false,
        'includeCuriosities': false,
        'includeSupportTips': false,
        'includeSupportLevel': false,
        'includeFoodLikes': false,
        'includeFoodDislikes': false,
        'includeMedications': false,
        'includeAllergies': false,
        'includeOtherImportantInfo': false,
        'commSpeech': false,
        'commGestures': false,
        'commPictograms': false,
        'commApps': false,
        'communicationNotes': '',
        'supportLevel': '1',
        'foodLikes': [],
        'foodDislikes': [],
        'likes': [],
        'irritations': [],
        'abilities': [],
        'supportTips': [],
        'medications': [],
        'allergies': [],
        'otherImportantInfo': '',
      };

      final draft = PrintSupportProfileDraft.fromJson(json);
      expect(draft.memberId, '123');
      expect(draft.localPhotoPath, isNull);
    });

    test('2. draft serializa somente localPhotoPath', () {
      final draft = PrintSupportProfileDraft.empty(
        '123',
      ).copyWith(localPhotoPath: '/app/path/123.jpg');
      final json = draft.toJson();
      expect(json['localPhotoPath'], '/app/path/123.jpg');
    });

    test('3. draft nunca serializa bytes/Base64', () {
      final draft = PrintSupportProfileDraft.empty(
        '123',
      ).copyWith(localPhotoPath: '/app/path/123.jpg');
      final json = draft.toJson();
      expect(json.containsKey('bytes'), isFalse);
      expect(json.containsKey('base64'), isFalse);
    });
  });
}
