import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class User {
  final int? id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool enabled;
  final List<String> roles;

  User({
    this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.enabled = true,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'enabled': enabled,
      'roles': roles,
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    return username;
  }

  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      return '${firstName![0]}${lastName != null && lastName!.isNotEmpty ? lastName![0] : ''}';
    }
    return username[0].toUpperCase();
  }

  String get roleLabel {
    if (roles.isEmpty) return 'Aucun rôle';
    return roles.map(roleLabelFor).join(', ');
  }

  Color get roleColor {
    if (roles.contains('ROLE_PDG')) return AppTheme.kErrorRed;
    if (roles.contains('ROLE_RESPONSABLE_VENTE')) return AppTheme.kPrimaryTeal;
    if (roles.contains('ROLE_RESPONSABLE_ACHAT')) return AppTheme.kPrimaryOrange;
    if (roles.contains('ROLE_RESPONSABLE_PRODUCTION')) return AppTheme.kSecondaryGold;
    if (roles.contains('ROLE_MAGASINIER')) return AppTheme.kWarningAmber;
    return AppTheme.kTextSecondary;
  }

  static String roleLabelFor(String role) {
    switch (role) {
      case 'ROLE_PDG':
        return 'Gérant';
      case 'ROLE_RESPONSABLE_VENTE':
        return 'Resp. Ventes';
      case 'ROLE_RESPONSABLE_ACHAT':
        return 'Resp. Achats';
      case 'ROLE_RESPONSABLE_PRODUCTION':
        return 'Resp. Production';
      case 'ROLE_MAGASINIER':
        return 'Magasinier';
      case 'ROLE_CLIENT':
        return 'Client';
      case 'ROLE_FOURNISSEUR':
        return 'Fournisseur';
      default:
        return role.replaceAll('ROLE_', '');
    }
  }

  static String roleLabelLong(String role) {
    switch (role) {
      case 'ROLE_PDG':
        return 'Gérant';
      case 'ROLE_RESPONSABLE_VENTE':
        return 'Responsable Ventes';
      case 'ROLE_RESPONSABLE_ACHAT':
        return 'Responsable Achats';
      case 'ROLE_RESPONSABLE_PRODUCTION':
        return 'Responsable Production';
      case 'ROLE_MAGASINIER':
        return 'Magasinier';
      default:
        return roleLabelFor(role);
    }
  }
}
