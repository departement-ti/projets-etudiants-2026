import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/supabase_service.dart';
import 'features/chat/presentation/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://your-project.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'your-anon-key',
    ),
  );
  runApp(
    const ProviderScope(
      child: SmartSupportApp(),
    ),
  );
}

class SmartSupportApp extends ConsumerWidget {
  const SmartSupportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(currentCompanyProvider);
    final company = companyAsync.valueOrNull;
    final theme = company != null && company.primaryColor != null && company.primaryColor!.isNotEmpty
        ? AppTheme.themeWithPrimary(company.primaryColor!)
        : AppTheme.lightTheme;
    return MaterialApp.router(
      title: 'Smart Support AI',
      theme: theme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
