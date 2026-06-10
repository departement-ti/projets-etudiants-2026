import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
//import 'package:image_picker/image_picker.dart';
import 'package:valortrash/screens/admin.dart';
import 'package:valortrash/services/firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


// ============================================================
// 1. Fonction Principale
// ============================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try { 
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ValortrashApp());
  } catch (e) {
    debugPrint("ERREUR FIREBASE: $e");
    
    runApp(const ErrorApp());
}

}

// ============================================================
// 2. Widget d'Erreur
// ============================================================
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 20),
                const Text(
                  "Erreur de configuration Firebase",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Vérifiez que le fichier 'google-services.json' est présent dans android/app.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. Application Principale
// ============================================================
class ValortrashApp extends StatelessWidget {
  const ValortrashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VALORTRASH',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF008B8B),
      ),
      home: const HomePage(role: null, email: null), 
    );
  }
}

// ============================================================
// 4. Service Firebase (Backend)
// ============================================================
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ----- Récupérer Articles -----
  Stream<QuerySnapshot> getArticles() {
    return _firestore.collection('articles').orderBy('createdAt', descending: true).snapshots();
  }
  // ----- Inscription -----

  Future<bool> register(String email, String password, String role) async {
    try {
      var query = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) return false;
      await _firestore.collection('users').add({
        'email': email, 'password': password, 'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) { return false; }
  }

  // ----- Connexion -----

  Future<String?> login(String email, String password) async {
    try {
      var query = await _firestore.collection('users')
          .where('email', isEqualTo: email).where('password', isEqualTo: password).get();
      if (query.docs.isNotEmpty) return query.docs.first['role'];
      return null;
    } catch (e) { 
      print("ERREUR LOGIN: $e"); 
      return null;
  }
  }

  // ----- Mise à jour du profil -----

  Future<void> updateUser(String email, Map<String, dynamic> data) async {
    try {
      var query = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(data);
      }
    } catch (e) {
      print("Erreur mise à jour: $e");
    }
  }


  // ----- Ajouter Offre -----

  Future<void> addOffer({
    required String userEmail, 
    required String materialType, 
    required String quantity,
    required String location, 
    required String transactionType, 
    String? price,
    String status = 'Disponible',

  }) async {
    await _firestore.collection('offers').add({
      'userEmail': userEmail, 
      'materialType': materialType, 
      'quantity': quantity,
      'location': location, 
      'transactionType': transactionType, 
      'price': price ?? '',
      'status': status, 
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  // ----- Récupérer Offres -----

  Stream<QuerySnapshot> getOffers() {
    return _firestore.collection('offers').where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true).snapshots();
  }

  // ----- Supprimer une offre -----

  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();
    } catch (e) {
      print("Erreur suppression offre: $e");
    }
  }

  // ----- Supprimer un utilisateur -----

  Future<void> deleteUser(String email) async {
    try {
      var query = await _firestore.collection('users').where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
    } catch (e) {
      print("Erreur suppression user: $e");
    }
  }
}

// ============================================================
// 5. PAGE D'ACCUEIL (STATE)
// ============================================================

class HomePage extends StatefulWidget {
  final String? role;
  final String? email;

  const HomePage({super.key, this.role, this.email});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ============================================================
  // 1. VARIABLES ET CONSTANTES
  // ============================================================
  
