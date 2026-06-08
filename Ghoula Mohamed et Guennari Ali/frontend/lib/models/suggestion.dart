class Suggestion {
  final int id;
  final String type;
  final String title;
  final String description;
  final String impact;
  final int priority;
  final String module;
  final bool read;

  Suggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.impact,
    this.priority = 0,
    this.module = 'general',
    this.read = false,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) => Suggestion(
        id: json['id'] ?? 0,
        type: json['type'] ?? 'info',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        impact: json['impact'] ?? '',
        priority: json['priority'] ?? 0,
        module: json['module'] ?? 'general',
        read: json['read'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'impact': impact,
        'priority': priority,
        'module': module,
        'read': read,
      };

  Suggestion copyWith({bool? read}) => Suggestion(
        id: id,
        type: type,
        title: title,
        description: description,
        impact: impact,
        priority: priority,
        module: module,
        read: read ?? this.read,
      );
}
