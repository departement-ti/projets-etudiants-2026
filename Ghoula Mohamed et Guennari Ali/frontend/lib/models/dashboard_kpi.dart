class DashboardKpi {
  final VentesKpi ventes;
  final AchatsKpi achats;
  final ProductionKpi production;
  final StockKpi stock;

  DashboardKpi({
    required this.ventes,
    required this.achats,
    required this.production,
    required this.stock,
  });

  factory DashboardKpi.fromJson(Map<String, dynamic> json) => DashboardKpi(
        ventes: VentesKpi.fromJson(json['ventes'] ?? {}),
        achats: AchatsKpi.fromJson(json['achats'] ?? {}),
        production: ProductionKpi.fromJson(json['production'] ?? {}),
        stock: StockKpi.fromJson(json['stock'] ?? {}),
      );
}

class VentesKpi {
  final int commandesEnCours;
  final int nbCommandesMois;
  final double chiffreAffairesMois;

  VentesKpi({
    required this.commandesEnCours,
    required this.nbCommandesMois,
    required this.chiffreAffairesMois,
  });

  factory VentesKpi.fromJson(Map<String, dynamic> json) => VentesKpi(
        commandesEnCours: json['commandesEnCours'] ?? 0,
        nbCommandesMois: json['nbCommandesMois'] ?? 0,
        chiffreAffairesMois: (json['chiffreAffairesMois'] ?? 0).toDouble(),
      );
}

class AchatsKpi {
  final int commandesEnAttente;

  AchatsKpi({required this.commandesEnAttente});

  factory AchatsKpi.fromJson(Map<String, dynamic> json) =>
      AchatsKpi(commandesEnAttente: json['commandesEnAttente'] ?? 0);
}

class ProductionKpi {
  final int ofEnCours;
  final int ofPlanifies;

  ProductionKpi({required this.ofEnCours, required this.ofPlanifies});

  factory ProductionKpi.fromJson(Map<String, dynamic> json) => ProductionKpi(
        ofEnCours: json['ofEnCours'] ?? 0,
        ofPlanifies: json['ofPlanifies'] ?? 0,
      );
}

class StockKpi {
  final int articlesEnAlerte;
  final List<dynamic> articlesEnAlerteDetails;

  StockKpi({required this.articlesEnAlerte, required this.articlesEnAlerteDetails});

  factory StockKpi.fromJson(Map<String, dynamic> json) => StockKpi(
        articlesEnAlerte: json['articlesEnAlerte'] ?? 0,
        articlesEnAlerteDetails: json['articlesEnAlerteDetails'] ?? [],
      );
}