  final Color darkGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF66BB6A);

  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  // Navigation
  final List<Widget> _navigationHistory = [];
  Widget? _currentBodyContent;

  // Données UI
  final List<Map<String, dynamic>> _items = [
    {"title": "Carton & Papier", "img": "assets/images/carton.jpg"},
    {"title": "Métal", "img": "assets/images/metal.jpg"},
    {"title": "Plastique", "img": "assets/images/plastique.jpg"},
    {"title": "Bois", "img": "assets/images/bois.jpg"},
    {"title": "Verre", "img": "assets/images/verre.jpg"},
  ];

  final Map<String, Map<String, dynamic>> _materialTips = {
    "Carton & Papier": {
      "icon": Icons.description, "color": Colors.brown,
      "tips": ["Dépliez les cartons.", "Retirez les adhésifs."],
      "impact": "Recycler 1 tonne de papier économise 17 arbres."
    },
    "Métal": {
      "icon": Icons.build, "color": Colors.blueGrey,
      "tips": ["Lavez les canettes.", "Compressez-les."],
      "impact": "L'acier se recycle à l'infini."
    },
    "Plastique": {
      "icon": Icons.local_drink, "color": Colors.blue,
      "tips": ["Vérifiez le code de tri.", "Rincez les bouteilles."],
      "impact": "Réduit la dépendance au pétrole."
    },
    "Bois": {
      "icon": Icons.forest, "color": Colors.green,
      "tips": ["Séparez le bois traité du brut."],
      "impact": "Devient des panneaux de particules."
    },
    "Verre": {
      "icon": Icons.wine_bar, "color": Colors.teal,
      "tips": ["Déposez sans bouchon.", "Pas de vaisselle."],
      "impact": "Économise l'énergie d'un lave-vaisselle."
    },
  };

  final Map<String, String> _articleImagesMap = {
    "Guide de recyclage": "assets/images/guide.jpg",
    "L'importance de recyclage": "assets/images/importance.jpg",
  };
  final String _defaultArticleImage = "assets/images/default_article.jpg";

  // Timer pour les faits
  late Timer _factTimer;
  int _currentFactIndex = 0;
  final List<String> _recyclingFacts = [
    "Recycler une canette économise l'énergie pour 3h de TV.",
    "Le verre se recycle à l'infini.",
    "1 personne = 1kg de déchets/jour en moyenne.",
    "Recycler 1 tonne de plastique économise 800kg de pétrole.",
    "Le papier se recycle jusqu'à 5 fois.",
  ];

  // ============================================================
  // 2. MÉTHODES DE LOGIQUE
  // ============================================================

  @override
  void initState() {
    super.initState();
    if (widget.role == null) {
      _startFactTimer();
  }
  }
 @override
  void dispose() {
    // Annulation du timer
    if (widget.role == null) {
       _factTimer.cancel();
    }
    super.dispose();
  }
  
  void _startFactTimer() {
    _factTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentFactIndex = (_currentFactIndex + 1) % _recyclingFacts.length;
        });
      }
    });
  }
  

  void _navigateToSection(Widget newContent) {
    setState(() {
      if (_currentBodyContent != null) {
        _navigationHistory.add(_currentBodyContent!);
      }
      _currentBodyContent = newContent;
    });
  }

  void _goBack() {
    if (_navigationHistory.isNotEmpty) {
      setState(() {
        _currentBodyContent = _navigationHistory.removeLast();
      });
    }
  }

  void _goHome() {
    setState(() {
      _navigationHistory.clear();
      _currentBodyContent = null;
    });
  }

  void _showMaterialDetails(String title) {
    var data = _materialTips[title] ?? {
      "icon": Icons.help_outline, "color": Colors.grey,
      "tips": ["Infos indisponibles."], "impact": "Contactez l'admin."
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(data['icon'], color: data['color'], size: 30),
                const SizedBox(width: 15),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              const Text("Conseils", style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
              const SizedBox(height: 10),
              ...data['tips'].map<Widget>((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip)),
                ]),
              )).toList(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.eco, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(child: Text(data['impact'], style: TextStyle(fontSize: 13, color: Colors.green.shade800))),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text("Voir les offres"),
                  style: ElevatedButton.styleFrom(backgroundColor: darkGreen, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToSection(SearchOffersScreen(userEmail: widget.email ?? '', navigateTo: _navigateToSection));
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 3. BUILD PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bodyContent = _currentBodyContent ?? (widget.role != null
        ? _buildUserDashboard()
        : _buildPublicHomeContent());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      resizeToAvoidBottomInset: true, 
      drawer: _navigationHistory.isEmpty && _currentBodyContent == null ? _buildAppDrawer() : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatBotScreen())),
        backgroundColor: darkGreen,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text("Assistant IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Builder(
        builder: (context) => Column(
          children: [
            _buildTopNavBar(context),
            Expanded(child: bodyContent),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 4. CONTENU DES PAGES 
  // ============================================================

  Widget _buildUserDashboard() {
    String role = (widget.role ?? '').toLowerCase();
    if (role == 'fournisseur') return _buildProviderDashboard();
    if (role == 'recycleur') return _buildRecyclerDashboard();
    if (role == 'admin') return _buildAdminDashboard();
    return const Center(child: Text("Rôle inconnu."));
  }

  // ============================================================
  // 1. DASHBOARD FOURNISSEUR
  // ============================================================
 
  Widget _buildProviderDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDashboardWaveHeader("Espace Fournisseur"),
          
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200), 
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Padding uniforme
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Lots en attente"),
                          const SizedBox(height: 10),
                          _buildPendingLotsList(),
                          const SizedBox(height: 30),
                          
                          _buildSectionHeader("Demandes Reçues"),
                          const SizedBox(height: 10),
                          _buildProviderRequestsList(),
                          const SizedBox(height: 30),
                          
                          _buildQuickDeclarationFormComplete(),
                        ],
                      )
                    else
                      // Sur Web : 3 colonnes adaptatives
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Colonne 1 : Lots 
                          Expanded(
                            flex: 3, 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Lots en attente"),
                                const SizedBox(height: 10),
                                _buildPendingLotsList(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20), 
                          
                          // Colonne 2 : Demandes 
                          Expanded(
                            flex: 3, 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Demandes Reçues"),
                                const SizedBox(height: 10),
                                _buildProviderRequestsList(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          
                          // Colonne 3 : Formulaire 
                          Expanded(
                            flex: 2,
                            child: _buildQuickDeclarationFormComplete(),
                          ),
                        ],
                      ),

                    const SizedBox(height: 40),

                    // --- PARTIE 2 : Stats 
                    if (_isMobile)
                      Column(
                        children: [
                          _buildActivitySummary(),
                          const SizedBox(height: 20),
                          _buildChartSection(),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildActivitySummary()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildChartSection()),
                        ],
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
    // --- Fournisseur : Liste des demandes 
  Widget _buildProviderRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests')
          .where('providerEmail', isEqualTo: widget.email)
          .where('status', whereIn: ['pending', 'accepted', 'rejected']) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)), child: const Center(child: Text("Aucune demande reçue.", style: TextStyle(color: Colors.grey))));
        }

        var requests = snapshot.data!.docs;
        return Column(
          children: requests.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String requestId = doc.id;
            String status = data['status'] ?? 'pending';
            String offerType = data['offerType'] ?? 'Inconnu';
            String recyclerEmail = data['recyclerEmail'] ?? '';
            String offerId = data['offerId'] ?? '';

            return Card(
              elevation: 2, 
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: status == 'rejected' ? Colors.grey[200] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LIGNE DU HAAUT (Titre + Statut + Supprimer) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("Offre: $offerType", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        
                        // Statut
                        if (status == 'accepted')
                          Chip(label: const Text("Acceptée"), backgroundColor: Colors.green.shade100, labelStyle: const TextStyle(color: Colors.green, fontSize: 10)),
                        if (status == 'rejected')
                          Chip(label: const Text("Refusée"), backgroundColor: Colors.red.shade100, labelStyle: const TextStyle(color: Colors.red, fontSize: 10)),

                        // BOUTON SUPPRIMER 
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                          onPressed: () async {
                            // Confirmation avant suppression
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Supprimer la demande"),
                                content: const Text("Êtes-vous sûr de vouloir supprimer cette demande ?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(context, true), 
                                    child: const Text("Supprimer")
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Demande supprimée définitivement"))
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    
                    Text("De: $recyclerEmail", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 10),
                    
                    // --- ACTIONS DU BAS ---
                    
                    if (status == 'rejected')
                      const Center(
                        child: Text("Demande refusée", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                      )
                    
                    else if (status == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                            label: const Text("Refuser", style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('requests').doc(requestId).update({'status': 'rejected'});
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demande refusée")));
                            },
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text("Accepter"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance.collection('requests').doc(requestId).update({'status': 'accepted'});
                                if (offerId.isNotEmpty) {
                                  await FirebaseFirestore.instance.collection('offers').doc(offerId).update({'status': 'Non disponible'});
                                }
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demande acceptée !"), backgroundColor: Colors.green));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
                              }
                            },
                          ),
                        ],
                      )
                      
                    else if (status == 'accepted')
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text("Contacter le recycleur"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          onPressed: () => _launchEmail(recyclerEmail),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  // ============================================================
  // 2. DASHBOARD RECYCLEUR
  // ============================================================
  Widget _buildRecyclerDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDashboardWaveHeader("Espace Recycleur"),
          Padding(
            padding: const EdgeInsets.all(15),
            child: _isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Dernières Offres Disponibles"),
                      const SizedBox(height: 10),
                      _buildAvailableOffersMiniList(),
                      const SizedBox(height: 30),
                      _buildSectionHeader("Mes Demandes en Attente"),
                      const SizedBox(height: 10),
                      _buildRecyclerPendingRequestsList(),
                      const SizedBox(height: 30),
                      _buildQuickSearchWidget(),
                      const SizedBox(height: 20),
                      _buildRecyclerStats(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonne Gauche : Offres
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader("Dernières Offres Disponibles"),
                            const SizedBox(height: 10),
                            _buildAvailableOffersMiniList(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Colonne Droite : Demandes & Actions
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader("Mes Demandes en Attente"),
                            const SizedBox(height: 10),
                            _buildRecyclerPendingRequestsList(),
                            const SizedBox(height: 20),
                            _buildQuickSearchWidget(),
                            const SizedBox(height: 20),
                            _buildRecyclerStats(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. DASHBOARD ADMIN
  // ============================================================
  Widget _buildAdminDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDashboardWaveHeader("Administration"),
          Padding(
            padding: const EdgeInsets.all(15),
            child: _isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Utilisateurs Récents"),
                      const SizedBox(height: 10),
                      _buildUsersList(),
                      const SizedBox(height: 30),
                      _buildSectionHeader("Offres Actives"),
                      const SizedBox(height: 10),
                      _buildAdminOffersList(),
                      const SizedBox(height: 30),
                      _buildGlobalStats(),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Utilisateurs Récents"),
                                const SizedBox(height: 10),
                                _buildUsersList(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Offres Actives"),
                                const SizedBox(height: 10),
                                _buildAdminOffersList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildGlobalStats(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS COMMUNS & HELPERS
  // ============================================================

  // --- En-tête Vague ---
  Widget _buildDashboardWaveHeader(String title) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [darkGreen, lightGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, height: 60,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: ClipOval(child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.recycling, color: Color(0xFF2E7D32), size: 30))),
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(widget.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
          ],
        ),
      ),
    );
  }
  Widget _buildQuickDeclarationFormComplete() {
    // On retourne le widget QuickOfferForm
    return QuickOfferForm(userEmail: widget.email ?? '');
  }
  // --- Formulaire Fournisseur ---
  Widget _buildPendingLotsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('offers').where('userEmail', isEqualTo: widget.email).where('status', isEqualTo: 'Disponible').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();
        return Column(children: snapshot.data!.docs.map((doc) => _buildLotCard(doc.id, doc.data() as Map<String, dynamic>)).toList());
      },
    );
  }

  Widget _buildLotCard(String docId, Map<String, dynamic> data) {
    String type = data['materialType'] ?? 'Inconnu';
    String qty = data['quantity']?.toString() ?? '0';
    String location = data['location'] ?? 'Non précisée';
    Color typeColor = Colors.green;
    if (type.contains('Plastique')) typeColor = Colors.blue;
    if (type.contains('Métal')) typeColor = Colors.orange;
    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(width: 8, height: 40, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Lot #V - ${docId.substring(0, 4).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                ]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)), child: Text("$qty kg", style: const TextStyle(fontWeight: FontWeight.bold)))
              ],
            ),
            const Divider(height: 20),
            Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 5), Expanded(child: Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)))]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(icon: const Icon(Icons.edit, size: 18), label: const Text("Modifier"), onPressed: () => _navigateToSection(EditOfferScreen(offerId: docId, initialData: data)))]),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Synthèse de votre activité", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(margin: const EdgeInsets.only(bottom: 10), width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Total Valorisé", style: TextStyle(color: Colors.green[700], fontSize: 12)), const SizedBox(height: 5), const Text("180 Tonnes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
        Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Revenus", style: TextStyle(color: Colors.blue[700], fontSize: 12)), const SizedBox(height: 5), const Text("\$ 150", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Répartition des matériaux", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        SizedBox(height: 150, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 100, height: 100, child: CircularProgressIndicator(value: 0.7, strokeWidth: 12, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(Colors.green))),
            const Text("70%", style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(width: 20),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildChartLegend("Carton", Colors.green), _buildChartLegend("Plastique", Colors.blue), _buildChartLegend("Métaux", Colors.orange),
          ])
        ]))
      ],
    );
  }

  // --- Listes Recycleur ---
  Widget _buildAvailableOffersMiniList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Erreur de chargement:\n${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return _buildRecyclerOfferCard(doc.id, data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecyclerOfferCard(String docId, Map<String, dynamic> data) {
    String type = data['materialType'] ?? 'Inconnu';
    String qty = data['quantity']?.toString() ?? '0';
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 10), child: ListTile(
      contentPadding: const EdgeInsets.all(10),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.recycling, color: Colors.green)),
      title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("$qty kg", style: const TextStyle(fontSize: 12)),
      trailing: ElevatedButton(child: const Text("Voir"), style: ElevatedButton.styleFrom(backgroundColor: darkGreen, foregroundColor: Colors.white), onPressed: () => _navigateToSection(OfferDetailScreen(offerId: docId, offerData: data, userEmail: widget.email, userRole: widget.role))),
    ));
  }

  // --- Recycleur : Liste des demandes  ---
  
  Widget _buildRecyclerPendingRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests')
          .where('recyclerEmail', isEqualTo: widget.email)
          // On inclut 'rejected' pour que le recycleur voie si sa demande est refusée
          .where('status', whereIn: ['pending', 'accepted', 'rejected']) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("Erreur: ${snapshot.error}", style: TextStyle(color: Colors.red))));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)), child: const Center(child: Text("Aucune demande envoyée.", style: TextStyle(color: Colors.grey))));
        }
        
        var requests = snapshot.data!.docs;
        return Column(
          children: requests.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String requestId = doc.id;
            String status = data['status'] ?? 'pending';
            String offerType = data['offerType'] ?? 'N/A';
            String providerEmail = data['providerEmail'] ?? '';
            
            return Card(
              elevation: 1, 
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              // Couleur grise si refusée
              color: status == 'rejected' ? Colors.grey[200] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LIGNE DU HAUT (Titre + Statut + Supprimer) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("Offre: $offerType", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        
                        // Statut
                        if (status == 'accepted')
                          Chip(label: const Text("Acceptée"), backgroundColor: Colors.green.shade100, labelStyle: const TextStyle(color: Colors.green, fontSize: 10)),
                        if (status == 'rejected')
                          Chip(label: const Text("Refusée"), backgroundColor: Colors.red.shade100, labelStyle: const TextStyle(color: Colors.red, fontSize: 10)),

                        // BOUTON SUPPRIMER
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                          onPressed: () async {
                            // Confirmation
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Supprimer la demande"),
                                content: const Text("Voulez-vous supprimer cette demande ?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(context, true), 
                                    child: const Text("Supprimer")
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Demande supprimée"))
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    
                    Text("Fournisseur: $providerEmail", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 10),

                    // --- ACTIONS DU BAS ---
                    
                    if (status == 'rejected')
                      const Center(
                        child: Text("Demande refusée par le fournisseur", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      )
                    
                    else if (status == 'accepted')
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text("Contacter"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _launchEmail(providerEmail), 
                        ),
                      )
                      
                    else if (status == 'pending')
                      const Center(
                        child: Text("En attente de réponse...", style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              )
            );
          }).toList(),
        );
      },
    );
  }
  Widget _buildQuickSearchWidget() {
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Recherche Rapide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const Divider(),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.search, size: 18), label: const Text("Trouver"), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), onPressed: () => _navigateToSection(SearchOffersScreen(userEmail: widget.email ?? '', navigateTo: _navigateToSection)))),
      ]),
    );
  }
  
  Widget _buildRecyclerStats() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Mon Activité", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(15), width: double.infinity, decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Demandes Envoyées", style: TextStyle(color: Colors.orange[700], fontSize: 12)), const SizedBox(height: 5), const Text("12", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]), const Icon(Icons.send, color: Colors.orange, size: 30)])),
    ]);
  }

  // --- Listes Admin ---
  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();
        return Column(children: snapshot.data!.docs.map((doc) => _buildUserCard(doc.id, doc.data() as Map<String, dynamic>)).toList());
      },
    );
  }

  Widget _buildUserCard(String docId, Map<String, dynamic> data) {
    String email = data['email'] ?? 'Email inconnu';
    String role = data['role'] ?? 'utilisateur';
    Color roleColor = (role == 'fournisseur') ? Colors.orange : (role == 'recycleur' ? Colors.blue : Colors.red);
    return Card(elevation: 2, margin: const EdgeInsets.only(bottom: 10), child: ListTile(
      leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Icon(Icons.person_outline, color: Colors.grey[600])),
      title: Text(email, style: const TextStyle(fontSize: 14)),
      subtitle: Text("Rôle: ${role.toUpperCase()}", style: const TextStyle(fontSize: 12)),
      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
         bool? confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text("Supprimer ?"), content: Text("Supprimer $email ?"), actions: [TextButton(onPressed: ()=> Navigator.pop(c, false), child: const Text("Annuler")), TextButton(onPressed: ()=> Navigator.pop(c, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red)))]));
         if(confirm == true) await FirebaseService().deleteUser(email);
      }),
    ));
  }
  
  Widget _buildAdminOffersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('offers').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();
        var offers = snapshot.data!.docs;
        return Column(
          children: offers.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String type = data['materialType'] ?? 'N/A';
            String status = data['status'] ?? 'N/A';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                title: Text("$type (${data['quantity'] ?? 0} kg)"),
                subtitle: Text("Statut: $status"),
                trailing: Wrap(
                  children: [
                    IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), onPressed: () => _navigateToSection(OfferDetailScreen(offerId: doc.id, offerData: data, userEmail: widget.email, userRole: 'admin'))), // Rôle Admin
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                       bool? confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text("Supprimer ?"), content: const Text("Supprimer cette offre ?"), actions: [TextButton(onPressed: ()=> Navigator.pop(c, false), child: const Text("Annuler")), TextButton(onPressed: ()=> Navigator.pop(c, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red)))]));
                       if(confirm == true) await FirebaseFirestore.instance.collection('offers').doc(doc.id).delete();
                    }),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGlobalStats() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Plateforme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 10),
      Container(margin: const EdgeInsets.only(bottom: 10), width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Total Utilisateurs", style: TextStyle(color: Colors.indigo[700], fontSize: 12)), const SizedBox(height: 5), const Text("152", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
      Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Offres Actives", style: TextStyle(color: Colors.purple[700], fontSize: 12)), const SizedBox(height: 5), const Text("45", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
    ]);
  }

  // --- Helpers ---
  Widget _buildSectionHeader(String title) => Text(title.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1.1));
  Widget _buildChartLegend(String title, Color color) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(children: [Container(width: 12, height: 12, color: color), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 12))]));
  Widget _buildEmptyState() => Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)), child: Center(child: Column(children: [Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]), const SizedBox(height: 10), const Text("Aucune donnée", style: TextStyle(color: Colors.grey))])));  
  
  // ============================================================
  // 1. MÉTHODE D'ENVOI D'EMAIL (GMAIL WEB / APP MOBILE)
  // ============================================================
  void _launchEmail(String email) async {
    final String subject = "Contact via ValorTrash";

    if (kIsWeb) {
      // --- CAS WEB ---
      final String gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=$subject';

      try {
        bool launched = await launchUrl(
          Uri.parse(gmailUrl),
          mode: LaunchMode.externalApplication, // Force l'ouverture externe
        );

        // Si le navigateur bloque l'ouverture, on affiche la popup de secours
        if (!launched) {
          _showWebEmailFallback(email);
        }
      } catch (e) {
        // En cas d'erreur, on affiche la popup de secours
        _showWebEmailFallback(email);
      }
    } else {
      // --- CAS MOBILE ---
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': subject},
      );

      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Impossible d'ouvrir l'application email."))
          );
        }
      }
    }
  } 

  // ============================================================
  // 2. MÉTHODE DE SECOURS (POPUP COPIER) 
  // ============================================================
  
  void _showWebEmailFallback(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contacter par email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Copiez l'adresse ci-dessous pour nous contacter :"),
            const SizedBox(height: 10),
            SelectableText(
              email,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text("Copier l'adresse"),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: email));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Adresse email copiée !"), backgroundColor: Colors.green)
                );
              },
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))
        ],
      ),
    );
  }
  Widget _buildPublicHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWaveHeader(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Marketplace Numérique", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 15),
                if (_isMobile)
                  Column(children: [
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _items.map((item) => _buildHorizontalCard(item)).toList())),
                    const SizedBox(height: 20),
                    _buildDidYouKnowWidget(),
                  ])
                else
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _items.map((item) => _buildHorizontalCard(item)).toList()))),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: _buildDidYouKnowWidget()),
                  ]),
                const SizedBox(height: 35),
                if (_isMobile)
                  Column(children: [_buildArticlesSection(), const SizedBox(height: 20), _buildHowItWorks()])
                else
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: _buildArticlesSection()),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: _buildHowItWorks()),
                  ]),
                const SizedBox(height: 30),
                _buildStatsSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. WIDGETS UI (HEADER, NAV, CARTES)
  // ============================================================

  Widget _buildWaveHeader() {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [darkGreen, lightGreen])),
        padding: EdgeInsets.fromLTRB(20, _isMobile ? 20 : 50, 20, _isMobile ? 60 : 80),
        constraints: BoxConstraints(minHeight: _isMobile ? 200 : 320),
        child: _isMobile ? _buildMobileHeaderLayout() : _buildWebHeaderLayout(),
      ),
    );
  }

  Widget _buildMobileHeaderLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover, errorBuilder: (c, o, s) => Icon(Icons.recycling, size: 40, color: darkGreen)))),
        const SizedBox(height: 10),
        const Text("VALORTRASH", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text("La 1ère plateforme tunisienne qui transforme vos déchets en ressources. Connectez-vous et participez à une économie plus propre.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildWebHeaderLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover, errorBuilder: (c, o, s) => Icon(Icons.recycling, size: 50, color: darkGreen)))),
        const SizedBox(width: 15),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text("VALORTRASH", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text("ValorTrash révolutionne la gestion des déchets en Tunisie. Notre plateforme connecte directement les détenteurs de déchets aux professionnels du recyclage. Valorisez vos rebuts, réduisez votre empreinte carbone et contribuez à une économie circulaire locale."),
        ])),
        const SizedBox(width: 15),
        Container(width: 380, height: 210, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Image.asset('assets/images/im.jpg', fit: BoxFit.cover, errorBuilder: (c, o, s) => Container(color: Colors.grey[300]))),
      ],
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    bool canGoBack = _navigationHistory.isNotEmpty;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          if (canGoBack)
            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: _goBack)
          else if (_isMobile)
            IconButton(icon: const Icon(Icons.menu, color: Colors.black87), onPressed: () => Scaffold.of(context).openDrawer())
          else ...[
            Icon(Icons.recycling, color: darkGreen, size: 28),
            const SizedBox(width: 8),
            Text("VALORTRASH", style: TextStyle(color: darkGreen, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
          if (canGoBack && _isMobile)
            Text("Retour", style: TextStyle(color: darkGreen, fontWeight: FontWeight.w800, fontSize: 18)),
          const Spacer(),
          if (!_isMobile) ...[
            _buildNavItem("Accueil"), _buildNavItem("Articles"), _buildNavItem("Statistiques"), _buildNavItem("Contact"), _buildNavItem("À propos"),
            const SizedBox(width: 20),
          ],
          if (widget.role == null) ...[
            if (!_isMobile) ...[
              _buildTextButton("Se connecter", Colors.grey[700]!, false),
              const SizedBox(width: 10),
              _buildTextButton("S'inscrire", darkGreen, true),
            ]
          ] else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextButton("Mon compte", Colors.grey[700]!, false),
                const SizedBox(width: 10),
                _buildTextButton("Déconnexion", Colors.red, false),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title) {
    return InkWell(
      onTap: () {
        if (title == "Accueil") _goHome();
        else if (title == "Articles") _navigateToSection(const ArticlesScreen());
        else if (title == "Statistiques") _navigateToSection(const StatsScreen());
        else if (title == "Contact") _navigateToSection(const ContactScreen());
        else if (title == "À propos") _navigateToSection(const AboutScreen());
      },
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10), child: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
    );
  }

  Widget _buildTextButton(String title, Color color, bool filled) {
    return InkWell(
      onTap: () {
        if (title == "Déconnexion") {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
        } else if (title == "Mon compte") {
          _navigateToSection(AccountScreen(email: widget.email ?? '', role: widget.role ?? ''));
        } else if (kIsWeb) {
          if (title == "S'inscrire") _showWebDialog(context, const SignupScreen());
          else _showWebDialog(context, const LoginScreen());
        } else {
          if (title == "S'inscrire") Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
          else Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: filled ? color : Colors.transparent, border: Border.all(color: filled ? color : Colors.grey.shade400), borderRadius: BorderRadius.circular(20)),
        child: Text(title, style: TextStyle(color: filled ? Colors.white : color, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  void _showWebDialog(BuildContext context, Widget screen) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Fermer",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: 450,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(borderRadius: BorderRadius.circular(20), child: screen),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: anim1.drive(Tween<double>(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOut))), child: child),
        );
      },
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: darkGreen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.recycling, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                const Text("VALORTRASH", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Valorisez vos déchets", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerItem(icon: Icons.home, title: "Accueil", onTap: () { Navigator.pop(context); _goHome(); }),
          _buildDrawerItem(icon: Icons.article, title: "Articles", onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticlesScreen())); }),
          _buildDrawerItem(icon: Icons.bar_chart, title: "Statistiques", onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())); }),
          _buildDrawerItem(icon: Icons.contact_mail, title: "Contact", onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())); }),
          _buildDrawerItem(icon: Icons.info, title: "À propos", onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())); }),
          const Divider(),
          if (widget.role == null) ...[
            _buildDrawerItem(icon: Icons.login, title: "Se connecter", color: Colors.grey[700], onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); }),
            _buildDrawerItem(icon: Icons.person_add, title: "S'inscrire", onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())); }),
          ] else
            _buildDrawerItem(icon: Icons.logout, title: "Déconnexion", color: Colors.red, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()))),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(height: 50, width: double.infinity, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: Row(children: [Icon(icon, color: color ?? darkGreen), const SizedBox(width: 15), Text(title, style: TextStyle(fontSize: 16, color: color ?? Colors.black87, fontWeight: FontWeight.w500))]))),
    );
  }

  Widget _buildHorizontalCard(Map<String, dynamic> item) {
    return Container(
      width: 160, margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.asset(item['img'], height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 100, color: Colors.grey[200]))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity, height: 24,
                  child: ElevatedButton(
                    onPressed: () => _showMaterialDetails(item['title']),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 112, 133, 112), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                    child: const Text("En savoir plus", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(children: [
      _buildStatCard("12,345", "Déchets\nValorisés", Icons.recycling),
      const SizedBox(width: 10),
      _buildStatCard("56,789", "Utilisateurs\nActifs", Icons.group),
      const SizedBox(width: 10),
      _buildStatCard("8,901", "Impact\nCO2", Icons.co2),
    ]);
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [Icon(icon, color: darkGreen, size: 22), const SizedBox(height: 5), Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkGreen)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.2))]),
      ),
    );
  }

  Widget _buildDidYouKnowWidget() {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: darkGreen, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.lightbulb_outline, color: darkGreen, size: 30), 
          const SizedBox(height: 10),
          const Text("Le Saviez-vous ?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))), 
          const SizedBox(height: 10),
          // Ce texte changera toutes les 5 secondes UNIQUEMENT sur l'accueil public
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500), 
            child: Text(
              _recyclingFacts[_currentFactIndex], 
              key: ValueKey<String>(_recyclingFacts[_currentFactIndex]), 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)
            )
          ),
        ]
      ),
    );
  }

  Widget _buildHowItWorks() {
    List<Map<String, dynamic>> steps = [
      {"icon": Icons.person_add, "title": "S'inscrire", "desc": "Créez un compte"},
      {"icon": Icons.swap_horiz, "title": "Échanger", "desc": "Publiez ou cherchez"},
      {"icon": Icons.eco, "title": "Agir", "desc": "Économie verte"}
    ];
    return Container(
      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Comment ça marche ?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkGreen)), const SizedBox(height: 15),
        Column(children: steps.asMap().entries.map((entry) {
          int idx = entry.key; Map<String, dynamic> step = entry.value;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [CircleAvatar(radius: 12, backgroundColor: darkGreen, child: Text("${idx + 1}", style: TextStyle(color: Colors.white, fontSize: 12))), if (idx < steps.length - 1) Container(height: 30, width: 2, color: Colors.grey.shade300)]),
            const SizedBox(width: 15),
            Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 15.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(step['icon'], size: 18, color: darkGreen), const SizedBox(width: 8), Text(step['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]), const SizedBox(height: 4), Text(step['desc'], style: TextStyle(fontSize: 11, color: Colors.grey[600]))]))),
          ]);
        }).toList()),
      ]),
    );
  }

  Widget _buildArticlesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Actualités & Guides", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
      const SizedBox(height: 15),
      SizedBox(height: 220, child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService().getArticles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Erreur: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Aucun article"));
          var articles = snapshot.data!.docs;
          return ListView.builder(
            scrollDirection: Axis.horizontal, itemCount: articles.length,
            itemBuilder: (context, index) {
              var articleData = articles[index].data() as Map<String, dynamic>;
              return _buildArticleCardHome(articleData);
            },
          );
        },
      )),
    ]);
  }

  Widget _buildArticleCardHome(Map<String, dynamic> article) {
    String title = article['title'] ?? '';
    String imagePath = _articleImagesMap[title] ?? _defaultArticleImage;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article))),
      child: Container(
        width: 220, margin: const EdgeInsets.only(right: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.asset(imagePath, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 120, color: Colors.grey[200]))),
          Padding(padding: const EdgeInsets.all(10.0), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
// --- CLIPPER POUR LA VAGUE ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _handleLogin() async {
    setState(() => _errorMessage = null);

    String email = _emailController.text.trim();
    String password = _passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Champs vides");
      return;
    }
    
    String? role = await FirebaseService().login(email, password);
    if (!mounted) return;

    if (role != null) {
      // Si on est sur Web dans un dialogue, on ferme le dialogue d'abord
      if (kIsWeb && Navigator.canPop(context)) {
         Navigator.pop(context);
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(role: role, email: email)));
    } else {
      setState(() => _errorMessage = "Identifiants incorrects");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebContent();
    } else {
      return _buildMobileContent();
    }
  }

  // --- Version Mobile ---
  Widget _buildMobileContent() {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion"), backgroundColor: const Color(0xFF008B8B), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            TextField(controller: _emailController, decoration: InputDecoration(hintText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(hintText: "Mot de passe", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50, 
              child: ElevatedButton(onPressed: _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008B8B)), child: const Text("Se connecter"))
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), 
              child: const Text("S'inscrire")
            )
          ],
        ),
      ),
    );
  }

  // --- Version Web ---
  Widget _buildWebContent() {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de titre
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF008B8B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Connexion", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white))
                ],
              ),
            ),
            // Corps
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20), const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                      ]),
                    ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(hintText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController, obscureText: true,
                    decoration: InputDecoration(hintText: "Mot de passe", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 45,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008B8B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text("Se connecter", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // --- CORRECTION ICI ---
                      // On ferme le dialogue de connexion actuel
                      Navigator.pop(context);
                      
                      // On ouvre le dialogue d'inscription directement
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: "Fermer",
                        barrierColor: Colors.black.withOpacity(0.5),
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, anim1, anim2) {
                          return Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 450, // Même largeur que la connexion
                              child: const SignupScreen(), // On affiche l'écran d'inscription
                            ),
                          );
                        },
                        transitionBuilder: (context, anim1, anim2, child) {
                          return FadeTransition(
                            opacity: anim1,
                            child: ScaleTransition(
                              scale: anim1.drive(Tween<double>(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOut))),
                              child: child,
                            ),
                          );
                        },
                      );
                    }, 
                    child: const Text("Pas de compte ? S'inscrire")
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --- Page Inscription ---

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;
  String? _errorMessage; // Pour afficher l'erreur dans le formulaire

  void _handleSignup() async {
    // Réinitialiser l'erreur
    setState(() => _errorMessage = null);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _selectedRole == null) {
      setState(() => _errorMessage = "Veuillez remplir tous les champs.");
      return;
    }

    bool success = await FirebaseService().register(_emailController.text, _passwordController.text, _selectedRole!);
    if (!mounted) return;

    if (success) {
      // Afficher le message de succès sur la page d'accueil après fermeture
      Navigator.pop(context); 
    } else {
      setState(() => _errorMessage = "Erreur : Email peut-être déjà utilisé.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebContent();
    } else {
      return _buildMobileContent();
    }
  }

  // --- Version Mobile ---
  Widget _buildMobileContent() {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription"), backgroundColor: const Color(0xFF008B8B)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Mot de passe", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: "Rôle",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: const [
                DropdownMenuItem(value: 'fournisseur', child: Text("Fournisseur")),
                DropdownMenuItem(value: 'recycleur', child: Text("Recycleur"))
              ],
              onChanged: (val) => setState(() => _selectedRole = val),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008B8B),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("S'inscrire", style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  // --- Version Web ---
  Widget _buildWebContent() {
    return Material( 
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de titre
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF008B8B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Créer un compte", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white),
                  )
                ],
              ),
            ),
            
            // Corps
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Affichage de l'erreur
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Mot de passe",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    hint: const Text("Sélectionner un rôle"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.people_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'fournisseur', child: Text("Fournisseur")),
                      DropdownMenuItem(value: 'recycleur', child: Text("Recycleur"))
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008B8B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("S'inscrire", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --- Page Ajouter Offre ---

class AddOfferScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onFinish; // NOUVEAU : Fonction pour revenir en arrière

  const AddOfferScreen({super.key, required this.userEmail, this.onFinish});

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  // Variables d'état
  String? _mat, _trans;
  final _qty = TextEditingController();
  final _loc = TextEditingController();
  final _price = TextEditingController();

  void _submit() async {
    // Validation simple
    if (_mat == null || _trans == null || _qty.text.isEmpty || _loc.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs obligatoires."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_trans == 'Vente' && _price.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un prix pour la vente."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseService().addOffer(
      userEmail: widget.userEmail,
      materialType: _mat!,
      quantity: _qty.text,
      location: _loc.text,
      transactionType: _trans!,
      price: _trans == 'Vente' ? _price.text : null,
      status: "Disponible",
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Votre offre a été publiée avec succès !"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );


    if (widget.onFinish != null) {
      widget.onFinish!();
    }
  }

  @override
  Widget build(BuildContext context) {
   
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // Titre manuel
              const Text(
                "Nouvelle Offre",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 20),

              // Type de matériau
              DropdownButtonFormField<String>(
                value: _mat,
                items: ["Plastique", "Carton", "Métaux", "Bois"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _mat = v),
                decoration: const InputDecoration(labelText: "Type de matériau"),
              ),
              const SizedBox(height: 15),

              TextField(
                  controller: _qty,
                  decoration: const InputDecoration(labelText: "Quantité (Kg)"),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),

              TextField(
                  controller: _loc, decoration: const InputDecoration(labelText: "Lieu de collecte")),
              const SizedBox(height: 15),

              // Type de transaction
              DropdownButtonFormField<String>(
                value: _trans,
                items: ["Vente", "Don"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _trans = v),
                decoration: const InputDecoration(labelText: "Type de transaction"),
              ),
              const SizedBox(height: 15),

              // Affichage conditionnel du prix
              if (_trans == 'Vente')
                TextField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: "Prix (TND)"),
                    keyboardType: TextInputType.number),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Publier l'offre", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- Page Rechercher Offres ---

class SearchOffersScreen extends StatefulWidget {
  final String userEmail;
  final void Function(Widget) navigateTo;

  const SearchOffersScreen({
    super.key, 
    required this.userEmail,
    required this.navigateTo,
  }); 

  @override
  State<SearchOffersScreen> createState() => _SearchOffersScreenState();
}

class _SearchOffersScreenState extends State<SearchOffersScreen> {
  // Contrôleur pour la recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "Rechercher des Offres",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),

            // BARRE DE RECHERCHE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Rechercher (ex: Carton, Plastique...)",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear), 
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        }
                      ) 
                    : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase().trim();
                  });
                },
              ),
            ),

            // Liste des offres
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('offers').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Aucune offre disponible."));
                  }

                  // FILTRAGE CÔTÉ CLIENT
                  var allOffers = snapshot.data!.docs;
                  var filteredOffers = allOffers.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String type = data['materialType']?.toString().toLowerCase() ?? '';
                    String status = data['status']?.toString() ?? '';

                    // On affiche seulement si le statut est Disponible 
                    bool isAvailable = status == 'Disponible' || status.isEmpty;

                    // Filtre par texte de recherche
                    bool matchesSearch = _searchQuery.isEmpty || type.contains(_searchQuery);

                    return isAvailable && matchesSearch;
                  }).toList();

                  if (filteredOffers.isEmpty) {
                    return Center(
                      child: Text(_searchQuery.isEmpty 
                        ? "Aucune offre disponible pour le moment." 
                        : "Aucun résultat pour '$_searchQuery'")
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredOffers.length,
                    itemBuilder: (context, index) {
                      var doc = filteredOffers[index];
                      var offerData = doc.data() as Map<String, dynamic>;
                      String offerId = doc.id;

                      return _buildOfferCard(offerId, offerData);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(String offerId, Map<String, dynamic> data) {
    String type = data['materialType'] ?? 'Inconnu';
    String quantity = data['quantity']?.toString() ?? '0';
    String location = data['location'] ?? 'Non spécifié';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline, color: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  Text(type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text("$quantity kg", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(child: Text(location, style: const TextStyle(color: Colors.grey))),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text("Détails"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                  onPressed: () => widget.navigateTo(OfferDetailScreen(offerId: offerId, offerData: data, userEmail: widget.userEmail)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text("Envoyer demande"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008B8B), foregroundColor: Colors.white),
                  onPressed: () => _sendRecyclingRequest(offerId, type, data['userEmail'] ?? 'Inconnu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendRecyclingRequest(String offerId, String offerType, String providerEmail) async {
    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'offerId': offerId,
        'offerType': offerType,
        'providerEmail': providerEmail,
        'recyclerEmail': widget.userEmail, 
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande envoyée ! Vous serez notifié de la réponse."), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
// --- Page Mon Compte  ---

class AccountScreen extends StatefulWidget {
  final String email;
  final String role;
  const AccountScreen({super.key, required this.email, required this.role});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Contrôleurs
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  void _loadData() async {
    try {
      var query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.email).get();
      if (query.docs.isNotEmpty) {
        var data = query.docs.first.data();
        if (mounted) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _locationController.text = data['location'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Erreur chargement profil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveProfile() async {
    // Vérification que le nom n'est pas vide
    if (_nameController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le nom ne peut pas être vide"), backgroundColor: Colors.red));
       return;
    }

    try {
      var query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: widget.email).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'location': _locationController.text,
        });
      }
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil mis à jour !"), backgroundColor: Colors.green));
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Titre manuel
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Mon Profil", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008B8B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF008B8B),
                          child: Text(
                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "U",
                            style: const TextStyle(fontSize: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : "Utilisateur",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D3557)),
                        ),
                        const SizedBox(height: 5),
                        Text(widget.email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text(widget.role.toUpperCase()),
                          backgroundColor: widget.role == 'fournisseur' ? Colors.orange.shade100 : Colors.green.shade100,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Carte Informations
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Informations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                              IconButton(
                                icon: Icon(_isEditing ? Icons.check : Icons.edit, color: const Color(0xFF008B8B)),
                                onPressed: () {
                                  if (_isEditing) _saveProfile();
                                  else setState(() => _isEditing = true);
                                },
                              )
                            ],
                          ),
                          const Divider(),
                          
                          if (_isEditing) ...[
                            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nom complet", prefixIcon: Icon(Icons.person))),
                            const SizedBox(height: 15),
                            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Téléphone", prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                            const SizedBox(height: 15),
                            TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Localisation", prefixIcon: Icon(Icons.location_on))),
                          ] else ...[
                            _buildInfoRow(Icons.person, "Nom", _nameController.text.isEmpty ? "Non renseigné" : _nameController.text),
                            const SizedBox(height: 15),
                            _buildInfoRow(Icons.phone, "Téléphone", _phoneController.text.isEmpty ? "Non renseigné" : _phoneController.text),
                            const SizedBox(height: 15),
                            _buildInfoRow(Icons.location_on, "Localisation", _locationController.text.isEmpty ? "Non renseigné" : _locationController.text),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  if (!_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_outline, color: Colors.orange),
                        label: const Text("Changer le mot de passe"),
                        onPressed: () => _showPasswordDialog(),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
//--- Affichage des infos ---
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF008B8B)),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // --- la boite de dialogue mot de passe ---
  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _currentPassController, obscureText: true, decoration: const InputDecoration(labelText: "Mot de passe actuel")),
            const SizedBox(height: 10),
            TextField(controller: _newPassController, obscureText: true, decoration: const InputDecoration(labelText: "Nouveau mot de passe")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonctionnalité à implémenter")));
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }
}
// --- Page Détails Offre  ---

class OfferDetailScreen extends StatelessWidget {
  final String offerId;
  final Map<String, dynamic> offerData;
  final String? userEmail;
  final String? userRole; 

  const OfferDetailScreen({
    super.key, 
    required this.offerId, 
    required this.offerData, 
    this.userEmail,
    this.userRole, 
  });

  @override
  Widget build(BuildContext context) {
    String type = offerData['materialType']?.toString() ?? 'Non spécifié';
    String quantity = offerData['quantity']?.toString() ?? '0';
    String location = offerData['location']?.toString() ?? 'Non spécifié';
    String transaction = offerData['transactionType']?.toString() ?? 'Non spécifié';
    String providerEmail = offerData['userEmail']?.toString() ?? 'Non spécifié';
    String price = offerData['price']?.toString() ?? '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Détails : $type",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.category, "Type de déchet", type),
                      const Divider(),
                      _buildInfoRow(Icons.scale, "Quantité", "$quantity kg"),
                      const Divider(),
                      _buildInfoRow(Icons.location_on, "Localisation", location),
                      const Divider(),
                      if (transaction == 'Vente' && price.isNotEmpty) ...[
                        _buildInfoRow(Icons.attach_money, "Prix", "$price TND", color: Colors.green),
                        const Divider(),
                      ],
                      _buildInfoRow(Icons.swap_horiz, "Type d'échange", transaction),
                      const Divider(),
                      _buildInfoRow(Icons.person, "Fournisseur", providerEmail),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Bouton CACHÉ si Admin
              if (userRole != 'admin')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("Envoyer une demande de recyclage"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008B8B),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (userEmail == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Erreur : Utilisateur non connecté."), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance.collection('requests').add({
                          'offerId': offerId,
                          'offerType': type,
                          'providerEmail': providerEmail,
                          'recyclerEmail': userEmail,
                          'status': 'pending',
                          'requestedAt': FieldValue.serverTimestamp(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Demande envoyée avec succès !"), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? const Color(0xFF008B8B)),
        const SizedBox(width: 15),
        Text("$label :", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: color ?? Colors.black))),
      ],
    );
  }
}
// --- Page Historique des Offres (Fournisseur) ---

class ProviderOffersHistoryScreen extends StatefulWidget {
  final String userEmail;
  final void Function(Widget) navigateTo;

  const ProviderOffersHistoryScreen({
    super.key, 
    required this.userEmail,
    required this.navigateTo,
  });

  @override
  State<ProviderOffersHistoryScreen> createState() => _ProviderOffersHistoryScreenState();
}

class _ProviderOffersHistoryScreenState extends State<ProviderOffersHistoryScreen> {
  
  Future<void> _confirmAndDelete(BuildContext context, String collection, String offerId, String offerTitle) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: Text("Voulez-vous vraiment supprimer \"$offerTitle\" ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection(collection).doc(offerId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Offre supprimée avec succès")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Centre le contenu pour le Web
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre manuel
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "Mes Offres Publiées",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),
            
            // Liste des offres
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('offers')
                    .where('userEmail', isEqualTo: widget.userEmail)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                     // Gestion d'erreur d'index Firestore
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("Erreur de chargement: ${snapshot.error}", textAlign: TextAlign.center),
                    ));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Vous n'avez publié aucune offre."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var document = snapshot.data!.docs[index];
                      var offerId = document.id;
                      var data = document.data() as Map<String, dynamic>;

                      // 1. Formatage de la date
                      String dateFormatee = "Date inconnue";
                      if (data['createdAt'] != null) {
                        Timestamp timestamp = data['createdAt'];
                        DateTime date = timestamp.toDate();
                        dateFormatee = "${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute}";
                      }

                      // 2. Récupération des champs pour l'affichage 
                      String type = data['materialType'] ?? 'Non spécifié';
                      String qty = data['quantity']?.toString() ?? '0';
                      String loc = data['location'] ?? 'Non spécifié';
                      String trans = data['transactionType'] ?? 'Non spécifié';
                      String price = data['price']?.toString() ?? '';

                      // 3. Construction du texte 
                      String detailsAffiches = "Type : $type\n"
                                               "Quantité : $qty kg\n"
                                               "Lieu : $loc\n"
                                               "Transaction : $trans";
                      
                      if (trans == 'Vente' && price.isNotEmpty) {
                        detailsAffiches += "\nPrix : $price TND";
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            "Offre du $dateFormatee",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008B8B)),
                          ),
                          subtitle: Text(detailsAffiches),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                 
                                  widget.navigateTo(
                                    EditOfferScreen(
                                      offerId: offerId,
                                      initialData: data,
                                    )
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmAndDelete(context, 'offers', offerId, "Offre du $dateFormatee");
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Page Gestion des Demandes (Fournisseur) ---

class ProviderRequestsScreen extends StatelessWidget {
  final String providerEmail;
  const ProviderRequestsScreen({super.key, required this.providerEmail});

  // Fonction pour accepter une demande
  Future<void> _acceptRequest(BuildContext context, String requestId, String offerId) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference requestRef = FirebaseFirestore.instance.collection('requests').doc(requestId);
      batch.update(requestRef, {'status': 'accepted'});

      DocumentReference offerRef = FirebaseFirestore.instance.collection('offers').doc(offerId);
      batch.update(offerRef, {'status': 'Non disponible'});

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Demande acceptée. L'offre est maintenant non disponible."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Fonction pour refuser une demande
  Future<void> _rejectRequest(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
        'status': 'rejected'
      });
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande refusée."), backgroundColor: Colors.orange),
      );
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre manuel
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "Demandes Reçues",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),

            // Liste des demandes
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('requests')
                    .where('providerEmail', isEqualTo: providerEmail)
                    .orderBy('requestedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Aucune demande reçue."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      
                      String requestId = doc.id;
                      String offerId = data['offerId'] ?? '';
                      String recyclerEmail = data['recyclerEmail'] ?? 'Inconnu';
                      String offerType = data['offerType'] ?? 'Inconnu';
                      String status = data['status'] ?? 'pending';

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text("Demande pour: $offerType", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("De: $recyclerEmail\nStatut: ${_translateStatus(status)}"),
                          trailing: status == 'pending'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      onPressed: () => _acceptRequest(context, requestId, offerId),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () => _rejectRequest(context, requestId),
                                    ),
                                  ],
                                )
                              : Chip(
                                  label: Text(_translateStatus(status)),
                                  backgroundColor: status == 'accepted' ? Colors.green[100] : Colors.red[100],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'accepted': return 'Acceptée';
      case 'rejected': return 'Refusée';
      default: return status;
    }
  }
}


