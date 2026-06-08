import 'api_client.dart';
import '../models/article.dart';

abstract class ArticleService {
  Future<List<Article>> fetchAll();
  Future<List<Article>> fetchByType(String type);
  Future<Article> create(Article article);
  Future<Article> update(int id, Article article);
  Future<void> delete(int id);
}

class RealArticleService implements ArticleService {
  @override
  Future<List<Article>> fetchAll() async {
    final res = await ApiClient.instance.get('/articles');
    return (res.data as List).map((e) => Article.fromJson(e)).toList();
  }

  @override
  Future<List<Article>> fetchByType(String type) async {
    final res = await ApiClient.instance.get('/articles/type/$type');
    return (res.data as List).map((e) => Article.fromJson(e)).toList();
  }

  @override
  Future<Article> create(Article article) async {
    final res = await ApiClient.instance.post('/articles', data: article.toJson());
    return Article.fromJson(res.data);
  }

  @override
  Future<Article> update(int id, Article article) async {
    final res = await ApiClient.instance.put('/articles/$id', data: article.toJson());
    return Article.fromJson(res.data);
  }

  @override
  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/articles/$id');
  }
}
