import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fournisseurs_provider.dart';
import '../models/fournisseur.dart';
import '../widgets/app_drawer.dart';
import '../widgets/brand_app_bar.dart';
import '../constants/app_theme.dart';
import 'fournisseur_detail_screen.dart';
import 'fournisseur_form_screen.dart';

class FournisseursScreen extends StatefulWidget {
  const FournisseursScreen({super.key});

  @override
  State<FournisseursScreen> createState() => _FournisseursScreenState();
}

class _FournisseursScreenState extends State<FournisseursScreen> {
  Fournisseur? _selectedFournisseur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FournisseursProvider>().load();
    });
  }

  bool get _isDesktop => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FournisseursProvider>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(BrandAppBar.heightFor(context)),
        child: BrandAppBar(
          title: 'Fournisseurs',
          subtitle: !provider.isLoading
              ? '${provider.fournisseurs.length} fournisseur(s)'
              : null,
          currentRoute: '/fournisseurs',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => context.read<FournisseursProvider>().load(),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/fournisseurs'),
      floatingActionButton: _isDesktop && _selectedFournisseur != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const FournisseurFormScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau fournisseur'),
            ),
      body: AppTheme.glassBackground(
        child: _isDesktop && _selectedFournisseur != null
            ? Row(
                children: [
                  SizedBox(
                    width: 380,
                    child: _buildBody(provider),
                  ),
                  Container(width: 1, color: AppTheme.kBorderLight),
                  Expanded(
                    child: FournisseurDetailScreen(
                      fournisseur: _selectedFournisseur!,
                      isEmbedded: true,
                    ),
                  ),
                ],
              )
            : _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(FournisseursProvider provider) {
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
              onPressed: () => context.read<FournisseursProvider>().load(),
              style: AppTheme.primaryButton,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (provider.fournisseurs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 64, color: AppTheme.kBorderLight),
            const SizedBox(height: 16),
            Text('Aucun fournisseur',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FournisseurFormScreen())),
              child: const Text('Créer le premier fournisseur'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<FournisseursProvider>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.fournisseurs.length,
        itemBuilder: (ctx, i) => _FournisseurCard(
          fournisseur: provider.fournisseurs[i],
          isSelected: _selectedFournisseur?.id == provider.fournisseurs[i].id,
          onTap: _isDesktop
              ? () => setState(() => _selectedFournisseur = provider.fournisseurs[i])
              : () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => FournisseurDetailScreen(fournisseur: provider.fournisseurs[i]))),
        ),
      ),
    );
  }
}

class _FournisseurCard extends StatelessWidget {
  final Fournisseur fournisseur;
  final bool isSelected;
  final VoidCallback onTap;
  const _FournisseurCard({required this.fournisseur, this.isSelected = false, required this.onTap});

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
                  border: Border.all(color: AppTheme.kSuccessGreen, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: fournisseur.actif
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fournisseur.raisonSociale,
                            style: AppTheme.titleSmall.copyWith(fontSize: 15)),
                        const SizedBox(height: 8),
                        if (fournisseur.matriculeFiscal != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.badge_outlined,
                                    size: 14, color: AppTheme.kTextSecondary),
                                const SizedBox(width: 4),
                                Text('MF: ${fournisseur.matriculeFiscal}',
                                    style: AppTheme.bodySmall
                                        .copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 13, color: AppTheme.kTextSecondary),
                            const SizedBox(width: 4),
                            Text(fournisseur.telephone ?? '—',
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.kTextSecondary)),
                            const SizedBox(width: 16),
                            const Icon(Icons.email_outlined,
                                size: 13, color: AppTheme.kTextSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(fournisseur.email ?? '—',
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppTheme.kTextSecondary)),
                            ),
                          ],
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
