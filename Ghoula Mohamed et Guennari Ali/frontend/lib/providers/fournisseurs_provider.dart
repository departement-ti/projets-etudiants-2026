import 'package:flutter/material.dart';
import '../models/fournisseur.dart';
import '../services/fournisseur_service.dart';

class FournisseursProvider extends ChangeNotifier {
  final FournisseurService fournisseurService;

  FournisseursProvider({required this.fournisseurService});

  List<Fournisseur> _fournisseurs = [];
  bool _isLoading = false;
  String? _error;

  List<Fournisseur> get fournisseurs => _fournisseurs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _fournisseurs = await fournisseurService.fetchAll();
    } catch (_) {
      _error = 'Impossible de charger les fournisseurs.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Fournisseur?> create(Fournisseur f) async {
    try {
      final created = await fournisseurService.create(f);
      _fournisseurs.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Erreur lors de la création.';
      notifyListeners();
      return null;
    }
  }

  Future<Fournisseur?> update(int id, Fournisseur f) async {
    try {
      final updated = await fournisseurService.update(id, f);
      final idx = _fournisseurs.indexWhere((c) => c.id == id);
      if (idx != -1) _fournisseurs[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour.';
      notifyListeners();
      return null;
    }
  }
}
