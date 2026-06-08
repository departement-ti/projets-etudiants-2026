import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rayhan_erp/providers/auth_provider.dart';
import 'package:rayhan_erp/providers/catalog_provider.dart';
import 'package:rayhan_erp/providers/client_order_provider.dart';
import 'package:rayhan_erp/constants/app_theme.dart';
import 'package:rayhan_erp/services/pdf_service.dart';
import 'package:rayhan_erp/models/sales_order.dart';
import 'package:rayhan_erp/models/article.dart';
import 'package:rayhan_erp/models/client.dart';
import 'package:rayhan_erp/widgets/client_scaffold.dart';

class ClientOrderFormScreen extends StatefulWidget {
  const ClientOrderFormScreen({super.key});

  @override
  State<ClientOrderFormScreen> createState() => _ClientOrderFormScreenState();
}

class _ClientOrderFormScreenState extends State<ClientOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_OrderLigne> _lignes = [];
  final _notesCtrl = TextEditingController();
  DateTime? _dateLivraison;
  bool _isSubmitting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      if (catalog.articles.isEmpty && !catalog.isLoading) {
        catalog.load();
      }
      final params = GoRouterState.of(context).uri.queryParameters;
      final articleId = params['articleId'];
      final qteStr = params['quantite'];
      if (articleId != null) {
        final article = catalog.articles.where(
          (a) => a.id.toString() == articleId,
        ).firstOrNull;
        if (article != null) {
          final ligne = _OrderLigne();
          ligne.article = article;
          ligne.qtyCtrl.text = qteStr ?? '1';
          setState(() => _lignes.add(ligne));
        }
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lignes) { l.dispose(); }
    super.dispose();
  }

  void _addLigne() {
    setState(() => _lignes.add(_OrderLigne()));
  }

  void _removeLigne(int i) {
    setState(() {
      _lignes[i].dispose();
      _lignes.removeAt(i);
    });
  }

  double get _totalHT => _lignes.fold(0.0, (s, l) {
        final qte = double.tryParse(l.qtyCtrl.text) ?? 0;
        final pu = l.article?.prixUnitaire ?? 0;
        return s + qte * pu;
      });

  double get _totalTVA => _totalHT * 0.19;
  double get _totalTTC => _totalHT + _totalTVA;

  Future<Article?> _showArticlePicker() {
    final catalog = context.read<CatalogProvider>();
    final searchCtrl = TextEditingController();
    String query = '';

    return showDialog<Article>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final articles = query.isEmpty
              ? catalog.articles
              : catalog.articles.where((a) {
                  final q = query.toLowerCase();
                  return a.designation.toLowerCase().contains(q) ||
                      a.reference.toLowerCase().contains(q);
                }).toList();

          return AlertDialog(
            title: const Text('Choisir un article'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher par nom ou référence…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setDialogState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: articles.length,
                      itemBuilder: (_, i) {
                        final a = articles[i];
                        return ListTile(
                          dense: true,
                          title: Text(a.designation,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            '${a.reference} — TND ${a.prixUnitaire.toStringAsFixed(3)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => Navigator.pop(ctx, a),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf() async {
    final auth = context.read<AuthProvider>();
    final lignes = _lignes.map((l) {
      final qte = double.tryParse(l.qtyCtrl.text) ?? 0;
      final pu = l.article?.prixUnitaire ?? 0;
      return SalesOrderLine(
        article: l.article,
        quantiteCommandee: qte,
        prixUnitaireHT: pu,
        tauxTVA: 19.0,
      );
    }).toList();

    final totalHT = lignes.fold(0.0, (s, l) => s + l.montantHTCalc);
    final totalTTC = lignes.fold(0.0, (s, l) => s + l.montantTTCCalc);

    final order = SalesOrder(
      client: Client(raisonSociale: auth.user ?? 'Client'),
      dateCommande: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      dateLivraisonSouhaitee: _dateLivraison != null
          ? DateFormat('yyyy-MM-dd').format(_dateLivraison!)
          : null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      lignes: lignes,
      totalHT: totalHT,
      totalTVA: totalTTC - totalHT,
      totalTTC: totalTTC,
    );

    setState(() => _isExporting = true);
    try {
      final bytes = await PdfService.generateDevis(order);
      PdfService.downloadPdf(bytes, 'devis_rayhan_${DateTime.now().millisecondsSinceEpoch}.pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devis exporté avec succès'),
            backgroundColor: AppTheme.kSuccessGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.kErrorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lignes.isEmpty) {
      _showError('Ajoutez au moins un article');
      return;
    }
    for (int i = 0; i < _lignes.length; i++) {
      if (_lignes[i].article == null) {
        _showError('Sélectionnez un article pour la ligne ${i + 1}');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final lignes = _lignes.map((l) => {
          'articleId': l.article!.id,
          'quantite': double.tryParse(l.qtyCtrl.text) ?? 0,
        }).toList();

    final body = <String, dynamic>{
      'lignes': lignes,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };
    if (_dateLivraison != null) {
      body['dateLivraisonSouhaitee'] =
          DateFormat('yyyy-MM-dd').format(_dateLivraison!);
    }

    final err = await context.read<ClientOrderProvider>().createOrder(body);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (err == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande soumise avec succès'),
            backgroundColor: AppTheme.kSuccessGreen,
          ),
        );
        context.go('/mes-commandes');
      } else {
        _showError(err);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.kErrorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);

    return ClientScaffold(
      currentRoute: '/catalogue/commander',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Nouvelle commande',
                style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.kTextPrimary)),
            const SizedBox(height: 20),

            _SectionCard(
              title: 'ARTICLES',
              child: Column(
                children: [
                  ..._lignes.asMap().entries.map((e) => _LigneWidget(
                        key: ValueKey('ligne_${e.key}_${_lignes.length}'),
                        index: e.key,
                        ligne: e.value,
                        onRemove: () => _removeLigne(e.key),
                        onChanged: () => setState(() {}),
                        onSelectArticle: _showArticlePicker,
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addLigne,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter un article'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              title: 'NOTES (OPTIONNEL)',
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Remarques, instructions particulières…',
                ),
              ),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              title: 'DATE LIVRAISON SOUHAITÉE (OPTIONNEL)',
              child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _dateLivraison = d);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.kInputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppTheme.kTextHint),
                      const SizedBox(width: 8),
                      Text(
                        _dateLivraison != null
                            ? DateFormat('dd/MM/yyyy').format(_dateLivraison!)
                            : 'Choisir une date',
                        style: TextStyle(
                          color: _dateLivraison != null
                              ? AppTheme.kTextPrimary
                              : AppTheme.kTextHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_lignes.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.kPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _TotalRow(label: 'Total HT', value: fmt.format(_totalHT)),
                    _TotalRow(
                        label: 'TVA (19%)', value: fmt.format(_totalTVA)),
                    const Divider(color: Colors.white30),
                    _TotalRow(
                        label: 'Total TTC',
                        value: fmt.format(_totalTTC),
                        bold: true),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: (_isExporting || _lignes.isEmpty)
                          ? null
                          : _exportPdf,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.description_outlined, size: 18),
                      label: Text(
                          _isExporting ? 'Génération…' : 'Exporter Devis (PDF)'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: AppTheme.primaryButton,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Soumettre la commande',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OrderLigne {
  Article? article;
  final qtyCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
  }
}

class _LigneWidget extends StatelessWidget {
  final int index;
  final _OrderLigne ligne;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Future<Article?> Function() onSelectArticle;

  const _LigneWidget({
    super.key,
    required this.index,
    required this.ligne,
    required this.onRemove,
    required this.onChanged,
    required this.onSelectArticle,
  });

  @override
  Widget build(BuildContext context) {
    final qte = double.tryParse(ligne.qtyCtrl.text) ?? 0;
    final pu = ligne.article?.prixUnitaire ?? 0;
    final total = qte * pu;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kInputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.kBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Ligne ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 18, color: AppTheme.kErrorRed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final article = await onSelectArticle();
              if (article != null) {
                ligne.article = article;
                onChanged();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.kSurfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.kBorderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ligne.article != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ligne.article!.designation,
                                  style: const TextStyle(fontSize: 14)),
                              Text(
                                '${ligne.article!.reference} — TND ${pu.toStringAsFixed(3)}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.kTextHint),
                              ),
                            ],
                          )
                        : const Text('Sélectionner un article',
                            style: TextStyle(
                                color: AppTheme.kTextHint, fontSize: 14)),
                  ),
                  const Icon(Icons.search, size: 18, color: AppTheme.kTextHint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ligne.qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => onChanged(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return '> 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.kInputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prix unitaire',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.kTextHint)),
                      Text(pu > 0 ? 'TND ${pu.toStringAsFixed(3)}' : '—',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.kPrimaryRed.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.kTextHint)),
                      Text(
                        qte > 0 ? 'TND ${total.toStringAsFixed(3)}' : '—',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kPrimaryRed),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.shadowSm,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: AppTheme.kTextHint)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 13)),
        ],
      ),
    );
  }
}
