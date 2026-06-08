import 'dart:math';
import '../models/dashboard_kpi.dart';
import '../models/article.dart';
import '../models/sales_order.dart';
import '../models/client.dart';
import '../models/purchase_order.dart';
import '../models/fournisseur.dart';
import '../models/production_order.dart';
import '../models/stock_movement.dart';
import '../models/user.dart';
import '../models/notification.dart';
import '../services/auth_service.dart';
import '../services/article_service.dart';
import '../services/dashboard_service.dart';
import '../services/client_service.dart';
import '../services/fournisseur_service.dart';
import '../services/sales_order_service.dart';
import '../services/purchase_order_service.dart';
import '../services/production_service.dart';
import '../services/stock_service.dart';
import '../services/user_service.dart';
import '../services/catalog_service.dart';
import '../services/client_order_service.dart';
import '../services/notification_service.dart';
import 'mock_data.dart';
import 'mock_config.dart';

class MockAuthService implements AuthService {
  MockUser? _currentUser;

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    await MockData.delay();
    final user = MockConfig.findUser(username, password);
    if (user != null) {
      _currentUser = user;
      return {
        'token': '${MockConfig.mockTokenPrefix}${user.role}',
        'type': 'Bearer',
        'id': MockConfig.mockUsers.indexOf(user) + 1,
        'username': user.username,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'roles': [user.role],
      };
    }
    throw Exception('Identifiants incorrects');
  }

  @override
  Future<void> saveToken(String token, String role) async {}

  @override
  Future<String?> getToken() async {
    if (_currentUser != null) return '${MockConfig.mockTokenPrefix}${_currentUser!.role}';
    return null;
  }

  @override
  Future<String?> getRole() async => _currentUser?.role;

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<Map<String, dynamic>> signup(
      String firstName, String lastName, String email, String username, String password) async {
    await MockData.delay();
    return {
      'token': '${MockConfig.mockTokenPrefix}ROLE_CLIENT',
      'type': 'Bearer',
      'id': MockConfig.mockUsers.length + 1,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'roles': ['ROLE_CLIENT'],
    };
  }
}

class MockArticleService implements ArticleService {
  List<Article> _articles = [];
  int _nextId = 100;

  @override
  Future<List<Article>> fetchAll() async {
    await MockData.delay();
    if (_articles.isEmpty) {
      _articles = MockData.articles.map((m) => Article(
        id: m['id'] as int,
        reference: m['reference'] as String,
        designation: m['designation'] as String,
        type: m['type'] as String,
        uniteMesure: m['uniteMesure'] as String? ?? 'unité',
        prixUnitaire: (m['prixUnitaire'] as num).toDouble(),
        stockActuel: (m['stockActuel'] as num).toDouble(),
        stockMinimum: (m['stockMinimum'] as num).toDouble(),
      )).toList();
      _nextId = 200;
    }
    return List.unmodifiable(_articles);
  }

  @override
  Future<List<Article>> fetchByType(String type) async {
    await MockData.delay();
    return _articles.where((a) => a.type == type).toList();
  }

  @override
  Future<Article> create(Article article) async {
    await MockData.delay();
    final created = Article(
      id: _nextId++,
      reference: article.reference,
      designation: article.designation,
      type: article.type,
      uniteMesure: article.uniteMesure,
      prixUnitaire: article.prixUnitaire,
      stockActuel: article.stockActuel,
      stockMinimum: article.stockMinimum,
    );
    _articles.add(created);
    return created;
  }

  @override
  Future<Article> update(int id, Article article) async {
    await MockData.delay();
    final idx = _articles.indexWhere((a) => a.id == id);
    if (idx == -1) throw Exception('Article non trouvé');
    final updated = Article(
      id: id,
      reference: article.reference,
      designation: article.designation,
      type: article.type,
      uniteMesure: article.uniteMesure,
      prixUnitaire: article.prixUnitaire,
      stockActuel: article.stockActuel,
      stockMinimum: article.stockMinimum,
    );
    _articles[idx] = updated;
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    await MockData.delay();
    _articles.removeWhere((a) => a.id == id);
  }
}

