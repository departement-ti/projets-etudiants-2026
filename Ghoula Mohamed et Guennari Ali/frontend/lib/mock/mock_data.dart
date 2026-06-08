import 'package:flutter/material.dart';
import '../models/dashboard_kpi.dart';
import 'mock_config.dart';

class MockData {
  static Future<void> delay() =>
      Future.delayed(Duration(milliseconds: MockConfig.delayMs));

  static DashboardKpi get dashboardKpi => DashboardKpi(
        ventes: VentesKpi(
          commandesEnCours: 12,
          nbCommandesMois: 43,
          chiffreAffairesMois: 284750.0,
        ),
        achats: AchatsKpi(commandesEnAttente: 5),
        production: ProductionKpi(ofEnCours: 8, ofPlanifies: 15),
        stock: StockKpi(
          articlesEnAlerte: 3,
          articlesEnAlerteDetails: [
            {'designation': 'Granulés PEHD Noir', 'reference': 'MP-0042', 'quantiteEnStock': 45},
            {'designation': 'Film Étirable 50cm', 'reference': 'PSF-0018', 'quantiteEnStock': 12},
            {'designation': 'Sac Poubelle 100L', 'reference': 'PF-0091', 'quantiteEnStock': 8},
          ],
        ),
      );

  static List<double> revenueByMonth() => [
        142000, 151000, 168000, 175000, 189000,
        201000, 215000, 228000, 241000, 256000,
        270000, 284750,
      ];

  static List<double> ordersByDay() =>
      [5, 7, 4, 8, 6, 3, 2];

  static List<double> productionCompletion() =>
      [0.35, 0.50, 0.65, 0.80, 0.45, 0.70, 0.90, 0.55];

  static List<Map<String, dynamic>> get articles => [
        {
          'id': 1,
          'reference': 'MP-0042',
          'designation': 'Granulés PEHD Noir',
          'type': 'MP',
          'stockActuel': 45.0,
          'stockMinimum': 100.0,
          'prixUnitaire': 2.50,
          'uniteMesure': 'kg',
          'enAlerte': true,
        },
        {
          'id': 2,
          'reference': 'MP-0051',
          'designation': 'Polypropylène Blanc',
          'type': 'MP',
          'stockActuel': 320.0,
          'stockMinimum': 200.0,
          'prixUnitaire': 3.20,
          'uniteMesure': 'kg',
          'enAlerte': false,
        },
        {
          'id': 3,
          'reference': 'PSF-0018',
          'designation': 'Film Étirable 50cm',
          'type': 'PSF',
          'stockActuel': 12.0,
          'stockMinimum': 50.0,
          'prixUnitaire': 8.00,
          'uniteMesure': 'rouleau',
          'enAlerte': true,
        },
        {
          'id': 4,
          'reference': 'PSF-0022',
          'designation': 'Gaine Thermo 30cm',
          'type': 'PSF',
          'stockActuel': 88.0,
          'stockMinimum': 30.0,
          'prixUnitaire': 5.50,
          'uniteMesure': 'rouleau',
          'enAlerte': false,
        },
        {
          'id': 5,
          'reference': 'PF-0091',
          'designation': 'Sac Poubelle 100L Noir',
          'type': 'PF',
          'stockActuel': 8.0,
          'stockMinimum': 50.0,
          'prixUnitaire': 12.00,
          'uniteMesure': 'paquet',
          'enAlerte': true,
          'assetImage': 'product_poubelle.jpg',
        },
        {
          'id': 6,
          'reference': 'PF-0095',
          'designation': 'Sac Courses 50x70',
          'type': 'PF',
          'stockActuel': 200.0,
          'stockMinimum': 100.0,
          'prixUnitaire': 6.50,
          'uniteMesure': 'paquet',
          'enAlerte': false,
          'assetImage': 'product_sacs.jpg',
        },
        {
          'id': 7,
          'reference': 'MP-0060',
          'designation': 'Additif UV Stabilisateur',
          'type': 'MP',
          'stockActuel': 150.0,
          'stockMinimum': 50.0,
          'prixUnitaire': 15.00,
          'uniteMesure': 'kg',
          'enAlerte': false,
        },
        {
          'id': 8,
          'reference': 'PF-0102',
          'designation': 'Film Agricole 2m',
          'type': 'PF',
          'stockActuel': 65.0,
          'stockMinimum': 40.0,
          'prixUnitaire': 22.00,
          'uniteMesure': 'rouleau',
          'enAlerte': false,
          'assetImage': 'product_film.jpg',
        },
        {
          'id': 9,
          'reference': 'PF-0110',
          'designation': 'Sac Plastique Standard',
          'type': 'PF',
          'stockActuel': 500.0,
          'stockMinimum': 200.0,
          'prixUnitaire': 3.50,
          'uniteMesure': 'paquet',
          'enAlerte': false,
          'assetImage': 'product_sac_plastique.jpg',
        },
        {
          'id': 10,
          'reference': 'PF-0111',
          'designation': 'Sac Cellophane',
          'type': 'PF',
          'stockActuel': 300.0,
          'stockMinimum': 100.0,
          'prixUnitaire': 8.00,
          'uniteMesure': 'paquet',
          'enAlerte': false,
          'assetImage': 'product_sac_cellophane.jpg',
        },
        {
          'id': 11,
          'reference': 'PF-0112',
          'designation': 'Sac à Poignée',
          'type': 'PF',
          'stockActuel': 150.0,
          'stockMinimum': 50.0,
          'prixUnitaire': 9.50,
          'uniteMesure': 'paquet',
          'enAlerte': false,
          'assetImage': 'product_sac_a_poigne.jpg',
        },
        {
          'id': 12,
          'reference': 'PF-0113',
          'designation': 'Sangles d\'Emballage',
          'type': 'PF',
          'stockActuel': 80.0,
          'stockMinimum': 30.0,
          'prixUnitaire': 15.00,
          'uniteMesure': 'rouleau',
          'enAlerte': false,
          'assetImage': 'product_sangles.jpg',
        },
      ];

