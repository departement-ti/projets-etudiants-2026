import 'api_client.dart';
import '../models/article.dart';

abstract class CatalogService {
  Future<List<Article>> fetchCatalog();
  Future<Article> fetchArticle(int id);
}

class RealCatalogService implements CatalogService {
  @override
  Future<List<Article>> fetchCatalog() async {
    final res = await ApiClient.instance.get('/public/articles');
    return (res.data as List).map((e) => Article.fromJson(e)).toList();
  }

  @override
  Future<Article> fetchArticle(int id) async {
    final res = await ApiClient.instance.get('/public/articles/$id');
    return Article.fromJson(res.data);
  }
}
