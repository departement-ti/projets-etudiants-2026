class ChatIntent {
  final String id;
  final String companyId;
  final String intentName;
  final List<String> trainingPhrases;
  final String responseText;
  final DateTime? createdAt;

  const ChatIntent({
    required this.id,
    required this.companyId,
    required this.intentName,
    required this.trainingPhrases,
    required this.responseText,
    this.createdAt,
  });

  factory ChatIntent.fromJson(Map<String, dynamic> json) {
    final phrases = json['training_phrases'];
    return ChatIntent(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      intentName: json['intent_name'] as String,
      trainingPhrases: phrases is List
          ? List<String>.from(phrases.map((e) => e.toString()))
          : (phrases is String ? phrases.split('|') : []),
      responseText: json['response_text'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'intent_name': intentName,
        'training_phrases': trainingPhrases,
        'response_text': responseText,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
