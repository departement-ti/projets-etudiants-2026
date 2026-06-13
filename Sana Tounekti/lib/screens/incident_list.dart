import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/models/incident.dart';

class IncidentListScreen extends StatefulWidget {
  final String? elderlyId;

  const IncidentListScreen({super.key, this.elderlyId});

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
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

  String _severityLabel(BuildContext context, int severity) {
    switch (severity) {
      case 1: return translation(context).severityMild;
      case 2: return translation(context).severityModerate;
      case 3: return translation(context).severitySevere;
      case 4: return translation(context).severityCritical;
      default: return translation(context).severityUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('Incidents')
        .orderBy('dateTime', descending: true);

    if (widget.elderlyId != null) {
      query = query.where('elderlyId', isEqualTo: widget.elderlyId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).incidentHistory),
        backgroundColor: const Color(0xFF5B5EA6),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(translation(context).noIncidents),
            );
          }

          final incidents = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident =
                  Incident.fromMap(incidents[index].data() as Map<String, dynamic>,
                      incidents[index].id);
              return _buildIncidentCard(incident);
            },
          );
        },
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    final severityColors = {
      1: Color(0xFF5B5EA6),
      2: Colors.orange,
      3: Colors.deepOrange,
      4: Colors.red,
    };

    final typeIcons = {
      'Chute': Icons.sailing,
      'Oubli de médicament': Icons.medication,
      'Comportement anormal': Icons.psychology,
      'Douleur / Malaise': Icons.sick,
      'Problème de mobilité': Icons.accessible,
      'Trouble du sommeil': Icons.bedtime,
      'Refus de soins': Icons.not_interested,
      'Autre': Icons.report,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (severityColors[incident.severity] ?? Colors.grey)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _severityLabel(context, incident.severity),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: severityColors[incident.severity] ?? Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  typeIcons[incident.type] ?? Icons.report,
                  size: 20,
                  color: const Color(0xFF5B5EA6),
                ),
                const SizedBox(width: 8),
                Text(
                  _incidentTypeLabel(context, incident.type),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              incident.description,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${incident.dateTime.day}/${incident.dateTime.month}/${incident.dateTime.year}  '
                  '${incident.dateTime.hour.toString().padLeft(2, '0')}:${incident.dateTime.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[500]),
                ),
                if (incident.reportedByName != null) ...[
                  const Spacer(),
                  Icon(Icons.person, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    translation(context).reportedBy(incident.reportedByName ?? ''),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
