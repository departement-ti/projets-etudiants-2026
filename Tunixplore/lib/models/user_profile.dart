// lib/models/user_profile.dart
//
// Strongly typed profile models for TuniXplore.
// Backward compatible with existing Firestore documents.
//
// Firestore shape (all fields may be null / missing in legacy docs):
//   role, firstName, lastName, email, phone, city, bio,
//   avatarUrl, interests, specialty, agencyName, agencyLicense

// ── Role enum ──────────────────────────────────────────────────────────────────
enum UserRole {
  visitor,
  organiserParticular,
  organiserAgency;

  /// Parse raw Firestore string, defaulting to [visitor] for unknown values.
  static UserRole fromString(String? raw) {
    switch (raw) {
      case 'organiserParticular': return UserRole.organiserParticular;
      case 'organiserAgency':     return UserRole.organiserAgency;
      default:                    return UserRole.visitor;
    }
  }

  String get firestoreValue => name; // 'visitor' | 'organiserParticular' | 'organiserAgency'

  bool get isOrganiser =>
      this == UserRole.organiserParticular || this == UserRole.organiserAgency;

  String get displayLabel {
    switch (this) {
      case UserRole.visitor:             return 'Visiteur';
      case UserRole.organiserParticular: return 'Guide indépendant';
      case UserRole.organiserAgency:     return 'Agence de voyage';
    }
  }
}

// ── Safe Firestore helpers ─────────────────────────────────────────────────────
// All parsing goes through these to ensure existing null / missing fields
// never crash parsing.
String _s(Map<String, dynamic> d, String k) => d[k] as String? ?? '';
List<String> _list(Map<String, dynamic> d, String k) =>
    (d[k] as List?)?.map((e) => e.toString()).toList() ?? [];

// ── Abstract base ──────────────────────────────────────────────────────────────
abstract class UserProfile {
  final String uid;
  final UserRole role;
  final String avatarUrl;
  final String email;
  final String city;
  final String bio;

  const UserProfile({
    required this.uid,
    required this.role,
    required this.avatarUrl,
    required this.email,
    required this.city,
    required this.bio,
  });

  // ── Factory: pick the right subclass from a Firestore document ─────────────
  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final role = UserRole.fromString(data['role'] as String?);
    switch (role) {
      case UserRole.organiserAgency:
        return OrganiserAgencyProfile.fromFirestore(uid, data);
      case UserRole.organiserParticular:
        return OrganiserParticularProfile.fromFirestore(uid, data);
      case UserRole.visitor:
        return VisitorProfile.fromFirestore(uid, data);
    }
  }

  // ── Each subclass provides its own Firestore map ───────────────────────────
  /// Returns only the fields owned by this profile type.
  /// The merge-write strategy in ProfileService ensures unknown fields
  /// from other roles are never overwritten.
  Map<String, dynamic> toFirestore();

  // ── Role-specific validation ───────────────────────────────────────────────
  /// Returns a human-readable error string, or null if valid.
  String? validate();

  // ── Common fields shared by all roles ─────────────────────────────────────
  Map<String, dynamic> _commonFields() => {
    'role'      : role.firestoreValue,
    'avatarUrl' : avatarUrl,
    'email'     : email,
    'city'      : city,
    'bio'       : bio,
  };
}

// ── Visitor ────────────────────────────────────────────────────────────────────
class VisitorProfile extends UserProfile {
  final String       firstName;
  final String       lastName;
  final List<String> interests;

  const VisitorProfile({
    required super.uid,
    required super.avatarUrl,
    required super.email,
    required super.city,
    required super.bio,
    required this.firstName,
    required this.lastName,
    required this.interests,
  }) : super(role: UserRole.visitor);

  factory VisitorProfile.fromFirestore(
      String uid, Map<String, dynamic> data) {
    return VisitorProfile(
      uid:       uid,
      firstName: _s(data, 'firstName'),
      lastName:  _s(data, 'lastName'),
      email:     _s(data, 'email'),
      city:      _s(data, 'city'),
      bio:       _s(data, 'bio'),
      avatarUrl: _s(data, 'avatarUrl'),
      interests: _list(data, 'interests'),
    );
  }

  /// Returns a copy with overridden fields.
  VisitorProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? city,
    String? bio,
    String? avatarUrl,
    List<String>? interests,
  }) =>
      VisitorProfile(
        uid:       uid,
        firstName: firstName  ?? this.firstName,
        lastName:  lastName   ?? this.lastName,
        email:     email      ?? this.email,
        city:      city       ?? this.city,
        bio:       bio        ?? this.bio,
        avatarUrl: avatarUrl  ?? this.avatarUrl,
        interests: interests  ?? this.interests,
      );

  @override
  Map<String, dynamic> toFirestore() => {
    ..._commonFields(),
    'firstName' : firstName,
    'lastName'  : lastName,
    'interests' : interests,
  };

  @override
  String? validate() {
    if (firstName.trim().isEmpty) return 'Le prénom est obligatoire';
    if (lastName.trim().isEmpty)  return 'Le nom est obligatoire';
    if (!_validEmail(email))      return 'Adresse email invalide';
    return null;
  }
}

