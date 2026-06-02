class NotificationAlertModel {
  final String id;
  final String title;
  final String message;
  final DateTime dateTime;
  final bool isRead;
  final String userId;

  NotificationAlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.dateTime,
    this.isRead = false,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'dateTime': dateTime.toIso8601String(),
      'isRead': isRead,
      'userId': userId,
    };
  }

  factory NotificationAlertModel.fromMap(Map<String, dynamic> map) {
    return NotificationAlertModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      isRead: map['isRead'] ?? false,
      userId: map['userId'] ?? '',
    );
  }

  NotificationAlertModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? dateTime,
    bool? isRead,
    String? userId,
  }) {
    return NotificationAlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
    );
  }
}