class MockDashboardService implements DashboardService {
  @override
  Future<DashboardKpi> fetchKpis() async {
    await MockData.delay();
    return MockData.dashboardKpi;
  }
}

class MockClientService implements ClientService {
  final List<Client> _clients = [
    Client(id: 1, raisonSociale: 'SOTUPLAST S.A.', matriculeFiscal: '123456789', adresse: 'Route de la Marsa', email: 'contact@sotuplast.tn', telephone: '71 123 456', ville: 'Tunis', typeClient: 'Industrie', plafondCredit: 50000, delaiPaiement: 30, representantNom: 'Mohamed Ali', representantTelephone: '98 765 432'),
    Client(id: 2, raisonSociale: 'PLASTITUNISIE', matriculeFiscal: '987654321', adresse: 'Z.I. Charguia II', email: 'info@plastitunisie.tn', telephone: '71 987 654', ville: 'Tunis', typeClient: 'Grossiste', plafondCredit: 30000, delaiPaiement: 45, representantNom: 'Sami Ben', representantTelephone: '99 111 222'),
    Client(id: 3, raisonSociale: 'EMBALLAGES MODERNES', matriculeFiscal: '456123789', adresse: 'Megrine', email: 'emodernes@planet.tn', telephone: '72 456 789', ville: 'Ben Arous', typeClient: 'Détaillant', plafondCredit: 10000, delaiPaiement: 30, representantNom: 'Karim', representantTelephone: '55 333 444'),
    Client(id: 4, raisonSociale: 'AGRO-PACK S.A.R.L.', matriculeFiscal: '789456123', adresse: 'Technopole El Ghazala', email: 'contact@agropack.tn', telephone: '70 123 789', ville: 'Ariana', typeClient: 'Industrie', plafondCredit: 75000, delaiPaiement: 60, representantNom: 'Nadia', representantTelephone: '22 555 666'),
    Client(id: 5, raisonSociale: 'NOUVEAU CLIENT', email: 'nouveau@client.tn', typeClient: 'Grossiste'),
  ];

  int _nextId = 100;

  @override
  Future<List<Client>> fetchAll() async {
    await MockData.delay();
    return List.unmodifiable(_clients);
  }

  @override
  Future<Client> getById(int id) async {
    await MockData.delay();
    return _clients.firstWhere((c) => c.id == id);
  }

  @override
  Future<Client> create(Client client) async {
    await MockData.delay();
    final created = Client(
      id: _nextId++,
      raisonSociale: client.raisonSociale,
      matriculeFiscal: client.matriculeFiscal,
      telephone: client.telephone,
      email: client.email,
      adresse: client.adresse,
      ville: client.ville,
      typeClient: client.typeClient,
      plafondCredit: client.plafondCredit,
      delaiPaiement: client.delaiPaiement,
      representantNom: client.representantNom,
      representantTelephone: client.representantTelephone,
      actif: client.actif,
    );
    _clients.add(created);
    return created;
  }

  @override
  Future<Client> update(int id, Client client) async {
    await MockData.delay();
    final idx = _clients.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('Client non trouvé');
    final updated = Client(
      id: id,
      raisonSociale: client.raisonSociale,
      matriculeFiscal: client.matriculeFiscal,
      telephone: client.telephone,
      email: client.email,
      adresse: client.adresse,
      ville: client.ville,
      typeClient: client.typeClient,
      plafondCredit: client.plafondCredit,
      delaiPaiement: client.delaiPaiement,
      representantNom: client.representantNom,
      representantTelephone: client.representantTelephone,
      actif: client.actif,
    );
    _clients[idx] = updated;
    return updated;
  }