class RecyclerRequestsScreen extends StatefulWidget {
  final String recyclerEmail;
  const RecyclerRequestsScreen({super.key, required this.recyclerEmail});

  @override
  State<RecyclerRequestsScreen> createState() => _RecyclerRequestsScreenState();
}

class _RecyclerRequestsScreenState extends State<RecyclerRequestsScreen> {

  // Fonction de suppression avec confirmation
  Future<void> _confirmAndDelete(BuildContext context, String requestId, String offerTitle) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Annuler la demande"),
          content: Text("Voulez-vous vraiment supprimer votre demande pour \"$offerTitle\" ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Demande supprimée")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre manuel
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "Mes Demandes",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ),

            // Liste des demandes
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('requests')
                    .where('recyclerEmail', isEqualTo: widget.recyclerEmail)
                    .orderBy('requestedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Erreur de chargement: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Vous n'avez envoyé aucune demande."));
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var request = docs[index].data() as Map<String, dynamic>;
                      String requestId = docs[index].id;
                      
                      String status = request['status'] ?? 'pending';
                      String offerType = request['offerType'] ?? 'Offre inconnue';
                      
                      String statusText = status == 'pending' ? 'En attente' : (status == 'accepted' ? 'Acceptée' : 'Refusée');

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading: Icon(
                            status == 'pending' 
                              ? Icons.hourglass_top 
                              : (status == 'accepted' ? Icons.check_circle : Icons.cancel),
                            color: status == 'pending' 
                              ? Colors.orange 
                              : (status == 'accepted' ? Colors.green : Colors.red),
                          ),
                          title: Text("Offre: $offerType"),
                          subtitle: Text("Fournisseur: ${request['providerEmail']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status == 'accepted') 
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.email, size: 18),
                                  label: const Text("Contacter"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () {
                                    final Uri emailLaunchUri = Uri(
                                      scheme: 'mailto',
                                      path: request['providerEmail'],
                                      queryParameters: {
                                        'subject': 'Acceptation de votre demande - ValorTrash',
                                        'body': 'Bonjour, je suis intéressé par votre offre...'
                                      },
                                    );
                                    launchUrl(emailLaunchUri);
                                  },
                                )
                              else
                                Text(
                                  statusText.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'pending' ? Colors.orange : Colors.red,
                                  ),
                                ),
                              
                              const SizedBox(width: 10),
                              
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmAndDelete(context, requestId, offerType);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// --- Modifier Offre  ---


