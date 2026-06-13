import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final Map<String, Map<String, String?>> _availability = {
    'Lundi': {'start': null, 'end': null},
    'Mardi': {'start': null, 'end': null},
    'Mercredi': {'start': null, 'end': null},
    'Jeudi': {'start': null, 'end': null},
    'Vendredi': {'start': null, 'end': null},
    'Samedi': {'start': null, 'end': null},
    'Dimanche': {'start': null, 'end': null},
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      final saved = data['availability'] as Map<String, dynamic>?;
      if (saved != null) {
        for (final day in _availability.keys) {
          if (saved[day] != null) {
            final dayData = saved[day] as Map<String, dynamic>?;
            _availability[day] = {
              'start': dayData?['start'] as String?,
              'end': dayData?['end'] as String?,
            };
          }
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('Users').doc(user.email).update({
      'availability': _availability,
    });
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disponibilités enregistrées')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickTime(String day, bool isStart) async {
    final initial = isStart
        ? _availability[day]!['start']
        : _availability[day]!['end'];
    final parsed = initial != null ? TimeOfDay(
      hour: int.parse(initial.split(':')[0]),
      minute: int.parse(initial.split(':')[1]),
    ) : const TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: parsed,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final formatted =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _availability[day]!['start'] = formatted;
        } else {
          _availability[day]!['end'] = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Disponibilités',
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Horaires de consultation',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Définissez vos horaires pour chaque jour de la semaine.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ..._availability.entries.map((entry) =>
                    _buildDayTile(entry.key, entry.value)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromRGBO(7, 82, 96, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Enregistrer',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayTile(String day, Map<String, String?> times) {
    final isAvailable = times['start'] != null && times['end'] != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color.fromRGBO(7, 82, 96, 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isAvailable ? Icons.check_circle : Icons.schedule,
                color: isAvailable
                    ? const Color.fromRGBO(7, 82, 96, 1)
                    : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                day,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: isAvailable
                  ? () => _pickTime(day, true)
                  : () => _pickTime(day, true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  times['start'] ?? '--:--',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: times['start'] != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('-',
                  style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            GestureDetector(
              onTap: isAvailable
                  ? () => _pickTime(day, false)
                  : () => _pickTime(day, false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  times['end'] ?? '--:--',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: times['end'] != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (isAvailable)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _availability[day] = {'start': null, 'end': null};
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