  @override
  Future<Client> createWithUser({
    required String raisonSociale,
    String? matriculeFiscal,
    String? adresse,
    String? telephone,
    String? email,
    String? ville,
    String? typeClient,
    double? plafondCredit,
    int? delaiPaiement,
    String? representantNom,
    String? representantTelephone,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    await MockData.delay();
    final created = Client(
      id: _nextId++,
      raisonSociale: raisonSociale,
      matriculeFiscal: matriculeFiscal,
      telephone: telephone,
      email: email,
      adresse: adresse,
      ville: ville,
      typeClient: typeClient,
      plafondCredit: plafondCredit,
      delaiPaiement: delaiPaiement,
      representantNom: representantNom,
      representantTelephone: representantTelephone,
    );
    _clients.add(created);
    return created;
  }
}

class MockFournisseurService implements FournisseurService {
  final List<Fournisseur> _fournisseurs = [
    Fournisseur(id: 1, raisonSociale: 'POLYMERGY TUNISIE', matriculeFiscal: '111222333', adresse: 'Z.I. Ben Arous'),
    Fournisseur(id: 2, raisonSociale: 'CHIMIPLAST S.A.', matriculeFiscal: '444555666', adresse: 'Sfax'),
    Fournisseur(id: 3, raisonSociale: 'EUROPLAST GmbH', matriculeFiscal: '777888999', adresse: 'Hambourg, Allemagne'),
  ];
  int _nextId = 4;

  @override
  Future<List<Fournisseur>> fetchAll() async {
    await MockData.delay();
    return List.unmodifiable(_fournisseurs.where((f) => f.actif));
  }

  @override
  Future<Fournisseur> getById(int id) async {
    await MockData.delay();
    return _fournisseurs.firstWhere((f) => f.id == id);
  }

  @override
  Future<Fournisseur> create(Fournisseur f) async {
    await MockData.delay();
    final created = Fournisseur(
      id: _nextId++,
      raisonSociale: f.raisonSociale,
      matriculeFiscal: f.matriculeFiscal,
      telephone: f.telephone,
      email: f.email,
      adresse: f.adresse,
      ville: f.ville,
      pays: f.pays,
      categorieProduit: f.categorieProduit,
      modePaiement: f.modePaiement,
      actif: true,
    );
    _fournisseurs.add(created);
    return created;
  }

  @override
  Future<Fournisseur> update(int id, Fournisseur f) async {
    await MockData.delay();
    final idx = _fournisseurs.indexWhere((x) => x.id == id);
    if (idx == -1) throw Exception('Not found');
    final updated = Fournisseur(
      id: id,
      raisonSociale: f.raisonSociale,
      matriculeFiscal: f.matriculeFiscal,
      telephone: f.telephone,
      email: f.email,
      adresse: f.adresse,
      ville: f.ville,
      pays: f.pays,
      categorieProduit: f.categorieProduit,
      modePaiement: f.modePaiement,
      actif: f.actif,
    );
    _fournisseurs[idx] = updated;
    return updated;
  }
}

class MockSalesOrderService implements SalesOrderService {
  final List<String> _clientNames = [
    'SOTUPLAST S.A.', 'PLASTITUNISIE', 'EMBALLAGES MODERNES', 'AGRO-PACK S.A.R.L.',
  ];

  int _idCounter = 100;

  @override
  Future<List<SalesOrder>> fetchAll() async {
    await MockData.delay();
    return MockData.salesOrders.map((m) {
      final clientName = m['client'] as String;
      return SalesOrder(
        id: _idCounter++,
        reference: m['reference'] as String,
        client: Client(id: 0, raisonSociale: clientName),
        dateCommande: '2024-05-${m['date']?.toString().substring(0, 2) ?? '15'}',
        statut: _statusFromLabel(m['statutLabel'] as String),
        totalTTC: m['totalTTC'] as double,
        lignes: List.generate(m['lignes'] as int, (i) => SalesOrderLine(
          id: i + 1,
          quantiteCommandee: Random().nextInt(100) + 10,
          prixUnitaireHT: Random().nextDouble() * 50 + 5,
        )),
      );
    }).toList();
  }

  @override
  Future<SalesOrder> create(SalesOrder order) async {
    await MockData.delay();
    return order;
  }

  @override
  Future<void> deliver(int orderId, Map<String, dynamic> payload) async {
    await MockData.delay();
  }

  @override
  Future<void> approve(int orderId) async {
    await MockData.delay();
  }

  @override
  Future<void> reject(int orderId) async {
    await MockData.delay();
  }

  @override
  Future<List<SalesOrder>> fetchPending() async {
    await MockData.delay();
    return [];
  }

