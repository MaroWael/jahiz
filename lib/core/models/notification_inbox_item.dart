class NotificationInboxItem {
  NotificationInboxItem({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.payload,
    this.scheduledFor,
    this.isRead = false,
  });

  final String id;
  final int notificationId;
  final String title;
  final String body;
  final String? payload;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;

  bool get isScheduled => scheduledFor != null;

  NotificationInboxItem copyWith({
    String? id,
    int? notificationId,
    String? title,
    String? body,
    String? payload,
    DateTime? createdAt,
    DateTime? scheduledFor,
    bool? isRead,
  }) {
    return NotificationInboxItem(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationInboxItem.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final scheduledFor = DateTime.tryParse(
      json['scheduledFor'] as String? ?? '',
    );

    return NotificationInboxItem(
      id: json['id'] as String? ?? '',
      notificationId: (json['notificationId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      payload: json['payload'] as String?,
      createdAt: createdAt ?? DateTime.now(),
      scheduledFor: scheduledFor,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
