import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormulaireDemande extends StatefulWidget {
  const FormulaireDemande({super.key});

  @override
  State<FormulaireDemande> createState() => _FormulaireDemandeState();
}

class _FormulaireDemandeState extends State<FormulaireDemande> {
  // Contrôleurs
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedWasteType;
  bool _isLoading = false; // Pour afficher un chargement pendant l'envoi

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publishOffer() async {
    // Validation
    if (_selectedWasteType == null || 
        _quantityController.text.isEmpty || 
        _locationController.text.isEmpty) {
      _showMessage("Veuillez remplir tous les champs obligatoires.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Envoi vers Firebase
      await FirebaseFirestore.instance.collection('offers').add({
        'type': _selectedWasteType,
        'quantity': _quantityController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'status': 'disponible', // Statut par défaut
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Message de succès 
      if (!mounted) return;
      _showMessage("Votre offre est publiée avec succès !", isError: false);

      // 3. Nettoyage des champs
      _quantityController.clear();
      _locationController.clear();
      _descriptionController.clear();
      setState(() => _selectedWasteType = null);

    } catch (e) {
      _showMessage("Erreur: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fonction utilitaire pour afficher les messages
  void _showMessage(String message, {required bool isError}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text("Nouvelle Demande", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3AA17E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Type de Déchet"),
            const SizedBox(height: 10),
            _buildDropdownField(),

            const SizedBox(height: 20),
            _buildSectionTitle("Quantité (kg)"),
            const SizedBox(height: 10),
            _buildTextField("Ex: 10 kg", Icons.scale, _quantityController),

            const SizedBox(height: 20),
            _buildSectionTitle("Lieu de Collecte"),
            const SizedBox(height: 10),
            _buildTextField("Ex: Sousse, Centre Ville", Icons.location_on, _locationController),

            const SizedBox(height: 20),
            _buildSectionTitle("Description"),
            const SizedBox(height: 10),
            _buildTextField("Ajoutez des détails...", Icons.description, _descriptionController, maxLines: 3),

            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E4053)),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF3AA17E)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Choisir le type (Plastique, Carton...)"),
          value: _selectedWasteType,
          items: ["Plastique", "Carton", "Métaux", "Bois"].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedWasteType = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4CBF9E), Color(0xFF3AA17E)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF3AA17E).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _publishOffer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Envoyer ma Demande",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
      ),
    );
  }
}