class EditOfferScreen extends StatefulWidget {
  final String offerId;
  final Map<String, dynamic> initialData;
  final VoidCallback? onUpdated; 

  const EditOfferScreen({
    super.key,
    required this.offerId,
    required this.initialData,
    this.onUpdated, 
  });

  @override
  State<EditOfferScreen> createState() => _EditOfferScreenState();
}

class _EditOfferScreenState extends State<EditOfferScreen> {
  late TextEditingController _qtyController;
  late TextEditingController _locController;
  late TextEditingController _priceController;

  String? _selectedMat;
  String? _selectedTrans;
  String? _selectedStatus;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _qtyController = TextEditingController(text: widget.initialData['quantity']?.toString() ?? '');
    _locController = TextEditingController(text: widget.initialData['location']?.toString() ?? '');
    _priceController = TextEditingController(text: widget.initialData['price']?.toString() ?? '');

    _selectedMat = widget.initialData['materialType']?.toString();
    _selectedTrans = widget.initialData['transactionType']?.toString();
    
    String rawStatus = widget.initialData['status']?.toString() ?? 'Disponible';
    if (rawStatus == 'available') {
      _selectedStatus = "Disponible";
    } else if (rawStatus == 'unavailable' || rawStatus == 'taken') {
      _selectedStatus = "Non disponible";
    } else {
      _selectedStatus = rawStatus;
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _locController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_selectedMat == null || _selectedTrans == null || _selectedStatus == null || 
        _qtyController.text.isEmpty || _locController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs."), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedTrans == 'Vente' && _priceController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un prix."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updatedData = {
        'materialType': _selectedMat,
        'quantity': _qtyController.text,
        'location': _locController.text,
        'transactionType': _selectedTrans,
        'price': _selectedTrans == 'Vente' ? _priceController.text : null,
        'status': _selectedStatus,
      };

      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Offre modifiée avec succès !"), backgroundColor: Colors.green),
        );
        
       
        if (widget.onUpdated != null) {
          widget.onUpdated!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Modifier l'offre",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ["Disponible", "Non disponible"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
                decoration: const InputDecoration(
                  labelText: "Statut de l'offre",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedMat,
                items: ["Plastique", "Carton", "Métaux", "Bois"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMat = v),
                decoration: const InputDecoration(labelText: "Type de matériau", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: "Quantité (Kg)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _locController,
                decoration: const InputDecoration(labelText: "Lieu de collecte", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedTrans,
                items: ["Vente", "Don"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTrans = v),
                decoration: const InputDecoration(labelText: "Type de transaction", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              if (_selectedTrans == 'Vente')
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Prix (TND)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              
              const SizedBox(height: 30),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text("Mettre à jour"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008B8B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saveChanges,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// =====================================================
// --- PAGE DES ARTICLES (ÉCONOMIE VERTE) ---
// =====================================================
class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  final Map<String, String> _articleImagesMap = const {
    "Guide de recyclage": "assets/images/guide.jpg",
    "L'importance de recyclage": "assets/images/importance.jpg",
  };
  final String _defaultArticleImage = "assets/images/default_article.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), 
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService().getArticles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("Aucun article pour le moment", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          var articles = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              var articleData = articles[index].data() as Map<String, dynamic>;
              return _buildModernArticleCard(context, articleData);
            },
          );
        },
      ),
    );
  }

  Widget _buildModernArticleCard(BuildContext context, Map<String, dynamic> article) {
    String title = article['title'] ?? 'Sans titre';
    
    String imagePath = _articleImagesMap[title] ?? _defaultArticleImage;
    
    String summary = article['summary'] ?? (article['content'] ?? '').substring(0, (article['content'] ?? '').length > 100 ? 100 : (article['content'] ?? '').length);
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article))),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                imagePath, // Utilisation de l'image correcte
                height: 180, 
                width: double.infinity, 
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  height: 180, 
                  color: Colors.green[50], 
                  child: Center(child: Icon(Icons.image, color: Colors.green[100], size: 50))
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(summary, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text("Lire la suite", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16, color: Color(0xFF2E7D32)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// =================================================
// --- PAGE DÉTAILS ARTICLE ---
// =================================================

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    // 1. Récupération du titre
    String title = article['title'] ?? 'Titre inconnu';
    String content = article['content'] ?? 'Pas de contenu disponible.';
    String author = article['author'] ?? 'ValorTrash';

    // 2. DÉFINITION DES IMAGES LOCALES 
    final Map<String, String> localImagesMap = {
      "Guide de recyclage": "assets/images/guide.jpg",
      "L'importance de recyclage": "assets/images/importance.jpg",
    };

    // 3. Recherche de l'image
    String imagePath = localImagesMap[title] ?? "assets/images/default_article.jpg";

    // Gestion de la date
    String date = "Date inconnue";
    if (article['createdAt'] != null && article['createdAt'] is Timestamp) {
      Timestamp timestamp = article['createdAt'];
      DateTime dateObj = timestamp.toDate();
      date = "${dateObj.day}/${dateObj.month}/${dateObj.year}";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de l'article"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Image.asset(
              imagePath,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITRE
                  Text(title, 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, height: 1.3)),
                  const SizedBox(height: 10),
                  
                  // AUTEUR ET DATE
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(author, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 15),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 30),

                  // CONTENU
                  Text(content, 
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// =================================================
// --- PAGE STATISTIQUES ---
// =================================================
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Détection de la taille de l'écran
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            const Text("Notre Impact", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
            Text("Ensemble pour un avenir vert", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 20),
            
            // Grille de Statistiques Compacte
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // 4 colonnes sur Web (parallèle), 2 colonnes sur Mobile
              crossAxisCount: isMobile ? 2 : 4, 
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Ratio plus compact 
              childAspectRatio: 0.9, 
              children: [
                _buildCompactStatCard("12,345", "Déchets\nValorisés", Icons.recycling, Colors.green),
                _buildCompactStatCard("56,789", "Utilisateurs\nActifs", Icons.group, Colors.blue),
                _buildCompactStatCard("8,901", "Tonnes CO2\nÉconomisées", Icons.co2, Colors.orange),
                _buildCompactStatCard("99%", "Taux de\nSatisfaction", Icons.thumb_up, Colors.purple),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Petite note en bas 
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Chaque action compte. Merci de faire partie du changement.",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une carte de stat COMPACTE
  Widget _buildCompactStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(icon, color: color, size: 28), 
          const SizedBox(height: 10),
          FittedBox( 
            child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color))
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500, height: 1.2)
          ),
        ],
      ),
    );
  }
}
// ====================================================
// --- PAGE CONTACT ---
// ====================================================
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  void _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  void _makeCall(String phoneNumber) async {
    final Uri telLaunchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(telLaunchUri)) {
      await launchUrl(telLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    String adminEmail = "contact@valortrash.tn";
    String adminPhone = "+216 20 123 456";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.headset_mic_outlined, size: 40, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 15),
                  const Text("Contactez-nous", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 5),
                  Text("Nous sommes là pour vous aider", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Cartes de Contact
            _buildContactCard(
              icon: Icons.email_outlined,
              title: "Email",
              subtitle: "Écrivez-nous directement",
              value: adminEmail,
              color: Colors.red,
              onTap: () => _launchEmail(adminEmail),
            ),
            const SizedBox(height: 15),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: "Téléphone",
              subtitle: "Appelez-nous",
              value: adminPhone,
              color: Colors.green,
              onTap: () => _makeCall(adminPhone),
            ),
            const SizedBox(height: 30),

            // Formulaire Rapide 
            const Text("Envoyer un message", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(decoration: InputDecoration(hintText: "Votre nom", prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100])),
                    const SizedBox(height: 10),
                    TextField(decoration: InputDecoration(hintText: "Votre message", prefixIcon: Icon(Icons.message_outlined, color: Colors.grey[400]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[100]), maxLines: 3),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text("Envoyer", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () {},
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String title, required String subtitle, required String value, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(color: Colors.grey[600])),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ),
    );
  }
}
// ==================================================
// --- PAGE À PROPOS ---
// ==================================================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Détection de la taille de l'écran
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER AVEC FOND VERT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipOval(child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.recycling, size: 50, color: Color(0xFF2E7D32)))),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("VALORTRASH", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text("Tous Recycleurs, Acteurs Solidaires de l'Humanité", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, letterSpacing: 1.2)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // NOTRE HISTOIRE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Notre Histoire", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                  const Divider(color: Color(0xFF2E7D32), thickness: 2, endIndent: 280),
                  const SizedBox(height: 10),
                  Text(
                    "ValorTrash est né d'une conviction simple : en Tunisie, nos déchets sont une richesse inexploitée. Face à l'urgence écologique, ValorTrash voit les déchets non plus comme un fardeau, mais comme une opportunité économique. Notre mission est de démocratiser le recyclage en Tunisie en créant le pont numérique manquant entre les citoyens et les structures de valorisation. Ensemble, transformons nos habitudes pour un avenir durable.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6),
                  ),
                  const SizedBox(height: 25),

                  // NOS OBJECTIFS 
                  const Text("Nos Objectifs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
                  const Divider(color: Color(0xFF2E7D32), thickness: 2, endIndent: 280),
                  const SizedBox(height: 15),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 2 : 4, 
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9, 
                    children: [
                      _buildCompactObjectiveCard(Icons.public, "Impact Environnemental", Colors.green),
                      _buildCompactObjectiveCard(Icons.handshake, "Solidarité", Colors.blue),
                      _buildCompactObjectiveCard(Icons.monetization_on, "Économie Circulaire", Colors.orange),
                      _buildCompactObjectiveCard(Icons.school, "Sensibilisation", Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Center(child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget CARTE COMPACTE
  static Widget _buildCompactObjectiveCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(10), // Padding réduit
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22), // Icône un peu plus petite
          ),
          const SizedBox(height: 8),
          Text(
            title, 
            textAlign: TextAlign.center, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11) // Texte plus petit
          ),
          
        ],
      ),
    );
  }
}

