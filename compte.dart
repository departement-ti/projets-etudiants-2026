import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:valortrash/screens/auth/login_screen.dart'; 

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  
  // Contrôleurs pour les champs modifiables
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // 1. Récupérer les données actuelles
  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user.uid)
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = _user!.email ?? '';
            _phoneController.text = data['phone'] ?? '';
            _locationController.text = data['location'] ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Erreur: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Sauvegarder les modifications (Nom, Tel, Localisation, Email)
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Mise à jour Firestore
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'location': _locationController.text,
      });

      // Mise à jour de l'Email dans Firebase Auth (si changé)
      if (_emailController.text != _user!.email) {
        await _user!.updateEmail(_emailController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès !"), backgroundColor: Colors.green),
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur Auth: ${e.message}"), backgroundColor: Colors.red),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // 3. Fonction pour changer le mot de passe (avec boîte de dialogue)
  Future<void> _changePassword() async {
    final _currentPassController = TextEditingController();
    final _newPassController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mot de passe actuel",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nouveau mot de passe",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // 1. Réauthentifier l'utilisateur
                AuthCredential credential = EmailAuthProvider.credential(
                  email: _user!.email!,
                  password: _currentPassController.text,
                );
                await _user!.reauthenticateWithCredential(credential);

                // 2. Changer le mot de passe
                await _user!.updatePassword(_newPassController.text);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Mot de passe changé avec succès !"), backgroundColor: Colors.green),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Erreur: Mot de passe actuel incorrect."), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  // 4. Déconnexion
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mon Compte", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3AA17E),
        elevation: 0,
        actions: [
          // Bouton Modifier / Annuler
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) _fetchUserData(); 
              });
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF3AA17E).withOpacity(0.2),
                    child: const Icon(Icons.person, size: 50, color: Color(0xFF3AA17E)),
                  ),
                  const SizedBox(height: 30),

                  // Formulaire
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        // Nom
                        _buildEditableField(
                          label: "Nom complet",
                          icon: Icons.person_outline,
                          controller: _nameController,
                          isEnabled: _isEditing,
                        ),
                        const SizedBox(height: 20),

                        // Email
                        _buildEditableField(
                          label: "Email",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          isEnabled: _isEditing,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Téléphone
                        _buildEditableField(
                          label: "Téléphone",
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          isEnabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),

                        // Localisation
                        _buildEditableField(
                          label: "Ville",
                          icon: Icons.location_on_outlined,
                          controller: _locationController,
                          isEnabled: _isEditing,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton Sauvegarder 
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3AA17E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("Sauvegarder les modifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  const SizedBox(height: 15),

                  // Bouton Changer Mot de passe
                  if (!_isEditing)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline, color: Colors.orange),
                        title: const Text("Changer le mot de passe"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _changePassword,
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Bouton Déconnexion
                  TextButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: _logout,
                    label: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget personnalisé pour les champs modifiables
  Widget _buildEditableField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isEnabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: isEnabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isEnabled ? const Color(0xFF3AA17E) : Colors.grey),
        filled: true,
        fillColor: isEnabled ? Colors.grey[50] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3AA17E), width: 1),
        ),
      ),
    );
  }
}