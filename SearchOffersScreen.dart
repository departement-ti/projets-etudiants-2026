import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclerOffersPage extends StatefulWidget {
  const RecyclerOffersPage({super.key});

  @override
  State<RecyclerOffersPage> createState() => _RecyclerOffersPageState();
}

class _RecyclerOffersPageState extends State<RecyclerOffersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offres Disponibles"),
        backgroundColor: const Color(0xFF3AA17E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Gestion des erreurs
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

          // 2. En cours de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Liste vide
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Aucune offre disponible pour le moment."),
            );
          }

          // 4. Affichage des offres
          var offers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              var offer = offers[index].data() as Map<String, dynamic>;
              String offerId = offers[index].id;

              // Sécurisation des données
              // On vérifie 'materialType' (nom utilisé dans AddOfferScreen) ou 'type'
              String type = offer['materialType']?.toString() ?? offer['type']?.toString() ?? 'Non spécifié';
              String quantity = offer['quantity']?.toString() ?? '0';
              String location = offer['location']?.toString() ?? 'Non spécifié';

              return InkWell(
                // ACTION : Cliquer sur la carte ouvre les détails
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // On ajoute userEmail: widget.userEmail
                      builder: (_) => OfferDetailScreen(
                        offerId: offerId, 
                        offerData: offer,
                        userEmail: widget.userEmail, 
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ligne du haut : Type et Quantité
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.delete_outline, color: Color(0xFF3AA17E)),
                                const SizedBox(width: 10),
                                Text(
                                  type,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "$quantity kg",
                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Lieu
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(location, style: const TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Bouton Envoyer Demande
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text("Envoyer demande de recyclage"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3AA17E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              _sendRecyclingRequest(offerId, type);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fonction pour envoyer la demande
    void _sendRecyclingRequest(String offerId, String offerType, String providerEmail) async {
    
    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'offerId': offerId,
        'offerType': offerType,
        'providerEmail': providerEmail, // Email du propriétaire de l'offre
        'recyclerEmail': 'EMAIL_DU_USER_CONNECTE', 
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Votre demande a été envoyé vous receverez la réponse par email"),
          backgroundColor: Color(0xFF3AA17E),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }
}