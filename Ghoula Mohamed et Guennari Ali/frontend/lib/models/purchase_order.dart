import 'fournisseur.dart';
import 'article.dart';

class PurchaseOrderLine {
  final int? id;
  final Article? article;
  final double quantiteCommandee;
  final double quantiteRecue;
  final double prixUnitaireHT;
  final double tauxTVA;
  final double? montantHT;
  final double? montantTTC;

  PurchaseOrderLine({
    this.id,
    this.article,
    required this.quantiteCommandee,
    this.quantiteRecue = 0,
    required this.prixUnitaireHT,
    this.tauxTVA = 19.0,
    this.montantHT,
    this.montantTTC,
  });

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> json) => PurchaseOrderLine(
        id: json['id'],
        article: json['article'] != null ? Article.fromJson(json['article']) : null,
        quantiteCommandee: (json['quantiteCommandee'] ?? 0).toDouble(),
        quantiteRecue: (json['quantiteRecue'] ?? 0).toDouble(),
        prixUnitaireHT: (json['prixUnitaireHT'] ?? 0).toDouble(),
        tauxTVA: (json['tauxTVA'] ?? 19.0).toDouble(),
        montantHT: json['montantHT']?.toDouble(),
        montantTTC: json['montantTTC']?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (article?.id != null) 'article': {'id': article!.id},
        'quantiteCommandee': quantiteCommandee,
        'prixUnitaireHT': prixUnitaireHT,
        'tauxTVA': tauxTVA,
      };

  double get montantHTCalc => quantiteCommandee * prixUnitaireHT;
  double get montantTTCCalc => montantHTCalc * (1 + tauxTVA / 100);
  bool get estRecu => quantiteRecue >= quantiteCommandee;
}

class PurchaseOrder {
  final int? id;
  final String? reference;
  final Fournisseur? fournisseur;
  final String dateCommande;
  final String? dateLivraisonPrevue;
  final String statut;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final String? notes;
  final List<PurchaseOrderLine> lignes;

  PurchaseOrder({
    this.id,
    this.reference,
    this.fournisseur,
    required this.dateCommande,
    this.dateLivraisonPrevue,
    this.statut = 'CONFIRMEE',
    this.totalHT = 0,
    this.totalTVA = 0,
    this.totalTTC = 0,
    this.notes,
    this.lignes = const [],
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
        id: json['id'],
        reference: json['reference'],
        fournisseur: json['fournisseur'] != null
            ? Fournisseur.fromJson(json['fournisseur'])
            : null,
        dateCommande: json['dateCommande'] ?? '',
        dateLivraisonPrevue: json['dateLivraisonPrevue'],
        statut: json['statut'] ?? 'CONFIRMEE',
        totalHT: (json['totalHT'] ?? 0).toDouble(),
        totalTVA: (json['totalTVA'] ?? 0).toDouble(),
        totalTTC: (json['totalTTC'] ?? 0).toDouble(),
        notes: json['notes'],
        lignes: (json['lignes'] as List? ?? [])
            .map((e) => PurchaseOrderLine.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (fournisseur?.id != null) 'fournisseur': {'id': fournisseur!.id},
        'dateCommande': dateCommande,
        if (dateLivraisonPrevue != null) 'dateLivraisonPrevue': dateLivraisonPrevue,
        if (notes != null) 'notes': notes,
        'lignes': lignes.map((l) => l.toJson()).toList(),
      };

  static const Map<String, String> statutLabels = {
    'BROUILLON': 'Brouillon',
    'CONFIRMEE': 'Confirmée',
    'PARTIELLEMENT_RECUE': 'Part. reçue',
    'COMPLETEMENT_RECUE': 'Reçue',
    'ANNULEE': 'Annulée',
  };

  static const Map<String, int> statutColors = {
    'BROUILLON': 0xFF9CA3AF,
    'CONFIRMEE': 0xFF3B82F6,
    'PARTIELLEMENT_RECUE': 0xFF8B5CF6,
    'COMPLETEMENT_RECUE': 0xFF10B981,
    'ANNULEE': 0xFFEF4444,
  };

  String get statutLabel => statutLabels[statut] ?? statut;
  int get statutColor => statutColors[statut] ?? 0xFF6B7280;
  bool get peutReceptionner =>
      statut == 'CONFIRMEE' || statut == 'PARTIELLEMENT_RECUE';
}
