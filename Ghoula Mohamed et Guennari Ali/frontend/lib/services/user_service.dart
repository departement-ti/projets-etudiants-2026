import 'api_client.dart';
import '../models/user.dart';

abstract class UserService {
  Future<List<User>> fetchAll();
  Future<User> getById(int id);
  Future<User> create(Map<String, dynamic> data);
  Future<User> update(int id, Map<String, dynamic> data);
  Future<void> setPassword(int id, String password);
  Future<void> disable(int id);
  Future<void> enable(int id);
}

class RealUserService implements UserService {
  @override
  Future<List<User>> fetchAll() async {
    final res = await ApiClient.instance.get('/users');
    return (res.data as List).map((e) => User.fromJson(e)).toList();
  }

  @override
  Future<User> getById(int id) async {
    final res = await ApiClient.instance.get('/users/$id');
    return User.fromJson(res.data);
  }

  @override
  Future<User> create(Map<String, dynamic> data) async {
    final res = await ApiClient.instance.post('/users', data: data);
    return User.fromJson(res.data);
  }

  @override
  Future<User> update(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/users/$id', data: data);
    return User.fromJson(res.data);
  }

  @override
  Future<void> setPassword(int id, String password) async {
    await ApiClient.instance.put('/users/$id/password', data: {'password': password});
  }

  @override
  Future<void> disable(int id) async {
    await ApiClient.instance.delete('/users/$id');
  }

  @override
  Future<void> enable(int id) async {
    await ApiClient.instance.put('/users/$id/enable');
  }
}
