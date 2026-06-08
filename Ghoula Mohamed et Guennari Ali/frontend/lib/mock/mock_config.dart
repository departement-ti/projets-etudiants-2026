// ── Mock Configuration ───────────────────────────────────────────
// Set USE_MOCK = true to use mock data (no backend needed).
// Set USE_MOCK = false to use the real API.
// To remove mocks: delete the mock/ directory and set to false.
// ─────────────────────────────────────────────────────────────────

class MockConfig {
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  // Simulated network delay in milliseconds
  static const int delayMs = 600;

  // Mock token prefix
  static const String mockTokenPrefix = 'mock-jwt-token-';

  // ── Mock Users (match roles from the backend) ─────────────────
  static const List<MockUser> mockUsers = [
    MockUser(
      username: 'admin',
      password: '123456',
      role: 'ROLE_PDG',
      firstName: 'Ahmed',
      lastName: 'Fekih',
      email: 'admin@rayhan.tn',
    ),
    MockUser(
      username: 'vente',
      password: '123456',
      role: 'ROLE_RESPONSABLE_VENTE',
      firstName: 'Karim',
      lastName: 'Ben Ali',
      email: 'vente@rayhan.tn',
    ),
    MockUser(
      username: 'achat',
      password: '123456',
      role: 'ROLE_RESPONSABLE_ACHAT',
      firstName: 'Sami',
      lastName: 'Trabelsi',
      email: 'achat@rayhan.tn',
    ),
    MockUser(
      username: 'production',
      password: '123456',
      role: 'ROLE_RESPONSABLE_PRODUCTION',
      firstName: 'Marwen',
      lastName: 'Jlassi',
      email: 'production@rayhan.tn',
    ),
    MockUser(
      username: 'magasinier',
      password: '123456',
      role: 'ROLE_MAGASINIER',
      firstName: 'Houssem',
      lastName: 'Mejri',
      email: 'magasinier@rayhan.tn',
    ),
    MockUser(
      username: 'client',
      password: '123456',
      role: 'ROLE_CLIENT',
      firstName: 'Omar',
      lastName: 'Ben Salem',
      email: 'client@rayhan.tn',
    ),
  ];

  static MockUser? findUser(String username, String password) {
    try {
      return mockUsers.firstWhere(
        (u) => u.username == username && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }
}

class MockUser {
  final String username;
  final String password;
  final String role;
  final String firstName;
  final String lastName;
  final String email;

  const MockUser({
    required this.username,
    required this.password,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get displayName => '$firstName $lastName';
}
