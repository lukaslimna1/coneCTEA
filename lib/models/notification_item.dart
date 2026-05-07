class NotificationItem {
  final String id;
  final String userId;
  final String memberId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String actionLabel;
  final String actionRoute;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.memberId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.actionLabel,
    required this.actionRoute,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      memberId: json['memberId'] ?? json['member_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general_notice',
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      actionLabel: json['actionLabel'] ?? json['action_label'] ?? '',
      actionRoute: json['actionRoute'] ?? json['action_route'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'member_id': memberId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'action_label': actionLabel,
      'action_route': actionRoute,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

