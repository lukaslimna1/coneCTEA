class DigitalCard {
  final String id;
  final String memberId;
  final String userId;
  final String cardNumber;
  final String status;
  final DateTime validUntil;
  final DateTime issuedAt;
  final Map<String, dynamic> frontData;
  final Map<String, dynamic> backData;
  final String qrValidationUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DigitalCard({
    required this.id,
    required this.memberId,
    required this.userId,
    required this.cardNumber,
    required this.status,
    required this.validUntil,
    required this.issuedAt,
    required this.frontData,
    required this.backData,
    required this.qrValidationUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DigitalCard.fromJson(Map<String, dynamic> data) {
    return DigitalCard(
      id: data['id']?.toString() ?? '',
      memberId: data['memberId'] ?? data['member_id'] ?? '',
      userId: data['userId'] ?? data['user_id'] ?? '',
      cardNumber: data['cardNumber'] ?? data['card_number'] ?? '',
      status: data['status'] ?? 'pending',
      validUntil: data['validUntil'] != null 
          ? DateTime.parse(data['validUntil']) 
          : (data['valid_until'] != null ? DateTime.parse(data['valid_until']) : DateTime.now()),
      issuedAt: data['issuedAt'] != null 
          ? DateTime.parse(data['issuedAt']) 
          : (data['issued_at'] != null ? DateTime.parse(data['issued_at']) : DateTime.now()),
      frontData: data['frontData'] ?? data['front_data'] ?? {},
      backData: data['backData'] ?? data['back_data'] ?? {},
      qrValidationUrl: data['qrValidationUrl'] ?? data['qr_validation_url'] ?? '',
      // isActive: usa is_active se existir, senão deriva de status
      isActive: data['is_active'] as bool? ?? (data['status'] == 'active'),
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : (data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now()),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt']) 
          : (data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'user_id': userId,
      'card_number': cardNumber,
      'status': status,
      'valid_until': validUntil.toIso8601String(),
      'issued_at': issuedAt.toIso8601String(),
      'front_data': frontData,
      'back_data': backData,
      'qr_validation_url': qrValidationUrl,
      // Não inclui 'is_active' — derivado de status=='active' no banco
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
