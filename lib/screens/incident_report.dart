import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/models/incident.dart';
import 'package:mymeds_app/services/autonomy_score_service.dart';

class IncidentReportScreen extends StatefulWidget {
  final String elderlyId;
  final String? elderlyName;

  const IncidentReportScreen({
    super.key,
    required this.elderlyId,
    this.elderlyName,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String? _selectedType;
  String _description = '';
  int _severity = 1;
  DateTime _dateTime = DateTime.now();
  bool _isSubmitting = false;

  Future<void> _submitIncident() async {
    if (_selectedType == null || _description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.email ?? widget.elderlyId)
          .get();

      final reportName = userDoc.exists
          ? (userDoc.data()?['name'] ?? 'Utilisateur')
          : 'Utilisateur';

      final incident = Incident(
        reportedById: user?.email ?? 'unknown',
        reportedByName: reportName,
        elderlyId: widget.elderlyId,
        elderlyName: widget.elderlyName,
        type: _selectedType!,
        description: _description.trim(),
        dateTime: _dateTime,
        severity: _severity,
      );

      await FirebaseFirestore.instance
          .collection('Incidents')
          .add(incident.toMap());

      await AutonomyScoreService().calculateScore(widget.elderlyId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident signalé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signaler un incident'),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.elderlyName != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Color.fromRGBO(7, 82, 96, 1)),
                  title: Text(widget.elderlyName!),
                  subtitle: const Text('Personne concernée'),
                ),
              ),
            const SizedBox(height: 16),
            Text('Type d\'incident',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Sélectionner le type',
              ),
              items: Incident.incidentTypes.map((t) {
                return DropdownMenuItem(
                  value: t['label'] as String,
                  child: Text(t['label'] as String),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val),
            ),
            const SizedBox(height: 16),
            Text('Gravité',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (i) {
                final level = i + 1;
                final labels = ['Léger', 'Modéré', 'Grave', 'Critique'];
                final colors = [
                  Colors.green,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.red
                ];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(labels[i]),
                      selected: _severity == level,
                      selectedColor: colors[i].withOpacity(0.3),
                      onSelected: (_) => setState(() => _severity = level),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text('Description',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Décrivez l\'incident en détail...',
              ),
              onChanged: (val) => _description = val,
            ),
            const SizedBox(height: 16),
            Text('Date et heure',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.grey.shade100,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_dateTime.day}/${_dateTime.month}/${_dateTime.year}  '
                '${_dateTime.hour.toString().padLeft(2, '0')}:${_dateTime.minute.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_dateTime),
                );
                if (time == null) return;
                setState(() {
                  _dateTime = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute);
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Signaler l\'incident',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
