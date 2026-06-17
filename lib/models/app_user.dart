class AppUser {
  final String id;
  final String companyId;
  final String role; // admin | agent
  final String email;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.companyId,
    required this.role,
    required this.email,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      role: json['role'] as String? ?? 'agent',
      email: json['email'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'role': role,
        'email': email,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  bool get isAdmin => role == 'admin';
}
