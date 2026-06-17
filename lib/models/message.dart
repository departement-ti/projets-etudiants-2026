class ChatMessage {
  final String id;
  final String sessionId;
  final String sender; // 'bot' | 'user'
  final String message;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      sender: json['sender'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'sender': sender,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isFromUser => sender == 'user';
  bool get isFromBot => sender == 'bot';
}
