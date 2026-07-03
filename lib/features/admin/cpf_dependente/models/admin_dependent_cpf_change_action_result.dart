class AdminDependentCpfChangeActionResult {
  final bool success;
  final String? requestId;
  final String? status;
  final String? errorCode;
  final String message;

  const AdminDependentCpfChangeActionResult({
    required this.success,
    this.requestId,
    this.status,
    this.errorCode,
    required this.message,
  });

  factory AdminDependentCpfChangeActionResult.fromJson(Map<String, dynamic> json) {
    return AdminDependentCpfChangeActionResult(
      success: json['success'] as bool? ?? false,
      requestId: json['request_id'] as String?,
      status: json['status'] as String?,
      errorCode: json['error_code'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}
