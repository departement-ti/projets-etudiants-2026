import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../constants/app_theme.dart';
import 'utilisateur_detail_screen.dart';
import 'utilisateur_form_screen.dart';

class UtilisateursScreen extends StatefulWidget {
  const UtilisateursScreen({super.key});

  @override
  State<UtilisateursScreen> createState() => _UtilisateursScreenState();
}

class _UtilisateursScreenState extends State<UtilisateursScreen> {
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().load();
    });
  }

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context)),
        child: BrandAppBar(
          title: 'Utilisateurs',
          subtitle: !provider.isLoading
              ? '${provider.users.length} utilisateur(s)'
              : null,
          currentRoute: '/utilisateurs',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => context.read<UserProvider>().load(),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/utilisateurs'),
      floatingActionButton: _isDesktop && _selectedUser != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const UtilisateurFormScreen())),
              icon: const Icon(Icons.person_add),
              label: const Text('Nouvel utilisateur'),
            ),
      body: AppTheme.glassBackground(
        child: _isDesktop && _selectedUser != null
            ? Row(
                children: [
                  SizedBox(
                    width: 380,
                    child: _buildBody(provider),
                  ),
                  Container(width: 1, color: AppTheme.kBorderLight),
                  Expanded(
                    child: UtilisateurDetailScreen(
                      user: _selectedUser!,
                      isEmbedded: true,
                    ),
                  ),
                ],
              )
            : _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(UserProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.kTextHint),
            const SizedBox(height: 12),
            Text(provider.error!,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<UserProvider>().load(),
              style: AppTheme.primaryButton,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: AppTheme.kBorderLight),
            const SizedBox(height: 16),
            Text('Aucun utilisateur',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UtilisateurFormScreen())),
              child: const Text('Créer le premier utilisateur'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<UserProvider>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.users.length,
        itemBuilder: (ctx, i) => _UserCard(
          user: provider.users[i],
          isSelected: _selectedUser?.id == provider.users[i].id,
          onTap: _isDesktop
              ? () => setState(() => _selectedUser = provider.users[i])
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => UtilisateurDetailScreen(user: provider.users[i]))),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final bool isSelected;
  final VoidCallback onTap;
  const _UserCard({required this.user, this.isSelected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppTheme.withGlass(
        radius: 12,
        blur: 16,
        opacity: 0.7,
        margin: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: user.roleColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: user.enabled
                        ? AppTheme.kSuccessGreen
                        : AppTheme.kTextHint,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: user.roleColor.withValues(alpha: 0.2),
                          child: Text(user.initials,
                              style: TextStyle(
                                  color: user.roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.displayName,
                                  style: AppTheme.titleSmall.copyWith(fontSize: 15)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined,
                                      size: 12, color: AppTheme.kTextSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(user.email,
                                        style: AppTheme.bodySmall
                                            .copyWith(fontSize: 11),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (user.roles.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              User.roleLabelFor(user.roles.first),
                              style: TextStyle(
                                  color: user.roleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
