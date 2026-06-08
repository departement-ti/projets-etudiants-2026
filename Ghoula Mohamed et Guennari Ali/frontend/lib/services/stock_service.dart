import 'api_client.dart';
import '../models/stock_movement.dart';

abstract class StockService {
  Future<List<StockMovement>> getHistorique(int articleId);
  Future<StockMovement> adjust({
    required int articleId,
    required double quantite,
    required String type,
    required String motif,
  });
}

class RealStockService implements StockService {
  @override
  Future<List<StockMovement>> getHistorique(int articleId) async {
    final res = await ApiClient.instance.get('/stock/historique/$articleId');
    return (res.data as List).map((e) => StockMovement.fromJson(e)).toList();
  }

  @override
  Future<StockMovement> adjust({
    required int articleId,
    required double quantite,
    required String type,
    required String motif,
  }) async {
    final res = await ApiClient.instance.post('/stock/adjust', data: {
      'articleId': articleId,
      'quantite': quantite,
      'type': type,
      'motif': motif,
    });
    return StockMovement.fromJson(res.data);
  }
}
