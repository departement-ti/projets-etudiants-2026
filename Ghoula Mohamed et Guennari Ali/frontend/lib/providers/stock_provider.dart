import 'package:flutter/material.dart';
import '../models/stock_movement.dart';
import '../services/stock_service.dart';

class StockProvider extends ChangeNotifier {
  final StockService stockService;

  StockProvider({required this.stockService});

  final Map<int, List<StockMovement>> _historiques = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<StockMovement> historiqueOf(int articleId) => _historiques[articleId] ?? [];

  Future<void> loadHistorique(int articleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _historiques[articleId] = await stockService.getHistorique(articleId);
    } catch (_) {
      _error = 'Impossible de charger l\'historique.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> adjust({
    required int articleId,
    required double quantite,
    required String type,
    required String motif,
  }) async {
    try {
      final mouvement = await stockService.adjust(
        articleId: articleId,
        quantite: quantite,
        type: type,
        motif: motif,
      );
      _historiques[articleId] = [mouvement, ...(_historiques[articleId] ?? [])];
      notifyListeners();
      return null;
    } catch (_) {
      return 'Erreur lors de l\'ajustement du stock';
    }
  }
}
