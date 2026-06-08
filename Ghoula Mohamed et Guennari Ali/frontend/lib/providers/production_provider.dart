import 'package:flutter/material.dart';
import '../models/production_order.dart';
import '../services/production_service.dart';

class ProductionProvider extends ChangeNotifier {
  final ProductionService productionService;

  ProductionProvider({required this.productionService});

  List<ProductionOrder> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<ProductionOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get ofPlanifies => _orders.where((o) => o.statut == 'PLANIFIE').length;
  int get ofEnCours => _orders.where((o) => o.statut == 'LANCE' || o.statut == 'EN_COURS').length;
  int get ofTermines => _orders.where((o) => o.statut == 'TERMINE').length;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await productionService.fetchAll();
    } catch (_) {
      _error = 'Impossible de charger les ordres de fabrication.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> plan({
    required int produitFiniId,
    required double quantite,
    required String datePlanifiee,
  }) async {
    try {
      final of = await productionService.plan(
        produitFiniId: produitFiniId,
        quantite: quantite,
        datePlanifiee: datePlanifiee,
      );
      _orders.insert(0, of);
      notifyListeners();
      return null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Stock insuffisant')) return 'Stock matières premières insuffisant';
      if (msg.contains('nomenclature')) return 'Aucune nomenclature BOM définie pour ce produit';
      return 'Erreur lors de la planification';
    }
  }

  Future<String?> launch(int id) async {
    try {
      final updated = await productionService.launch(id);
      _replaceOrder(updated);
      return null;
    } catch (_) {
      return 'Erreur lors du lancement de l\'OF';
    }
  }

  Future<String?> complete(int id, double quantiteRealisee) async {
    try {
      final updated = await productionService.complete(id, quantiteRealisee);
      _replaceOrder(updated);
      return null;
    } catch (_) {
      return 'Erreur lors de la clôture de l\'OF';
    }
  }

  void _replaceOrder(ProductionOrder updated) {
    final idx = _orders.indexWhere((o) => o.id == updated.id);
    if (idx != -1) _orders[idx] = updated;
    notifyListeners();
  }
}
