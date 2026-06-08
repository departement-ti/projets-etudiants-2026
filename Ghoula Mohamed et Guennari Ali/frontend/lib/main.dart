import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rayhan_erp/constants/app_theme.dart';
import 'package:rayhan_erp/services/auth_service.dart';
import 'package:rayhan_erp/services/article_service.dart';
import 'package:rayhan_erp/services/dashboard_service.dart';
import 'package:rayhan_erp/services/client_service.dart';
import 'package:rayhan_erp/services/fournisseur_service.dart';
import 'package:rayhan_erp/services/sales_order_service.dart';
import 'package:rayhan_erp/services/purchase_order_service.dart';
import 'package:rayhan_erp/services/production_service.dart';
import 'package:rayhan_erp/services/stock_service.dart';
import 'package:rayhan_erp/services/user_service.dart';
import 'package:rayhan_erp/services/catalog_service.dart';
import 'package:rayhan_erp/services/client_order_service.dart';
import 'package:rayhan_erp/services/notification_service.dart';
import 'package:rayhan_erp/mock/mock_services.dart';
import 'package:rayhan_erp/mock/mock_config.dart';
import 'package:rayhan_erp/providers/auth_provider.dart';
import 'package:rayhan_erp/providers/dashboard_provider.dart';
import 'package:rayhan_erp/providers/article_provider.dart';
import 'package:rayhan_erp/providers/ventes_provider.dart';
import 'package:rayhan_erp/providers/achats_provider.dart';
import 'package:rayhan_erp/providers/production_provider.dart';
import 'package:rayhan_erp/providers/clients_provider.dart';
import 'package:rayhan_erp/providers/fournisseurs_provider.dart';
import 'package:rayhan_erp/providers/stock_provider.dart';
import 'package:rayhan_erp/providers/user_provider.dart';
import 'package:rayhan_erp/providers/catalog_provider.dart';
import 'package:rayhan_erp/providers/client_order_provider.dart';
import 'package:rayhan_erp/providers/notification_provider.dart';
import 'package:rayhan_erp/screens/landing_screen.dart';
import 'package:rayhan_erp/screens/login_screen.dart';
import 'package:rayhan_erp/screens/dashboard_screen.dart';
import 'package:rayhan_erp/screens/articles_screen.dart';
import 'package:rayhan_erp/screens/ventes_screen.dart';
import 'package:rayhan_erp/screens/achats_screen.dart';
import 'package:rayhan_erp/screens/production_screen.dart';
import 'package:rayhan_erp/screens/stock_screen.dart';
import 'package:rayhan_erp/screens/signup_screen.dart';
import 'package:rayhan_erp/screens/forgot_password_screen.dart';
import 'package:rayhan_erp/screens/rapports_screen.dart';
import 'package:rayhan_erp/screens/utilisateurs_screen.dart';
import 'package:rayhan_erp/screens/clients_screen.dart';
import 'package:rayhan_erp/screens/fournisseurs_screen.dart';
import 'package:rayhan_erp/screens/catalog_screen.dart';
import 'package:rayhan_erp/screens/product_detail_screen.dart';
import 'package:rayhan_erp/screens/client_order_form_screen.dart';
import 'package:rayhan_erp/screens/client_orders_screen.dart';
import 'package:rayhan_erp/screens/client_order_detail_screen.dart';
import 'package:rayhan_erp/screens/profile_screen.dart';
import 'package:rayhan_erp/widgets/role_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('fr_TN');

  final useMock = MockConfig.useMock;

  final AuthService authService =
      useMock ? MockAuthService() : RealAuthService();
  final auth = AuthProvider(authService: authService);
  await auth.checkAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(
            create: (_) => DashboardProvider(
                  dashboardService:
                      useMock ? MockDashboardService() : RealDashboardService(),
                )),
        ChangeNotifierProvider(
            create: (_) => ArticleProvider(
                  articleService:
                      useMock ? MockArticleService() : RealArticleService(),
                )),
        ChangeNotifierProvider(
            create: (_) => VentesProvider(
                  salesOrderService: useMock
                      ? MockSalesOrderService()
                      : RealSalesOrderService(),
                  clientService:
                      useMock ? MockClientService() : RealClientService(),
                )),
        ChangeNotifierProvider(
            create: (_) => AchatsProvider(
                  purchaseOrderService: useMock
                      ? MockPurchaseOrderService()
                      : RealPurchaseOrderService(),
                  fournisseurService: useMock
                      ? MockFournisseurService()
                      : RealFournisseurService(),
                )),
        ChangeNotifierProvider(
            create: (_) => ClientsProvider(
                  clientService:
                      useMock ? MockClientService() : RealClientService(),
                )),
        ChangeNotifierProvider(
            create: (_) => FournisseursProvider(
                  fournisseurService: useMock
                      ? MockFournisseurService()
                      : RealFournisseurService(),
                )),
        ChangeNotifierProvider(
            create: (_) => ProductionProvider(
                  productionService: useMock
                      ? MockProductionService()
                      : RealProductionService(),
                )),
        ChangeNotifierProvider(
            create: (_) => StockProvider(
                  stockService:
                      useMock ? MockStockService() : RealStockService(),
                )),
        ChangeNotifierProvider(
            create: (_) => UserProvider(
                  userService: useMock ? MockUserService() : RealUserService(),
                )),
        ChangeNotifierProvider(
            create: (_) => CatalogProvider(
                  catalogService:
                      useMock ? MockCatalogService() : RealCatalogService(),
                )),
        ChangeNotifierProvider(
            create: (_) => ClientOrderProvider(
                  clientOrderService: useMock
                      ? MockClientOrderService()
                      : RealClientOrderService(),
                )),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider(
                  notificationService: useMock
                      ? MockNotificationService()
                      : RealNotificationService(),
                )),
      ],
      child: const RayhanApp(),
    ),
  );
}