// ============================================================
// CHATBOT IA INTELLIGENT (VERSION 1.0)
// ============================================================

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // Base de connaissances du Bot 
  final Map<String, String> _knowledgeBase = {
    // Matériaux
    'carton': '📦 **Carton** : Dépliez les cartons et retirez les adhésifs. Ne jetez pas les cartons souillés (pizza) avec les propres.',
    'plastique': '🥤 **Plastique** : Vérifiez le code de tri (triangle). Rincez les bouteilles et écrasez-les pour gagner de la place.',
    'métal': '🛠️ **Métal** : Lavez les canettes et bocaux. Ils se recyclent à l\'infini !',
    'verre': '🍷 **Verre** : Déposez les bouteilles sans bouchon. Attention : la vaisselle et les miroirs ne vont pas dans le verre de tri.',
    'bois': '🪵 **Bois** : Séparez le bois traité du bois brut. Le bois humide ou pourri n\'est généralement pas recyclable.',
    
    // Fonctionnement de l'app
    'offre': 'Pour publier une offre, connectez-vous en tant que **Fournisseur**, puis remplissez le formulaire rapide sur votre tableau de bord.',
    'vendre': 'Vous pouvez vendre vos déchets en créant une offre de type "Vente". Le recycleur vous contactera pour convenir du prix.',
    'donner': 'Vous pouvez donner vos déchets en créant une offre de type "Don". C\'est un geste solidaire et écologique !',
    'inscription': 'Pour vous inscrire, cliquez sur "S\'inscrire" sur la page d\'accueil. Choisissez votre rôle : Fournisseur ou Recycleur.',
    'recycleur': 'Un recycleur peut chercher des offres, envoyer des demandes et contacter les fournisseurs.',
    'fournisseur': 'Un fournisseur peut déclarer des lots de déchets et recevoir des demandes de recyclage.',
    'bonjour': 'Bonjour ! 👋 Je suis l\'assistant ValorTrash. Comment puis-je vous aider ? Vous pouvez me poser des questions sur le tri (ex: "Carton") ou l\'utilisation de l\'application.',
    'salut': 'Salut ! 👋 Je suis là pour vous aider à valoriser vos déchets. Que voulez-vous savoir ?',
    'merci': 'Avec plaisir ! 🌱 N\'hésitez pas si vous avez d\'autres questions. Ensemble, valorisons nos déchets !',
    'aide': 'Je peux vous aider sur les sujets suivants :\n- Comment trier (Carton, Plastique, Verre...)\n- Comment publier une offre\n- Comment s\'inscrire\n\nTapez un mot-clé !',
    'contact': 'Vous pouvez contacter l\'équipe ValorTrash via la page "Contact" dans le menu.',
  };

  @override
  void initState() {
    super.initState();
    // Message de bienvenue
    _addBotMessage("Bonjour ! 👋 Je suis l'assistant virtuel ValorTrash.\n\nJe peux vous renseigner sur le **tri sélectif** ou vous aider à **utiliser l'application**.\n\nTapez votre question (ex: *Comment trier le plastique ?*)");
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: false));
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    _controller.clear();
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
    });

    // Simuler un délai de "réflexion"
    Future.delayed(const Duration(milliseconds: 500), () {
      _processInput(text);
      _scrollToBottom();
    });
  }

  void _processInput(String input) {
    String response = _findBestAnswer(input);
    _addBotMessage(response);
  }

  String _findBestAnswer(String input) {
    input = input.toLowerCase().trim();
    
    // Recherche de mots-clés dans la base de connaissances
    List<String> keys = _knowledgeBase.keys.toList();
    
    // Priorité aux mots-clés exacts ou contenus
    for (var key in keys) {
      if (input.contains(key)) {
        return _knowledgeBase[key]!;
      }
    }

    // Réponse par défaut si aucun mot-clé trouvé
    return "🤔 Je ne suis pas sûr de comprendre votre demande.\n\nVous pouvez me demander des informations sur :\n- Les matériaux (*Carton, Plastique, Verre...*)\n- L'application (*Offre, Inscription, Contact*)\n\nOu tapez **'Aide'** pour voir ce que je peux faire.";
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant IA"),
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          // Zone des messages
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              reverse: true, 
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _buildMessage(_messages[index]),
            ),
          ),
          const Divider(height: 1.0),
          // Zone de saisie
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  // Widget pour un message
  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.isUser
            ? _buildUserLayout(message)
            : _buildBotLayout(message),
      ),
    );
  }

  // Layout Bot
  List<Widget> _buildBotLayout(ChatMessage message) {
    return [
      // Avatar Bot
      Container(
        margin: const EdgeInsets.only(right: 16.0),
        child: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
        ),
      ),
      // Bulle de message
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                message.text,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // Layout User (Avatar à droite)
  List<Widget> _buildUserLayout(ChatMessage message) {
    return [
      // Bulle de message
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                message.text,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      // Avatar User
      Container(
        margin: const EdgeInsets.only(left: 16.0),
        child: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ),
    ];
  }

  // Zone de saisie de texte
  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _controller,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: "Écrivez votre message...",
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                onPressed: () => _handleSubmitted(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modèle de données pour un message
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
// ===============================================================
// --- CLIPPER POUR LA VAGUE  ---
// ===============================================================
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.75); 

    // Première vague
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height * 0.75);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    // Deuxième vague
    var secondControlPoint = Offset(size.width * 3 / 4, size.height * 0.6);
    var secondEndPoint = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// ============================================================
