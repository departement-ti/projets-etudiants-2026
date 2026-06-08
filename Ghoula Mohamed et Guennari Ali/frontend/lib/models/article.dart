class Article {
  final int? id;
  final String reference;
  final String designation;
  final String type; // MP, PSF, PF
  final String? uniteMesure;
  final double prixUnitaire;
  final double stockActuel;
  final double stockMinimum;
  final bool actif;
  final String? assetImage;

  Article({
    this.id,
    required this.reference,
    required this.designation,
    required this.type,
    this.uniteMesure,
    this.prixUnitaire = 0,
    this.stockActuel = 0,
    this.stockMinimum = 0,
    this.actif = true,
    this.assetImage,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'],
        reference: json['reference'] ?? '',
        designation: json['designation'] ?? '',
        type: json['type'] ?? 'MP',
        uniteMesure: json['uniteMesure'],
        prixUnitaire: (json['prixUnitaire'] ?? 0).toDouble(),
        stockActuel: (json['stockActuel'] ?? 0).toDouble(),
        stockMinimum: (json['stockMinimum'] ?? 0).toDouble(),
        actif: json['actif'] ?? true,
        assetImage: json['assetImage'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'reference': reference,
        'designation': designation,
        'type': type,
        'uniteMesure': uniteMesure,
        'prixUnitaire': prixUnitaire,
        'stockActuel': stockActuel,
        'stockMinimum': stockMinimum,
        'actif': actif,
        if (assetImage != null) 'assetImage': assetImage,
      };

  bool get enAlerte => stockActuel <= stockMinimum;

  static const Map<String, String> typeLabels = {
    'MP': 'Matière Première',
    'PSF': 'Produit Semi-Fini',
    'PF': 'Produit Fini',
  };

  String get typeLabel => typeLabels[type] ?? type;
}