  static List<Map<String, dynamic>> get salesOrders => [
        {
          'reference': 'BC-2024-001',
          'client': 'SOTUPLAST S.A.',
          'statutLabel': 'En cours',
          'statutColor': 0xFFF59E0B,
          'date': '15/05/2024',
          'totalTTC': 45600.0,
          'lignes': 4,
        },
        {
          'reference': 'BC-2024-002',
          'client': 'PLASTITUNISIE',
          'statutLabel': 'Livrée',
          'statutColor': 0xFF10B981,
          'date': '12/05/2024',
          'totalTTC': 28300.0,
          'lignes': 3,
        },
        {
          'reference': 'BC-2024-003',
          'client': 'EMBALLAGES MODERNES',
          'statutLabel': 'En attente',
          'statutColor': 0xFFF59E0B,
          'date': '10/05/2024',
          'totalTTC': 124500.0,
          'lignes': 6,
        },
        {
          'reference': 'BC-2024-004',
          'client': 'AGRO-PACK S.A.R.L.',
          'statutLabel': 'En cours',
          'statutColor': 0xFFF59E0B,
          'date': '08/05/2024',
          'totalTTC': 18900.0,
          'lignes': 2,
        },
      ];

  static List<Map<String, dynamic>> get purchaseOrders => [
        {
          'reference': 'BA-2024-012',
          'fournisseur': 'POLYMERGY TUNISIE',
          'statutLabel': 'Reçue',
          'statutColor': 0xFF10B981,
          'date': '14/05/2024',
          'totalTTC': 89200.0,
          'lignes': 5,
        },
        {
          'reference': 'BA-2024-013',
          'fournisseur': 'CHIMIPLAST S.A.',
          'statutLabel': 'En cours',
          'statutColor': 0xFFF59E0B,
          'date': '11/05/2024',
          'totalTTC': 34500.0,
          'lignes': 3,
        },
        {
          'reference': 'BA-2024-014',
          'fournisseur': 'EUROPLAST GmbH',
          'statutLabel': 'En attente',
          'statutColor': 0xFFEF4444,
          'date': '09/05/2024',
          'totalTTC': 156000.0,
          'lignes': 8,
        },
      ];

  static List<Map<String, dynamic>> get productionOrders => [
        {
          'reference': 'OF-2024-031',
          'produit': 'Sac Poubelle 100L',
          'statutLabel': 'Lancé',
          'statutColor': 0xFFF59E0B,
          'date': '16/05/2024',
          'quantite': 5000,
          'unite': 'paquet',
          'realisee': 1800,
          'peutLancer': false,
          'peutTerminer': false,
        },
        {
          'reference': 'OF-2024-032',
          'produit': 'Film Agricole 2m',
          'statutLabel': 'Planifié',
          'statutColor': 0xFF6B7280,
          'date': '18/05/2024',
          'quantite': 200,
          'unite': 'rouleau',
          'realisee': 0,
          'peutLancer': true,
          'peutTerminer': false,
        },
        {
          'reference': 'OF-2024-033',
          'produit': 'Sac Courses 50x70',
          'statutLabel': 'Terminé',
          'statutColor': 0xFF10B981,
          'date': '10/05/2024',
          'quantite': 10000,
          'unite': 'paquet',
          'realisee': 10000,
          'peutLancer': false,
          'peutTerminer': false,
        },
        {
          'reference': 'OF-2024-034',
          'produit': 'Gaine Thermo 30cm',
          'statutLabel': 'En cours',
          'statutColor': 0xFFF59E0B,
          'date': '15/05/2024',
          'quantite': 800,
          'unite': 'rouleau',
          'realisee': 420,
          'peutLancer': false,
          'peutTerminer': true,
        },
      ];

  static List<Map<String, dynamic>> get recentActivity => [
        {
          'icon': Icons.shopping_cart_outlined,
          'text': 'Nouvelle commande vente BC-2024-001',
          'time': 'Il y a 15 min',
          'color': 0xFF1E104E,
        },
        {
          'icon': Icons.check_circle_outlined,
          'text': 'OF-2024-033 marqué comme terminé',
          'time': 'Il y a 2h',
          'color': 0xFF4CAF50,
        },
        {
          'icon': Icons.warning_amber_outlined,
          'text': 'Alerte stock: MP-0042 sous seuil',
          'time': 'Il y a 3h',
          'color': 0xFFE53935,
        },
        {
          'icon': Icons.local_shipping_outlined,
          'text': 'Réception BA-2024-012 validée',
          'time': 'Il y a 5h',
          'color': 0xFF1E104E,
        },
        {
          'icon': Icons.precision_manufacturing_outlined,
          'text': 'OF-2024-032 planifié',
          'time': 'Hier',
          'color': 0xFFFFA726,
        },
        {
          'icon': Icons.article_outlined,
          'text': 'Rapport mensuel de production généré',
          'time': 'Hier',
          'color': 0xFF452E5A,
        },
      ];
}
