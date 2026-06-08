//UNUSED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/achats_provider.dart';
import '../providers/article_provider.dart';
import '../models/fournisseur.dart';
import '../models/article.dart';
import '../models/purchase_order.dart';
import '../constants/app_theme.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  const PurchaseOrderFormScreen({super.key});

  @override
  State<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Fournisseur? _selectedFournisseur;
  DateTime? _dateLivraison;
  final _notesCtrl = TextEditingController();
  final List<_LigneSaisie> _lignes = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ArticleProvider>().articles.isEmpty) {
        context.read<ArticleProvider>().load();
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lignes) {
      l.dispose();
    }
    super.dispose();
  }

  double get _totalHT => _lignes.fold(0, (s, l) {
        final qte = double.tryParse(l.qteCtrl.text) ?? 0;
        final prix = double.tryParse(l.prixCtrl.text) ?? 0;
        return s + qte * prix;
      });

  double get _totalTTC => _totalHT * 1.19;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFournisseur == null) {
      _showError('Veuillez sélectionner un fournisseur');
      return;
    }
    if (_lignes.isEmpty) {
      _showError('Ajoutez au moins une ligne');
      return;
    }
    for (int i = 0; i < _lignes.length; i++) {
      if (_lignes[i].article == null) {
        _showError('Sélectionnez un article pour la ligne ${i + 1}');
        return;
      }
    }

    setState(() => _saving = true);

    final lignes = _lignes
        .map((l) => PurchaseOrderLine(
              article: l.article,
              quantiteCommandee: double.tryParse(l.qteCtrl.text) ?? 0,
              prixUnitaireHT: double.tryParse(l.prixCtrl.text) ?? 0,
              tauxTVA: 19.0,
            ))
        .toList();

    final order = PurchaseOrder(
      fournisseur: _selectedFournisseur,
      dateCommande: DateTime.now().toIso8601String().substring(0, 10),
      dateLivraisonPrevue: _dateLivraison?.toIso8601String().substring(0, 10),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      lignes: lignes,
    );

    final err = await context.read<AchatsProvider>().createOrder(order);
    if (mounted) {
      setState(() => _saving = false);
      if (err == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Commande achat créée avec succès'),
          backgroundColor: Colors.green,
        ));
      } else {
        _showError(err);
      }
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    final fournisseurs = context.watch<AchatsProvider>().fournisseurs;
    final articles = context.watch<ArticleProvider>().articles;
    final fmt =
        NumberFormat.currency(locale: 'fr_TN', symbol: 'TND', decimalDigits: 3);

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouvelle commande achat',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Fournisseur',
              child: DropdownButtonFormField<Fournisseur>(
                initialValue: _selectedFournisseur,
                hint: const Text('Sélectionner un fournisseur'),
                decoration: _deco('Fournisseur'),
                items: fournisseurs
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.raisonSociale),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFournisseur = v),
                validator: (v) => v == null ? 'Obligatoire' : null,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Livraison prévue (optionnel)',
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.kInputFill,
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _dateLivraison != null
                            ? DateFormat('dd/MM/yyyy').format(_dateLivraison!)
                            : 'Choisir une date',
                        style: TextStyle(
                            color: _dateLivraison != null
                                ? Colors.black87
                                : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Lignes de commande',
              child: Column(
                children: [
                  ..._lignes.asMap().entries.map((e) => _LigneWidget(
                        index: e.key,
                        ligne: e.value,
                        articles: articles,
                        onRemove: () => setState(() {
                          _lignes[e.key].dispose();
                          _lignes.removeAt(e.key);
                        }),
                        onChanged: () => setState(() {}),
                      )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _lignes.add(_LigneSaisie())),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une ligne'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Notes (optionnel)',
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration:
                    _deco('Notes').copyWith(hintText: 'Conditions, remarques…'),
              ),
            ),
            const SizedBox(height: 12),
            if (_lignes.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.kPrimaryTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _TotalRow(label: 'Total HT', value: fmt.format(_totalHT)),
                    _TotalRow(
                        label: 'TVA (19%)',
                        value: fmt.format(_totalTTC - _totalHT)),
                    const Divider(color: Colors.white30),
                    _TotalRow(
                        label: 'Total TTC',
                        value: fmt.format(_totalTTC),
                        bold: true),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Créer la commande',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LigneWidget extends StatelessWidget {
  final int index;
  final _LigneSaisie ligne;
  final List<Article> articles;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LigneWidget({
    required this.index,
    required this.ligne,
    required this.articles,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundOffWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Ligne ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
              const Spacer(),
              GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 18, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Article>(
            initialValue: ligne.article,
            hint: const Text('Article', style: TextStyle(fontSize: 13)),
            decoration: _deco('Article').copyWith(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            items: articles
                .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text('${a.reference} — ${a.designation}',
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (a) {
              ligne.article = a;
              if (a != null) ligne.prixCtrl.text = a.prixUnitaire.toString();
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ligne.qteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _deco('Quantité').copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10)),
                  onChanged: (_) => onChanged(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if ((double.tryParse(v) ?? 0) <= 0) return '> 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: ligne.prixCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _deco('Prix HT').copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10)),
                  onChanged: (_) => onChanged(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if ((double.tryParse(v) ?? 0) <= 0) return '> 0';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LigneSaisie {
  Article? article;
  final qteCtrl = TextEditingController();
  final prixCtrl = TextEditingController();
  void dispose() {
    qteCtrl.dispose();
    prixCtrl.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.kTextSecondary)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    fontSize: bold ? 16 : 13)),
          ],
        ),
      );
}

InputDecoration _deco(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: AppTheme.kInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
