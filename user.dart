enum UserRole { fournisseur, recycleur }

class AppUser {
  final String id;
  final String nom;
  final String email;
  final UserRole role;

  AppUser({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
  });
}