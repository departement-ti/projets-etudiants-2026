class UnknownQuestion {
  final String id;
  final String companyId;
  final String question;
  final int frequency;
  final String status; // pending | approved
  final DateTime? createdAt;

  const UnknownQuestion({
    required this.id,
    required this.companyId,
    required this.question,
    this.frequency = 1,
    this.status = 'pending',
    this.createdAt,
  });

  factory UnknownQuestion.fromJson(Map<String, dynamic> json) {
    return UnknownQuestion(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      question: json['question'] as String,
      frequency: (json['frequency'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'question': question,
        'frequency': frequency,
        'status': status,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
