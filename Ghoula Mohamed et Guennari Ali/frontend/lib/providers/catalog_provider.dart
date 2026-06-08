import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/catalog_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService catalogService;

  CatalogProvider({required this.catalogService});

  List<Article> _articles = [];
  List<Article> _filtered = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';

  List<Article> get articles => _filtered;
  List<Article> get allArticles => _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _articles = await catalogService.fetchCatalog();
      _applyFilter();
    } catch (e) {
      _error = 'Impossible de charger le catalogue';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _search = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_search.isEmpty) {
      _filtered = List.from(_articles);
    } else {
      _filtered = _articles
          .where((a) => a.designation.toLowerCase().contains(_search))
          .toList();
    }
  }
}
