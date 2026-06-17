import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/supabase_service.dart';

class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _welcomeController = TextEditingController(text: 'Hello! How can I help you today?');
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _companyNameController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final uid = SupabaseService.instance.currentUserId;
      if (uid == null) {
        setState(() {
          _error = 'Not signed in';
          _loading = false;
        });
        return;
      }
      final company = await _authService.createCompany(
        name: _companyNameController.text.trim(),
        welcomeMessage: _welcomeController.text.trim().isEmpty ? null : _welcomeController.text.trim(),
      );
      await _authService.createAppUser(
        uid: uid,
        companyId: company.id,
        email: SupabaseService.instance.currentUser?.email ?? '',
        role: 'admin',
      );
      if (!mounted) return;
      context.go('/chat');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Create your company',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will be your workspace and chatbot tenant.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
                  ),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company name',
                    hintText: 'Acme Inc.',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter company name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _welcomeController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Welcome message (optional)',
                    hintText: 'Hello! How can I help?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _loading ? null : () {
                    if (_formKey.currentState?.validate() ?? false) _createCompany();
                  },
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create company & continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
