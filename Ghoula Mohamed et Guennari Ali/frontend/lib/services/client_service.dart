import 'api_client.dart';
import '../models/client.dart';

abstract class ClientService {
  Future<List<Client>> fetchAll();
  Future<Client> getById(int id);
  Future<Client> create(Client client);
  Future<Client> update(int id, Client client);
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
  });
}

class RealClientService implements ClientService {
  @override
  Future<List<Client>> fetchAll() async {
    final res = await ApiClient.instance.get('/clients');
    return (res.data as List).map((e) => Client.fromJson(e)).toList();
  }

  @override
  Future<Client> getById(int id) async {
    final res = await ApiClient.instance.get('/clients/$id');
    return Client.fromJson(res.data);
  }

  @override
  Future<Client> create(Client client) async {
    final res = await ApiClient.instance.post('/clients', data: client.toJson());
    return Client.fromJson(res.data);
  }

  @override
  Future<Client> update(int id, Client client) async {
    final res = await ApiClient.instance.put('/clients/$id', data: client.toJson());
    return Client.fromJson(res.data);
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
    final res = await ApiClient.instance.post('/clients/with-user', data: {
      'raisonSociale': raisonSociale,
      if (matriculeFiscal != null) 'matriculeFiscal': matriculeFiscal,
      if (adresse != null) 'adresse': adresse,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (ville != null) 'ville': ville,
      if (typeClient != null) 'typeClient': typeClient,
      if (plafondCredit != null) 'plafondCredit': plafondCredit,
      if (delaiPaiement != null) 'delaiPaiement': delaiPaiement,
      if (representantNom != null) 'representantNom': representantNom,
      if (representantTelephone != null)
        'representantTelephone': representantTelephone,
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
    });
    return Client.fromJson(res.data);
  }
}