  String _statusFromLabel(String label) {
    switch (label) {
      case 'En cours': return 'EN_PREPARATION';
      case 'Livrée': return 'COMPLETEMENT_LIVREE';
      case 'En attente': return 'CONFIRMEE';
      default: return 'CONFIRMEE';
    }
  }
}

class MockPurchaseOrderService implements PurchaseOrderService {
  final List<String> _fournisseurNames = [
    'POLYMERGY TUNISIE', 'CHIMIPLAST S.A.', 'EUROPLAST GmbH',
  ];

  int _idCounter = 100;

  @override
  Future<List<PurchaseOrder>> fetchAll() async {
    await MockData.delay();
    return MockData.purchaseOrders.map((m) {
      final fournisseurName = m['fournisseur'] as String;
      return PurchaseOrder(
        id: _idCounter++,
        reference: m['reference'] as String,
        fournisseur: Fournisseur(id: 0, raisonSociale: fournisseurName),
        dateCommande: '2024-05-${m['date']?.toString().substring(0, 2) ?? '10'}',
        statut: _statusFromLabel(m['statutLabel'] as String),
        totalTTC: m['totalTTC'] as double,
        lignes: List.generate(m['lignes'] as int, (i) => PurchaseOrderLine(
          id: i + 1,
          quantiteCommandee: Random().nextInt(500) + 50,
          prixUnitaireHT: Random().nextDouble() * 20 + 2,
        )),
      );
    }).toList();
  }

  @override
  Future<PurchaseOrder> create(PurchaseOrder order) async {
    await MockData.delay();
    return order;
  }

  @override
  Future<void> receive(int orderId, Map<String, dynamic> payload) async {
    await MockData.delay();
  }

  String _statusFromLabel(String label) {
    switch (label) {
      case 'Reçue': return 'COMPLETEMENT_RECUE';
      case 'En cours': return 'CONFIRMEE';
      case 'En attente': return 'BROUILLON';
      default: return 'CONFIRMEE';
    }
  }
}

class MockProductionService implements ProductionService {
  int _idCounter = 100;

  @override
  Future<List<ProductionOrder>> fetchAll() async {
    await MockData.delay();
    return MockData.productionOrders.map((m) => ProductionOrder(
      id: _idCounter++,
      reference: m['reference'] as String,
      quantitePlanifiee: (m['quantite'] as int).toDouble(),
      quantiteRealisee: (m['realisee'] as int).toDouble(),
      datePlanifiee: '2024-05-${m['date']?.toString().substring(0, 2) ?? '15'}',
      statut: _statusFromLabel(m['statutLabel'] as String),
    )).toList();
  }

  @override
  Future<List<BomLine>> getBom(int produitFiniId) async {
    await MockData.delay();
    return [];
  }

  @override
  Future<ProductionOrder> plan({
    required int produitFiniId,
    required double quantite,
    required String datePlanifiee,
  }) async {
    await MockData.delay();
    return ProductionOrder(
      id: _idCounter++,
      reference: 'OF-2024-${_idCounter.toString().padLeft(3, '0')}',
      statut: 'PLANIFIE',
      quantitePlanifiee: quantite,
      quantiteRealisee: 0,
      datePlanifiee: datePlanifiee,
    );
  }

  @override
  Future<ProductionOrder> launch(int id) async {
    await MockData.delay();
    return ProductionOrder(
      id: id,
      reference: 'OF-2024-0$id',
      statut: 'LANCE',
      quantitePlanifiee: 100,
      quantiteRealisee: 0,
      datePlanifiee: '2024-05-20',
    );
  }

  @override
  Future<ProductionOrder> complete(int id, double quantiteRealisee) async {
    await MockData.delay();
    return ProductionOrder(
      id: id,
      reference: 'OF-2024-0$id',
      statut: 'TERMINE',
      quantitePlanifiee: 100,
      quantiteRealisee: quantiteRealisee,
      datePlanifiee: '2024-05-20',
    );
  }

  String _statusFromLabel(String label) {
    switch (label) {
      case 'Lancé': return 'LANCE';
      case 'Planifié': return 'PLANIFIE';
      case 'Terminé': return 'TERMINE';
      case 'En cours': return 'EN_COURS';
      default: return 'PLANIFIE';
    }
  }
}

class MockStockService implements StockService {
  int _idCounter = 200;

