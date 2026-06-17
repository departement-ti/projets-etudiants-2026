import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/auth_service.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(currentCompanyProvider).valueOrNull;
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          if (company != null) ...[
            const _SectionHeader(title: 'Branding'),
            ListTile(
              leading: const Icon(Icons.business_rounded),
              title: const Text('Company'),
              subtitle: Text(company.name),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Primary color'),
              subtitle: Text(company.primaryColor ?? '#6366F1'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Welcome message'),
              subtitle: Text(company.welcomeMessage ?? 'Not set'),
            ),
            const Divider(),
            const _SectionHeader(title: 'Human handoff'),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Support email'),
              subtitle: Text(company.supportEmail ?? 'Not set'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_rounded),
              title: const Text('WhatsApp'),
              subtitle: Text(company.supportWhatsapp ?? 'Not set'),
            ),
          ],
          const Divider(),
          const _SectionHeader(title: 'Account'),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Email'),
              subtitle: Text(user.email),
            ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Integration'),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('Integration code'),
            subtitle: const Text('Web widget, Flutter SDK, API'),
            onTap: () => _showIntegrationDialog(context, company?.id ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Help & docs'),
            onTap: () => launchUrl(Uri.parse('https://supabase.com/docs')),
          ),
        ],
      ),
    );
  }

  void _showIntegrationDialog(BuildContext context, String companyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chatbot integration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Web widget (paste before </body>):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SelectableText(
                '<script src="https://your-cdn.com/smart-support-widget.js" data-company-id="$companyId"></script>',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text('2. Flutter SDK (embed in your app):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const SelectableText(
                'SmartSupportChatWidget(companyId: \'YOUR_COMPANY_ID\')',
                style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text('3. REST endpoint:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SelectableText(
                'POST /v1/chat\nBody: {"company_id":"$companyId","message":"user text"}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