// WIDGET FORMULAIRE INDÉPENDANT 
// ============================================================
class QuickOfferForm extends StatefulWidget {
  final String userEmail;
  const QuickOfferForm({super.key, required this.userEmail});

  @override
  State<QuickOfferForm> createState() => _QuickOfferFormState();
}

class _QuickOfferFormState extends State<QuickOfferForm> {
  String? _selectedType;
  String? _selectedTrans;
  final _qtyController = TextEditingController();
  final _locController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _locController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    // Validation
    if (_selectedType == null || _selectedTrans == null || _qtyController.text.isEmpty || _locController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires."), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedTrans == 'Vente' && _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un prix."), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseService().addOffer(
        userEmail: widget.userEmail,
        materialType: _selectedType!,
        quantity: _qtyController.text,
        location: _locController.text,
        transactionType: _selectedTrans!,
        price: _selectedTrans == 'Vente' ? _priceController.text : null,
        status: "Disponible"
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Offre publiée avec succès !"), backgroundColor: Colors.green),
        );
        
        // Vider le formulaire après succès
        _qtyController.clear();
        _locController.clear();
        _priceController.clear();
        setState(() {
          _selectedType = null;
          _selectedTrans = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
        children: [
          const Text("Formulaire Rapide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          
          // Type Matériau
          DropdownButtonFormField<String>(
            value: _selectedType,
            hint: const Text("Type de matériau *"),
            items: ["Carton", "Plastique", "Métal", "Bois"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedType = v),
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
          ),
          const SizedBox(height: 10),

          // Quantité
          TextField(
            controller: _qtyController,
            decoration: const InputDecoration(hintText: "Quantité (Kg) *", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
            keyboardType: TextInputType.number,
            scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          ),
          const SizedBox(height: 10),

          // Lieu
          TextField(
            controller: _locController,
            decoration: const InputDecoration(hintText: "Lieu de collecte *", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
            scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          ),
          const SizedBox(height: 10),

          // Type Transaction
          DropdownButtonFormField<String>(
            value: _selectedTrans,
            hint: const Text("Type d'échange *"),
            items: ["Vente", "Don"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedTrans = v),
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
          ),
          
          // Prix (Conditionnel)
          if (_selectedTrans == 'Vente') ...[
             const SizedBox(height: 10),
             TextField(
               controller: _priceController,
               decoration: const InputDecoration(hintText: "Prix (TND) *", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
               keyboardType: TextInputType.number,
               scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
             ),
          ],
          
          const SizedBox(height: 15),
          
          // Bouton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Déclarer"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)), // Vert foncé
              onPressed: _submitOffer,
            ),
          )
        ],
      ),
    );
  }
}
