import 'package:flutter/material.dart';

// --- Page d'Accueil ---
class HomePage extends StatelessWidget {
  final String? role;
  final String? email; 

  const HomePage({super.key, this.role, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE0F7FA)])),
        child: Column(
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    height: 300,
                    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF004D7A), Color(0xFF008B8B), Color(0xFF40E0D0)])),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(child: Container(height: 80, width: 80, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]), child: ClipOval(child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.recycling, size: 40, color: Color(0xFF008B8B)))))),
                      const SizedBox(height: 10),
                      const Text("VALORTRASH", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(role == null ? "Tous recycleurs, acteurs solidaires de l'humanité!" : (role == 'fournisseur' ? "Espace Fournisseur" : "Espace Recycleur"), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 20),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _StatBar()),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(role == null ? "Bienvenue sur ValorTrash" : "Que voulez-vous faire aujourd'hui ?", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D3557)), textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _buildCategoryItem("Plastique", Icons.local_drink, Colors.blue), 
                      _buildCategoryItem("Carton", Icons.inventory_2, Colors.orange), 
                      _buildCategoryItem("Métaux", Icons.precision_manufacturing, Colors.blueGrey), 
                      _buildCategoryItem("Bois", Icons.forest, Colors.brown)
                    ]),
                    const SizedBox(height: 50),
                    _buildMainAction(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF008B8B),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(role == null ? Icons.login : Icons.history), label: role == null ? "Connexion" : "Historique"),
          BottomNavigationBarItem(icon: Icon(role == null ? Icons.person_add : Icons.person), label: role == null ? "Inscription" : "Profil"),
        ],
        onTap: (index) {
          if (role == null) {
            // Actions si NON connecté
            if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
          } else {
            // Actions SI CONNECTÉ
            if (index == 2) {
              // Navigation vers Mon Compte en passant l'email et le rôle
              Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen(email: email!, role: role!)));
            }
          }
        },
      ),
    );
  }

  Widget _buildMainAction(BuildContext context) {
    if (role == null) return _buildGradientButton(context, "Commencer l'aventure", const LoginScreen());
    
    if (role == 'admin') {
      return _buildGradientButton(context, "Panneau d'Administration", AdminScreen(email: email ?? ''));
    }

    if (role == 'fournisseur') return _buildGradientButton(context, "Publier offre", const AddOfferScreen());
    
    return _buildGradientButton(context, "Rechercher offre", SearchOffersScreen());
  }
  Widget _buildGradientButton(BuildContext context, String text, Widget page) {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFF40E0D0), Color(0xFF008B8B)]), boxShadow: [BoxShadow(color: const Color(0xFF008B8B).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)), style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
    );
  }

  static Widget _buildCategoryItem(String label, IconData icon, Color color) {
    return SizedBox(width: 75, child: Column(children: [
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)]), child: Icon(icon, color: color, size: 28)), 
      const SizedBox(height: 10), 
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1D3557)))
    ]));
  }
}