// ── Organiser Particular ───────────────────────────────────────────────────────
class OrganiserParticularProfile extends UserProfile {
  final String       firstName;
  final String       lastName;
  final String       phone;
  final String       specialty;
  final List<String> interests;

  const OrganiserParticularProfile({
    required super.uid,
    required super.avatarUrl,
    required super.email,
    required super.city,
    required super.bio,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.specialty,
    required this.interests,
  }) : super(role: UserRole.organiserParticular);

  factory OrganiserParticularProfile.fromFirestore(
      String uid, Map<String, dynamic> data) {
    return OrganiserParticularProfile(
      uid:       uid,
      firstName: _s(data, 'firstName'),
      lastName:  _s(data, 'lastName'),
      email:     _s(data, 'email'),
      phone:     _s(data, 'phone'),
      city:      _s(data, 'city'),
      bio:       _s(data, 'bio'),
      avatarUrl: _s(data, 'avatarUrl'),
      specialty: _s(data, 'specialty'),
      interests: _list(data, 'interests'),
    );
  }

  OrganiserParticularProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? city,
    String? bio,
    String? avatarUrl,
    String? specialty,
    List<String>? interests,
  }) =>
      OrganiserParticularProfile(
        uid:       uid,
        firstName: firstName  ?? this.firstName,
        lastName:  lastName   ?? this.lastName,
        email:     email      ?? this.email,
        phone:     phone      ?? this.phone,
        city:      city       ?? this.city,
        bio:       bio        ?? this.bio,
        avatarUrl: avatarUrl  ?? this.avatarUrl,
        specialty: specialty  ?? this.specialty,
        interests: interests  ?? this.interests,
      );

  @override
  Map<String, dynamic> toFirestore() => {
    ..._commonFields(),
    'firstName' : firstName,
    'lastName'  : lastName,
    'phone'     : phone,
    'specialty' : specialty,
    'interests' : interests,
  };

  @override
  String? validate() {
    if (firstName.trim().isEmpty) return 'Le prénom est obligatoire';
    if (lastName.trim().isEmpty)  return 'Le nom est obligatoire';
    if (!_validEmail(email))      return 'Adresse email invalide';
    if (phone.trim().isEmpty)     return 'Le téléphone est obligatoire';
    if (specialty.trim().isEmpty) return 'La spécialité est obligatoire';
    return null;
  }
}

// ── Organiser Agency ───────────────────────────────────────────────────────────
class OrganiserAgencyProfile extends UserProfile {
  final String agencyName;
  final String agencyLicense;
  final String phone;

  const OrganiserAgencyProfile({
    required super.uid,
    required super.avatarUrl,
    required super.email,
    required super.city,
    required super.bio,
    required this.agencyName,
    required this.agencyLicense,
    required this.phone,
  }) : super(role: UserRole.organiserAgency);

  factory OrganiserAgencyProfile.fromFirestore(
      String uid, Map<String, dynamic> data) {
    return OrganiserAgencyProfile(
      uid:           uid,
      email:         _s(data, 'email'),
      phone:         _s(data, 'phone'),
      city:          _s(data, 'city'),
      bio:           _s(data, 'bio'),
      avatarUrl:     _s(data, 'avatarUrl'),
      agencyName:    _s(data, 'agencyName'),
      agencyLicense: _s(data, 'agencyLicense'),
    );
  }

  OrganiserAgencyProfile copyWith({
    String? email,
    String? phone,
    String? city,
    String? bio,
    String? avatarUrl,
    String? agencyName,
    String? agencyLicense,
  }) =>
      OrganiserAgencyProfile(
        uid:           uid,
        email:         email          ?? this.email,
        phone:         phone          ?? this.phone,
        city:          city           ?? this.city,
        bio:           bio            ?? this.bio,
        avatarUrl:     avatarUrl      ?? this.avatarUrl,
        agencyName:    agencyName     ?? this.agencyName,
        agencyLicense: agencyLicense  ?? this.agencyLicense,
      );

  @override
  Map<String, dynamic> toFirestore() => {
    ..._commonFields(),
    'phone'         : phone,
    'agencyName'    : agencyName,
    'agencyLicense' : agencyLicense,
  };

  @override
  String? validate() {
    if (!_validEmail(email))          return 'Adresse email invalide';
    if (phone.trim().isEmpty)         return 'Le téléphone est obligatoire';
    if (agencyName.trim().isEmpty)    return 'Le nom de l\'agence est obligatoire';
    if (agencyLicense.trim().isEmpty) return 'Le numéro de licence est obligatoire';
    return null;
  }
}

// ── Shared validator ───────────────────────────────────────────────────────────
bool _validEmail(String e) =>
    RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(e.trim());