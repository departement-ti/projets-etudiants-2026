import '../models/company.dart';
import '../services/auth_service.dart';

/// Repository for company data. Isolates data access for Clean Architecture.
class CompanyRepository {
  CompanyRepository(this._authService);
  final AuthService _authService;

  Future<Company?> getCompany(String companyId) => _authService.getCompany(companyId);

  Future<Company> createCompany({
    required String name,
    String? logoUrl,
    String? primaryColor,
    String? welcomeMessage,
  }) =>
      _authService.createCompany(
        name: name,
        logoUrl: logoUrl,
        primaryColor: primaryColor,
        welcomeMessage: welcomeMessage,
      );

  Future<void> updateCompany(String companyId, Map<String, dynamic> data) =>
      _authService.updateCompany(companyId, data);
}