class RayhanApp extends StatefulWidget {
  const RayhanApp({super.key});

  @override
  State<RayhanApp> createState() => _RayhanAppState();
}

class _RayhanAppState extends State<RayhanApp> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_router == null) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _router = GoRouter(
        initialLocation: '/',
        refreshListenable: auth,
        redirect: (_, state) {
          final loggedIn = auth.isAuthenticated;
          final role = auth.role;
          final onLoginForm = state.matchedLocation == '/login';
          final publicRoutes = ['/', '/login', '/signup', '/forgot-password'];
          final isPublic = publicRoutes.any((r) =>
              state.matchedLocation == r ||
              state.matchedLocation.startsWith('/catalogue'));

          if (!loggedIn &&
              state.matchedLocation.startsWith('/catalogue/commander')) {
            final redirect = Uri.encodeComponent(state.matchedLocation);
            return '/login?redirect=$redirect';
          }
          if (!loggedIn && !isPublic) {
            return '/login';
          }
          if (loggedIn && (onLoginForm || state.matchedLocation == '/')) {
            final defaultRoute = RoleGuard.getDefaultRoute(role);
            if (state.matchedLocation != defaultRoute) {
              return defaultRoute;
            }
          }
          if (loggedIn && !isPublic) {
            if (!RoleGuard.hasAccess(role, state.matchedLocation)) {
              return RoleGuard.getDefaultRoute(role);
            }
          }
          return null;
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
          GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/articles', builder: (_, __) => const ArticlesScreen()),
          GoRoute(path: '/ventes', builder: (_, __) => const VentesScreen()),
          GoRoute(path: '/clients', builder: (_, __) => const ClientsScreen()),
          GoRoute(path: '/achats', builder: (_, __) => const AchatsScreen()),
          GoRoute(
              path: '/fournisseurs',
              builder: (_, __) => const FournisseursScreen()),
          GoRoute(
              path: '/production',
              builder: (_, __) => const ProductionScreen()),
          GoRoute(path: '/stock', builder: (_, __) => const StockScreen()),
          GoRoute(
              path: '/rapports', builder: (_, __) => const RapportsScreen()),
          GoRoute(
              path: '/utilisateurs',
              builder: (_, __) => const UtilisateursScreen()),
          GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
          GoRoute(
              path: '/forgot-password',
              builder: (_, __) => const ForgotPasswordScreen()),
          GoRoute(
              path: '/catalogue', builder: (_, __) => const CatalogScreen()),
          GoRoute(
              path: '/catalogue/:id',
              builder: (_, __) => const ProductDetailScreen()),
          GoRoute(
              path: '/catalogue/commander',
              builder: (_, __) => const ClientOrderFormScreen()),
          GoRoute(
              path: '/mes-commandes',
              builder: (_, __) => const ClientOrdersScreen()),
          GoRoute(
              path: '/mes-commandes/:id',
              builder: (_, __) => const ClientOrderDetailScreen()),
          GoRoute(
              path: '/mon-profil', builder: (_, __) => const ProfileScreen()),
        ],
      );
    }
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) return const SizedBox.shrink();
    return MaterialApp.router(
      title: 'RayhanERP | La Précision Industrielle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router!,
      //scrollBehavior: const _WebScrollBehavior(),
    );
  }
}

class _WebScrollBehavior extends MaterialScrollBehavior {
  const _WebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
