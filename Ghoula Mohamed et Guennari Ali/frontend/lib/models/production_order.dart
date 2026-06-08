import 'article.dart';

class BomLine {
  final int? id;
  final Article? composant;
  final double quantiteParUnite;
  final String? uniteMesure;

  BomLine({
    this.id,
    this.composant,
    required this.quantiteParUnite,
    this.uniteMesure,
  });

  factory BomLine.fromJson(Map<String, dynamic> json) => BomLine(
        id: json['id'],
        composant: json['composant'] != null ? Article.fromJson(json['composant']) : null,
        quantiteParUnite: (json['quantiteParUnite'] ?? 0).toDouble(),
        uniteMesure: json['uniteMesure'],
      );
}

class ProductionOrder {
  final int? id;
  final String? reference;
  final Article? produitFini;
  final double quantitePlanifiee;
  final double quantiteRealisee;
  final String datePlanifiee;
  final String? dateLancement;
  final String? dateTerminaison;
  final String statut;
  final String? notes;

  ProductionOrder({
    this.id,
    this.reference,
    this.produitFini,
    required this.quantitePlanifiee,
    this.quantiteRealisee = 0,
    required this.datePlanifiee,
    this.dateLancement,
    this.dateTerminaison,
    this.statut = 'PLANIFIE',
    this.notes,
  });

  factory ProductionOrder.fromJson(Map<String, dynamic> json) => ProductionOrder(
        id: json['id'],
        reference: json['reference'],
        produitFini: json['produitFini'] != null ? Article.fromJson(json['produitFini']) : null,
        quantitePlanifiee: (json['quantitePlanifiee'] ?? 0).toDouble(),
        quantiteRealisee: (json['quantiteRealisee'] ?? 0).toDouble(),
        datePlanifiee: json['datePlanifiee'] ?? '',
        dateLancement: json['dateLancement'],
        dateTerminaison: json['dateTerminaison'],
        statut: json['statut'] ?? 'PLANIFIE',
        notes: json['notes'],
      );

  static const Map<String, String> statutLabels = {
    'PLANIFIE': 'Planifié',
    'LANCE': 'Lancé',
    'EN_COURS': 'En cours',
    'TERMINE': 'Terminé',
    'ANNULE': 'Annulé',
  };

  static const Map<String, int> statutColors = {
    'PLANIFIE': 0xFF6366F1,
    'LANCE': 0xFFF59E0B,
    'EN_COURS': 0xFF3B82F6,
    'TERMINE': 0xFF10B981,
    'ANNULE': 0xFFEF4444,
  };

  static const Map<String, int> statutIcons = {
    'PLANIFIE': 0xe614, // schedule
    'LANCE': 0xe3a5,   // play_arrow
    'EN_COURS': 0xe88b, // settings
    'TERMINE': 0xe876,  // check_circle
    'ANNULE': 0xe5c9,   // cancel
  };

  String get statutLabel => statutLabels[statut] ?? statut;
  int get statutColor => statutColors[statut] ?? 0xFF6B7280;
  bool get peutLancer => statut == 'PLANIFIE';
  bool get peutTerminer => statut == 'LANCE' || statut == 'EN_COURS';
}
