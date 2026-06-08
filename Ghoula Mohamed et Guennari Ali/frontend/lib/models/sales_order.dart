import 'client.dart';
import 'article.dart';

class SalesOrderLine {
  final int? id;
  final Article? article;
  final double quantiteCommandee;
  final double quantiteLivree;
  final double prixUnitaireHT;
  final double tauxTVA;
  final double? montantHT;
  final double? montantTTC;

  SalesOrderLine({
    this.id,
    this.article,
    required this.quantiteCommandee,
    this.quantiteLivree = 0,
    required this.prixUnitaireHT,
    this.tauxTVA = 19.0,
    this.montantHT,
    this.montantTTC,
  });

  factory SalesOrderLine.fromJson(Map<String, dynamic> json) => SalesOrderLine(
        id: json['id'],
        article: json['article'] != null
            ? Article.fromJson(json['article'])
            : null,
        quantiteCommandee: (json['quantiteCommandee'] ?? 0).toDouble(),
        quantiteLivree: (json['quantiteLivree'] ?? 0).toDouble(),
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
}

class SalesOrder {
  final int? id;
  final String? reference;
  final Client? client;
  final String dateCommande;
  final String? dateLivraisonSouhaitee;
  final String statut;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final String? notes;
  final List<SalesOrderLine> lignes;

  SalesOrder({
    this.id,
    this.reference,
    this.client,
    required this.dateCommande,
    this.dateLivraisonSouhaitee,
    this.statut = 'CONFIRMEE',
    this.totalHT = 0,
    this.totalTVA = 0,
    this.totalTTC = 0,
    this.notes,
    this.lignes = const [],
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) => SalesOrder(
        id: json['id'],
        reference: json['reference'],
        client: json['client'] != null ? Client.fromJson(json['client']) : null,
        dateCommande: json['dateCommande'] ?? '',
        dateLivraisonSouhaitee: json['dateLivraisonSouhaitee'],
        statut: json['statut'] ?? 'CONFIRMEE',
        totalHT: (json['totalHT'] ?? 0).toDouble(),
        totalTVA: (json['totalTVA'] ?? 0).toDouble(),
        totalTTC: (json['totalTTC'] ?? 0).toDouble(),
        notes: json['notes'],
        lignes: (json['lignes'] as List? ?? [])
            .map((e) => SalesOrderLine.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (client?.id != null) 'client': {'id': client!.id},
        'dateCommande': dateCommande,
        if (dateLivraisonSouhaitee != null)
          'dateLivraisonSouhaitee': dateLivraisonSouhaitee,
        if (notes != null) 'notes': notes,
        'lignes': lignes.map((l) => l.toJson()).toList(),
      };

  static const Map<String, String> statutLabels = {
    'EN_ATTENTE': 'En attente',
    'CONFIRMEE': 'Confirmée',
    'EN_PREPARATION': 'En préparation',
    'PARTIELLEMENT_LIVREE': 'Part. livrée',
    'COMPLETEMENT_LIVREE': 'Livrée',
    'ANNULEE': 'Annulée',
  };

  static const Map<String, int> statutColors = {
    'EN_ATTENTE': 0xFFF97316,
    'CONFIRMEE': 0xFF3B82F6,
    'EN_PREPARATION': 0xFFF59E0B,
    'PARTIELLEMENT_LIVREE': 0xFF8B5CF6,
    'COMPLETEMENT_LIVREE': 0xFF10B981,
    'ANNULEE': 0xFFEF4444,
  };

  String get statutLabel => statutLabels[statut] ?? statut;
  int get statutColor => statutColors[statut] ?? 0xFF6B7280;
  bool get peutLivrer =>
      statut == 'CONFIRMEE' || statut == 'EN_PREPARATION' || statut == 'PARTIELLEMENT_LIVREE';
}
