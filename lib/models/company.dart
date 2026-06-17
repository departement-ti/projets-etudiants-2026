class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String? primaryColor;
  final String? welcomeMessage;
  final String? supportEmail;
  final String? supportWhatsapp;
  final String subscriptionPlan;
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.welcomeMessage,
    this.supportEmail,
    this.supportWhatsapp,
    this.subscriptionPlan = 'free',
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      primaryColor: json['primary_color'] as String?,
      welcomeMessage: json['welcome_message'] as String?,
      supportEmail: json['support_email'] as String?,
      supportWhatsapp: json['support_whatsapp'] as String?,
      subscriptionPlan: json['subscription_plan'] as String? ?? 'free',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo_url': logoUrl,
        'primary_color': primaryColor,
        'welcome_message': welcomeMessage,
        'support_email': supportEmail,
        'support_whatsapp': supportWhatsapp,
        'subscription_plan': subscriptionPlan,
        'created_at': createdAt.toIso8601String(),
      };

  Company copyWith({
    String? name,
    String? logoUrl,
    String? primaryColor,
    String? welcomeMessage,
    String? supportEmail,
    String? supportWhatsapp,
    String? subscriptionPlan,
  }) {
    return Company(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      supportEmail: supportEmail ?? this.supportEmail,
      supportWhatsapp: supportWhatsapp ?? this.supportWhatsapp,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      createdAt: createdAt,
    );
  }
}
