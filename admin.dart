import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  final String email;
  const AdminScreen({super.key, required this.email});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Panneau Admin", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.list), text: "Offres"),
              Tab(icon: Icon(Icons.people), text: "Utilisateurs"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOffersList(),
            _buildUsersList(),
          ],
        ),
      ),
    );
  }

  // --- Liste des Offres ---
  Widget _buildOffersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('offers').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        
        if (docs.isEmpty) return const Center(child: Text("Aucune offre."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var offer = docs[index].data() as Map<String, dynamic>;
            String id = docs[index].id;
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.grey),
                title: Text(offer['materialType'] ?? 'Offre'),
                subtitle: Text("Par: ${offer['userEmail']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  // On utilise la fonction locale _deleteOffer
                  onPressed: () => _confirmDelete("cette offre", () => _deleteOffer(id)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Liste des Utilisateurs ---
  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("Aucun utilisateur."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var user = docs[index].data() as Map<String, dynamic>;
            String userEmail = user['email'];
            String role = user['role'] ?? 'user';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: Icon(Icons.person, color: role == 'admin' ? Colors.red : Colors.grey),
                title: Text(userEmail),
                subtitle: Text("Rôle: $role"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  // On utilise la fonction locale _deleteUser
                  onPressed: () => _confirmDelete("cet utilisateur", () => _deleteUser(userEmail)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Fonctions de suppression directes ---
  
  Future<void> _deleteOffer(String id) async {
    try {
      await FirebaseFirestore.instance.collection('offers').doc(id).delete();
    } catch (e) {
      print("Erreur: $e");
    }
  }

  Future<void> _deleteUser(String email) async {
    try {
      var query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  // --- Boîte de dialogue de confirmation ---
  void _confirmDelete(String item, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text("Voulez-vous vraiment supprimer $item ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}