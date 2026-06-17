class SessionRating {
  final String id;
  final String sessionId;
  final int rating;
  final String? feedback;
  final DateTime? createdAt;

  const SessionRating({
    required this.id,
    required this.sessionId,
    required this.rating,
    this.feedback,
    this.createdAt,
  });

  factory SessionRating.fromJson(Map<String, dynamic> json) {
    return SessionRating(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      rating: (json['rating'] as num).toInt(),
      feedback: json['feedback'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'rating': rating,
        'feedback': feedback,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
