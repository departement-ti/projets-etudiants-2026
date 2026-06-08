import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/client_service.dart';

class ClientsProvider extends ChangeNotifier {
  final ClientService clientService;

  ClientsProvider({required this.clientService});

  List<Client> _clients = [];
  bool _isLoading = false;
  String? _error;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _clients = await clientService.fetchAll();
    } catch (_) {
      _error = 'Impossible de charger les clients.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Client?> createWithUser({
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
    try {
      final created = await clientService.createWithUser(
        raisonSociale: raisonSociale,
        matriculeFiscal: matriculeFiscal,
        adresse: adresse,
        telephone: telephone,
        email: email,
        ville: ville,
        typeClient: typeClient,
        plafondCredit: plafondCredit,
        delaiPaiement: delaiPaiement,
        representantNom: representantNom,
        representantTelephone: representantTelephone,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
      _clients.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Erreur lors de la création du client.';
      notifyListeners();
      return null;
    }
  }

  Future<Client?> update(int id, Client client) async {
    try {
      final updated = await clientService.update(id, client);
      final idx = _clients.indexWhere((c) => c.id == id);
      if (idx != -1) _clients[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour.';
      notifyListeners();
      return null;
    }
  }
}
