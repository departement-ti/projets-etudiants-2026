import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyActivitiesScreen extends StatefulWidget {
  final String? targetEmail;
  const DailyActivitiesScreen({super.key, this.targetEmail});

  @override
  State<DailyActivitiesScreen> createState() => _DailyActivitiesScreenState();
}

class _DailyActivitiesScreenState extends State<DailyActivitiesScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  int _waterGlasses = 0;
  int _mealsTaken = 0;
  int _exercisesDone = 0;
  int _walksTaken = 0;
  bool _morningRoutine = false;
  bool _eveningRoutine = false;
  bool _socialInteraction = false;
  bool _saving = false;

  String get _userEmail => widget.targetEmail ?? currentUser!.email!;

  @override
  void initState() {
    super.initState();
    _loadTodayActivities();
  }

  Future<void> _loadTodayActivities() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userEmail)
          .collection('DailyActivities')
          .doc(todayStr)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _waterGlasses = data['waterGlasses'] ?? 0;
          _mealsTaken = data['mealsTaken'] ?? 0;
          _exercisesDone = data['exercisesDone'] ?? 0;
          _walksTaken = data['walksTaken'] ?? 0;
          _morningRoutine = data['morningRoutine'] ?? false;
          _eveningRoutine = data['eveningRoutine'] ?? false;
          _socialInteraction = data['socialInteraction'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  Future<void> _saveActivities() async {
    setState(() => _saving = true);
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final totalCount = 4 + 3; // compteurs + booléens
    final doneCount = _waterGlasses.clamp(0, 8) +
        _mealsTaken.clamp(0, 3) +
        (_exercisesDone > 0 ? 1 : 0) +
        (_walksTaken > 0 ? 1 : 0) +
        (_morningRoutine ? 1 : 0) +
        (_eveningRoutine ? 1 : 0) +
        (_socialInteraction ? 1 : 0);

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userEmail)
          .collection('DailyActivities')
          .doc(todayStr)
          .set({
        'waterGlasses': _waterGlasses.clamp(0, 8),
        'mealsTaken': _mealsTaken.clamp(0, 3),
        'exercisesDone': _exercisesDone.clamp(0, 5),
        'walksTaken': _walksTaken.clamp(0, 3),
        'morningRoutine': _morningRoutine,
        'eveningRoutine': _eveningRoutine,
        'socialInteraction': _socialInteraction,
        'doneCount': doneCount,
        'totalCount': totalCount,
        'date': todayStr,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activités sauvegardées'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      print('Error saving activities: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités Quotidiennes'),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
        actions: _saving
            ? const [Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hydratation
          _buildSectionCard(
            icon: Icons.water_drop,
            title: 'Hydratation',
            color: Colors.blue,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(8, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _waterGlasses = i + 1),
                      child: Icon(
                        i < _waterGlasses ? Icons.water_drop : Icons.water_drop_outlined,
                        size: 32,
                        color: i < _waterGlasses ? Colors.blue : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text('$_waterGlasses / 8 verres',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),

          // Repas
          _buildSectionCard(
            icon: Icons.restaurant,
            title: 'Repas',
            color: Colors.orange,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMealButton('🍳', 'Petit-déj', 0),
                _buildMealButton('🍽️', 'Déjeuner', 1),
                _buildMealButton('🌙', 'Dîner', 2),
              ],
            ),
          ),

          // Exercice
          _buildSectionCard(
            icon: Icons.fitness_center,
            title: 'Exercices',
            color: Colors.green,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCounterButton('-', () => setState(() => _exercisesDone = (_exercisesDone - 1).clamp(0, 5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('$_exercisesDone exercices',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    _buildCounterButton('+', () => setState(() => _exercisesDone = (_exercisesDone + 1).clamp(0, 5))),
                  ],
                ),
              ],
            ),
          ),

          // Marche
          _buildSectionCard(
            icon: Icons.directions_walk,
            title: 'Marche',
            color: Colors.teal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWalkButton(_walksTaken >= 1, 'Matin', () => setState(() => _walksTaken = _walksTaken >= 1 ? 0 : 1)),
                _buildWalkButton(_walksTaken >= 2, 'Midi', () => setState(() => _walksTaken = _walksTaken >= 2 ? 1 : 2)),
                _buildWalkButton(_walksTaken >= 3, 'Soir', () => setState(() => _walksTaken = _walksTaken >= 3 ? 2 : 3)),
              ],
            ),
          ),

          // Routines
          _buildSectionCard(
            icon: Icons.wb_sunny,
            title: 'Routines',
            color: Colors.purple,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Routine du matin 🌅', style: GoogleFonts.poppins(fontSize: 16)),
                  value: _morningRoutine,
                  activeColor: const Color.fromRGBO(7, 82, 96, 1),
                  onChanged: (v) => setState(() => _morningRoutine = v),
                ),
                SwitchListTile(
                  title: Text('Routine du soir 🌙', style: GoogleFonts.poppins(fontSize: 16)),
                  value: _eveningRoutine,
                  activeColor: const Color.fromRGBO(7, 82, 96, 1),
                  onChanged: (v) => setState(() => _eveningRoutine = v),
                ),
              ],
            ),
          ),

          // Social
          _buildSectionCard(
            icon: Icons.people,
            title: 'Interaction sociale',
            color: Colors.pink,
            child: SwitchListTile(
              title: Text('Contact avec famille/amis aujourd\'hui', style: GoogleFonts.poppins(fontSize: 16)),
              value: _socialInteraction,
              activeColor: const Color.fromRGBO(7, 82, 96, 1),
              onChanged: (v) => setState(() => _socialInteraction = v),
            ),
          ),

          const SizedBox(height: 24),

          // Bouton sauvegarder
          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveActivities,
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.save),
              label: Text('Sauvegarder les activités',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMealButton(String emoji, String label, int index) {
    final taken = _mealsTaken > index;
    return GestureDetector(
      onTap: () => setState(() {
        if (taken) {
          _mealsTaken = (_mealsTaken - 1).clamp(0, 3);
        } else {
          _mealsTaken = index + 1;
        }
      }),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: taken ? Colors.orange.withAlpha(50) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: taken ? Colors.orange : Colors.grey[300]!, width: 2),
            ),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: taken ? Colors.orange : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWalkButton(bool active, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: active ? Colors.teal.withAlpha(50) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: active ? Colors.teal : Colors.grey[300]!, width: 2),
            ),
            child: Icon(Icons.directions_walk, size: 28, color: active ? Colors.teal : Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: active ? Colors.teal : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCounterButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(7, 82, 96, 1).withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text(label, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color.fromRGBO(7, 82, 96, 1)))),
      ),
    );
  }
}
