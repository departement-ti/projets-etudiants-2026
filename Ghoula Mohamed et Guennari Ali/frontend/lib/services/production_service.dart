import 'api_client.dart';
import '../models/production_order.dart';

abstract class ProductionService {
  Future<List<ProductionOrder>> fetchAll();
  Future<List<BomLine>> getBom(int produitFiniId);
  Future<ProductionOrder> plan({
    required int produitFiniId,
    required double quantite,
    required String datePlanifiee,
  });
  Future<ProductionOrder> launch(int id);
  Future<ProductionOrder> complete(int id, double quantiteRealisee);
}

class RealProductionService implements ProductionService {
  @override
  Future<List<ProductionOrder>> fetchAll() async {
    final res = await ApiClient.instance.get('/production/orders');
    return (res.data as List).map((e) => ProductionOrder.fromJson(e)).toList();
  }

  @override
  Future<List<BomLine>> getBom(int produitFiniId) async {
    final res = await ApiClient.instance.get('/production/bom/$produitFiniId');
    return (res.data as List).map((e) => BomLine.fromJson(e)).toList();
  }

  @override
  Future<ProductionOrder> plan({
    required int produitFiniId,
    required double quantite,
    required String datePlanifiee,
  }) async {
    final res = await ApiClient.instance.post('/production/orders/plan', data: {
      'produitFiniId': produitFiniId,
      'quantite': quantite,
      'datePlanifiee': datePlanifiee,
    });
    return ProductionOrder.fromJson(res.data);
  }

  @override
  Future<ProductionOrder> launch(int id) async {
    final res = await ApiClient.instance.post('/production/orders/$id/launch');
    return ProductionOrder.fromJson(res.data);
  }

  @override
  Future<ProductionOrder> complete(int id, double quantiteRealisee) async {
    final res = await ApiClient.instance.post('/production/orders/$id/complete', data: {
      'quantiteRealisee': quantiteRealisee,
    });
    return ProductionOrder.fromJson(res.data);
  }
}
