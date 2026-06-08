import 'api_client.dart';
import '../models/dashboard_kpi.dart';

abstract class DashboardService {
  Future<DashboardKpi> fetchKpis();
}

class RealDashboardService implements DashboardService {
  @override
  Future<DashboardKpi> fetchKpis() async {
    final response = await ApiClient.instance.get('/dashboard');
    return DashboardKpi.fromJson(response.data as Map<String, dynamic>);
  }
}
