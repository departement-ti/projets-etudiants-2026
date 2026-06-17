class ChatSession {
  final String id;
  final String companyId;
  final String userIdentifier;
  final DateTime? startedAt;
  final DateTime? endTime;
  final DateTime? createdAt;

  const ChatSession({
    required this.id,
    required this.companyId,
    required this.userIdentifier,
    this.startedAt,
    this.endTime,
    this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userIdentifier: json['user_identifier'] as String,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : json['start_time'] != null
              ? DateTime.parse(json['start_time'] as String)
              : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'user_identifier': userIdentifier,
        'started_at': startedAt?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };
}
