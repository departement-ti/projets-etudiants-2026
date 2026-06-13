import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpecialtiesScreen extends StatefulWidget {
  const SpecialtiesScreen({super.key});

  @override
  State<SpecialtiesScreen> createState() => _SpecialtiesScreenState();
}

class _SpecialtiesScreenState extends State<SpecialtiesScreen> {
  List<String> _specialties = [];
  bool _isLoading = true;
  final _addController = TextEditingController();

  static const List<String> _suggestions = [
    'Médecine générale',
    'Cardiologie',
    'Dermatologie',
    'Pédiatrie',
    'Gynécologie',
    'Neurologie',
    'Orthopédie',
    'Ophtalmologie',
    'ORL',
    'Psychiatrie',
    'Radiologie',
    'Chirurgie générale',
    'Anesthésiologie',
    'Endocrinologie',
    'Gastro-entérologie',
    'Rhumatologie',
    'Urologie',
    'Pneumologie',
    'Hématologie',
    'Oncologie',
    'Néphrologie',
    'Médecine d\'urgence',
    'Médecine du sport',
    'Gériatrie',
    'Médecine interne',
  ];

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _specialties = List<String>.from(data['specialties'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addSpecialty(String specialty) async {
    final trimmed = specialty.trim();
    if (trimmed.isEmpty || _specialties.contains(trimmed)) return;
    setState(() {
      _specialties.add(trimmed);
    });
    _addController.clear();
    await _saveToFirestore();
  }

  Future<void> _removeSpecialty(String specialty) async {
    setState(() {
      _specialties.remove(specialty);
    });
    await _saveToFirestore();
  }

  Future<void> _saveToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('Users').doc(user.email).update({
      'specialties': _specialties,
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Ajouter une spécialité',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addController,
              decoration: InputDecoration(
                hintText: 'Rechercher ou saisir...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView(
                children: _suggestions
                    .where((s) => s.toLowerCase().contains(
                          _addController.text.toLowerCase(),
                        ))
                    .map((s) => ListTile(
                          title: Text(s, style: GoogleFonts.poppins()),
                          onTap: () {
                            _addSpecialty(s);
                            Navigator.pop(ctx);
                          },
                          dense: true,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _addSpecialty(_addController.text);
              Navigator.pop(ctx);
            },
            child: Text(
              'Ajouter',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color.fromRGBO(7, 82, 96, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spécialités',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color.fromRGBO(7, 82, 96, 1)),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _specialties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune spécialité ajoutée',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: Text('Ajouter une spécialité'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _specialties.length,
                  itemBuilder: (context, index) {
                    final specialty = _specialties[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(7, 82, 96, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            color: Color.fromRGBO(7, 82, 96, 1),
                          ),
                        ),
                        title: Text(
                          specialty,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _removeSpecialty(specialty),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