  @override
  Future<List<StockMovement>> getHistorique(int articleId) async {
    await MockData.delay();
    return List.generate(5, (i) => StockMovement(
      id: _idCounter++,
      type: i % 2 == 0 ? 'IN' : 'OUT',
      quantite: (i + 1) * 10.0,
      motif: i % 2 == 0 ? 'Réception fournisseur' : 'Utilisation production',
      dateHeure: '2024-05-${15 - i}T10:00:00',
    ));
  }

  @override
  Future<StockMovement> adjust({
    required int articleId,
    required double quantite,
    required String type,
    required String motif,
  }) async {
    await MockData.delay();
    return StockMovement(
      id: _idCounter++,
      type: type,
      quantite: quantite,
      motif: motif,
      dateHeure: DateTime.now().toIso8601String(),
    );
  }
}

class MockUserService implements UserService {
  int _idCounter = 100;

  List<User> _mockUsers() => MockConfig.mockUsers
      .where((mu) => mu.role != 'ROLE_CLIENT')
      .toList()
      .asMap()
      .entries
      .map((e) => User(
            id: e.key + 1,
            username: e.value.username,
            email: e.value.email,
            firstName: e.value.firstName,
            lastName: e.value.lastName,
            enabled: true,
            roles: [e.value.role],
          ))
      .toList();

  @override
  Future<List<User>> fetchAll() async {
    await MockData.delay();
    return _mockUsers();
  }

  @override
  Future<User> getById(int id) async {
    await MockData.delay();
    return _mockUsers().firstWhere((u) => u.id == id);
  }

  @override
  Future<User> create(Map<String, dynamic> data) async {
    await MockData.delay();
    final user = User(
      id: _idCounter++,
      username: data['username'] as String,
      email: data['email'] as String,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      enabled: true,
      roles: List<String>.from(data['roles'] as List),
    );
    return user;
  }

  @override
  Future<User> update(int id, Map<String, dynamic> data) async {
    await MockData.delay();
    final existing = _mockUsers().firstWhere((u) => u.id == id);
    return User(
      id: id,
      username: data['username'] as String? ?? existing.username,
      email: data['email'] as String? ?? existing.email,
      firstName: data['firstName'] as String? ?? existing.firstName,
      lastName: data['lastName'] as String? ?? existing.lastName,
      enabled: data['enabled'] as bool? ?? existing.enabled,
      roles: data['roles'] != null
          ? List<String>.from(data['roles'] as List)
          : existing.roles,
    );
  }

  @override
  Future<void> setPassword(int id, String password) async {
    await MockData.delay();
  }

  @override
  Future<void> disable(int id) async {
    await MockData.delay();
  }

  @override
  Future<void> enable(int id) async {
    await MockData.delay();
  }
}

class MockCatalogService implements CatalogService {
  List<Article> _articles = [];

  @override
  Future<List<Article>> fetchCatalog() async {
    await MockData.delay();
    if (_articles.isEmpty) {
      _articles = MockData.articles
          .map((m) => Article.fromJson(m))
          .where((a) => a.type == 'PF')
          .toList();
    }
    return List.from(_articles);
  }

  @override
  Future<Article> fetchArticle(int id) async {
    await MockData.delay();
    if (_articles.isEmpty) await fetchCatalog();
    return _articles.firstWhere((a) => a.id == id);
  }
}

class MockClientOrderService implements ClientOrderService {
  @override
  Future<List<SalesOrder>> fetchMyOrders() async {
    await MockData.delay();
    return [];
  }

  @override
  Future<SalesOrder> createOrder(Map<String, dynamic> data) async {
    await MockData.delay();
    throw UnimplementedError('Mock: createOrder');
  }

  @override
  Future<void> cancelOrder(int id) async {
    await MockData.delay();
  }
}

class MockNotificationService implements NotificationService {
  @override
  Future<int> getUnreadCount() async {
    await MockData.delay();
    return 0;
  }

  @override
  Future<List<AppNotification>> getAll() async {
    await MockData.delay();
    return [];
  }

  @override
  Future<void> markAsRead(int id) async {
    await MockData.delay();
  }

  @override
  Future<void> markAllAsRead() async {
    await MockData.delay();
  }
}
