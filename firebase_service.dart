import 'dart:io'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 

// ============================================================
// 4. Service Firebase (Backend)
// ============================================================
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Inscription
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

  // Connexion
  Future<String?> login(String email, String password) async {
    try {
      var query = await _firestore.collection('users')
          .where('email', isEqualTo: email).where('password', isEqualTo: password).get();
      if (query.docs.isNotEmpty) return query.docs.first['role'];
      return null;
    } catch (e) { return null; }
  }

  // Mise à jour du profil utilisateur
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

  // Upload Image
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('offers_images/$fileName');
      TaskSnapshot snapshot = await ref.putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) { return null; }
  }

  // Ajouter Offre 
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
  
  // Récupérer Offres
  Stream<QuerySnapshot> getOffers() {
    return _firestore.collection('offers').where('status', isEqualTo: 'Disponible')
        .orderBy('createdAt', descending: true).snapshots();
  }

  // Supprimer une offre
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();
    } catch (e) {
      print("Erreur suppression offre: $e");
    }
  }

  // Supprimer un utilisateur
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