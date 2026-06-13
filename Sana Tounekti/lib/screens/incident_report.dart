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

  String _incidentTypeLabel(BuildContext context, String type) {
    switch (type) {
      case 'Chute': return translation(context).fall;
      case 'Oubli de médicament': return translation(context).medicationMiss;
      case 'Comportement anormal': return translation(context).abnormalBehavior;
      case 'Douleur / Malaise': return translation(context).painDiscomfort;
      case 'Problème de mobilité': return translation(context).mobilityIssue;
      case 'Trouble du sommeil': return translation(context).sleepDisorder;
      case 'Refus de soins': return translation(context).careRefusal;
      case 'Autre': return translation(context).otherIncident;
      default: return type;
    }
  }

  Future<void> _submitIncident() async {
    if (_selectedType == null || _description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translation(context).fillAllFields)),
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
          SnackBar(
            content: Text(translation(context).incidentReportedSuccess),
            backgroundColor: const Color(0xFF5B5EA6),
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
        title: Text(translation(context).reportIncident),
        backgroundColor: const Color(0xFF5B5EA6),
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
                  leading: const Icon(Icons.person, color: const Color(0xFF5B5EA6)),
                  title: Text(widget.elderlyName!),
                  subtitle: Text(translation(context).personConcerned),
                ),
              ),
            const SizedBox(height: 16),
            Text(translation(context).incidentType,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: translation(context).selectType,
              ),
              items: Incident.incidentTypes.map((t) {
                return DropdownMenuItem(
                  value: t['label'] as String,
                  child: Text(_incidentTypeLabel(context, t['label'] as String)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val),
            ),
            const SizedBox(height: 16),
            Text(translation(context).severity,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (i) {
                final level = i + 1;
                final labels = [translation(context).mild, translation(context).moderate, translation(context).severe, translation(context).critical];
                final colors = [
                  Color(0xFF5B5EA6),
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
            Text(translation(context).description,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: translation(context).description,
              ),
              onChanged: (val) => _description = val,
            ),
            const SizedBox(height: 16),
            Text(translation(context).dateTime,
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
                  backgroundColor: const Color(0xFF5B5EA6),
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white))
                    : Text(translation(context).reportIncidentBtn,
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
