class AppNotification {
  final int id;
  final String type;
  final int? referenceId;
  final String message;
  final bool lu;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.referenceId,
    required this.message,
    this.lu = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        type: json['type'] ?? '',
        referenceId: json['referenceId'],
        message: json['message'] ?? '',
        lu: json['lu'] ?? false,
        createdAt: json['createdAt'] ?? '',
      );
}
