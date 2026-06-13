import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CabinetInfoScreen extends StatefulWidget {
  const CabinetInfoScreen({super.key});

  @override
  State<CabinetInfoScreen> createState() => _CabinetInfoScreenState();
}

class _CabinetInfoScreenState extends State<CabinetInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hoursController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCabinetInfo();
  }

  Future<void> _loadCabinetInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['cabinetName'] ?? '';
      _addressController.text = data['cabinetAddress'] ?? '';
      _phoneController.text = data['cabinetPhone'] ?? '';
      _hoursController.text = data['cabinetHours'] ?? '';
      _emailController.text = data['cabinetEmail'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('Users').doc(user.email).update({
      'cabinetName': _nameController.text.trim(),
      'cabinetAddress': _addressController.text.trim(),
      'cabinetPhone': _phoneController.text.trim(),
      'cabinetHours': _hoursController.text.trim(),
      'cabinetEmail': _emailController.text.trim(),
    });
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informations du cabinet enregistrées')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Informations du cabinet',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              'Enregistrer',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color.fromRGBO(7, 82, 96, 1),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'Nom du cabinet',
                      hint: 'Ex: Cabinet Médical Dr. X',
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _addressController,
                      label: 'Adresse',
                      hint: '123 Rue Exemple, Ville',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      hint: 'Ex: +216 00 000 000',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _emailController,
                      label: 'Email du cabinet',
                      hint: 'cabinet@exemple.com',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _hoursController,
                      label: 'Horaires',
                      hint: 'Ex: Lun-Ven: 9h-17h, Sam: 9h-12h',
                      icon: Icons.schedule,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color.fromRGBO(7, 82, 96, 1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromRGBO(7, 82, 96, 1)),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }
}
