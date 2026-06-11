import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:conectea/features/carteirinhas/models/impressao/print_card_request.dart';
import 'package:conectea/models/member.dart';
import 'package:conectea/models/digital_card.dart';
import 'package:conectea/features/carteirinhas/models/impressao/print_card_options.dart';

void main() {
  group('PrintCardRequest Tests (FOTO-PDF-2)', () {
    late PrintCardRequest baseRequest;

    setUp(() {
      baseRequest = PrintCardRequest(
        member: Member.empty(),
        activeCard: DigitalCard.fromJson(const {}), // Fake empty
        options: const PrintCardOptions(
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
          includeProfile: true,
        ),
        includeProfile: true,
        extraResponsibles: const [],
        extraEmergencyContacts: const [],
        supportProfilePhotoBytes: Uint8List.fromList([1, 2, 3]),
      );
    });

    test('4. copyWith preserva foto quando omitida', () {
      final updated = baseRequest.copyWith(bloodTypeOverride: 'A+');
      expect(updated.bloodTypeOverride, 'A+');
      expect(updated.supportProfilePhotoBytes, isNotNull);
      expect(updated.supportProfilePhotoBytes!.length, 3);
    });

    test('5. copyWith substitui foto', () {
      final updated = baseRequest.copyWith(
        supportProfilePhotoBytes: Uint8List.fromList([4, 5]),
      );
      expect(updated.supportProfilePhotoBytes!.length, 2);
    });

    test('6. copyWith limpa foto explicitamente', () {
      final updated = baseRequest.copyWith(clearSupportProfilePhoto: true);
      expect(updated.supportProfilePhotoBytes, isNull);
    });
  });
}
