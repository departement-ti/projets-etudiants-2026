import 'article.dart';

class StockMovement {
  final int? id;
  final Article? article;
  final String type; // IN ou OUT
  final double quantite;
  final double? stockAvant;
  final double? stockApres;
  final String? sourceDocument;
  final String? referenceDocument;
  final String? motif;
  final String dateHeure;

  StockMovement({
    this.id,
    this.article,
    required this.type,
    required this.quantite,
    this.stockAvant,
    this.stockApres,
    this.sourceDocument,
    this.referenceDocument,
    this.motif,
    required this.dateHeure,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: json['id'],
        article: json['article'] != null ? Article.fromJson(json['article']) : null,
        type: json['type'] ?? 'IN',
        quantite: (json['quantite'] ?? 0).toDouble(),
        stockAvant: json['stockAvant']?.toDouble(),
        stockApres: json['stockApres']?.toDouble(),
        sourceDocument: json['sourceDocument'],
        referenceDocument: json['referenceDocument'],
        motif: json['motif'],
        dateHeure: json['dateHeure'] ?? '',
      );

  bool get isEntree => type == 'IN';

  String get dateFormatted {
    if (dateHeure.length >= 10) return dateHeure.substring(0, 10);
    return dateHeure;
  }

  String get heureFormatted {
    if (dateHeure.length >= 16) return dateHeure.substring(11, 16);
    return '';
  }

  static const Map<String, String> sourceLabels = {
    'BON_RECEPTION': 'Bon de réception',
    'BON_LIVRAISON': 'Bon de livraison',
    'ORDRE_FABRICATION': 'Ordre de fabrication',
    'AJUSTEMENT': 'Ajustement manuel',
  };

  String get sourceLabel => sourceLabels[sourceDocument] ?? (sourceDocument ?? '—');
}
