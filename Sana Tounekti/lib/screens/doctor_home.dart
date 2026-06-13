import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/autonomy_score_widget.dart';
import 'package:mymeds_app/screens/create_prescription_screen.dart';
import 'package:mymeds_app/screens/doctor_reports_screen.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/talkback_screen_mixin.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> with TalkbackScreenMixin {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _recentIncidents = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _recentReports = [];
  bool _isLoading = true;
  String? _selectedPatientEmail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    speakOnLoad(translation(context).doctorHome);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .get();
      final linked = (userDoc.data()?['linkedPatientsEmails'] as List<dynamic>?)?.cast<String>() ?? [];

      final patients = <Map<String, dynamic>>[];
      for (final email in linked) {
        if (email.isEmpty) continue;
        final patDoc = await FirebaseFirestore.instance.collection('Users').doc(email).get();
        if (patDoc.exists) patients.add({'email': email, ...patDoc.data()!});
      }

      final incidentSnap = await FirebaseFirestore.instance
          .collection('Incidents')
          .orderBy('dateTime', descending: true)
          .limit(10)
          .get();
      print('Doctor home: found ${incidentSnap.docs.length} incidents total');
      final incidents = <Map<String, dynamic>>[];
      for (final d in incidentSnap.docs) {
        final data = d.data();
        final elderlyId = data['elderlyId'] as String? ?? data['elderlyEmail'] as String?;
        print('Incident: ${data['type']} for $elderlyId');
        // Afficher les incidents pour les patients liés
        final isLinked = patients.any((p) => p['email'] == elderlyId);
        if (isLinked || patients.isEmpty) {
          incidents.add({...data, 'id': d.id});
        }
      }
      print('Doctor home: filtered ${incidents.length} incidents for linked patients');

      final notifSnap = await FirebaseFirestore.instance
          .collection('Notifications')
          .where('targetEmail', isEqualTo: user!.email)
          .get();
      final notifications = notifSnap.docs
          .map((d) => d.data())
          .where((n) => n['read'] == false || n['read'] == null)
          .toList()
        ..sort((a, b) {
          final da = a['sentAt'] ?? '';
          final db = b['sentAt'] ?? '';
          return db.toString().compareTo(da.toString());
        });

      setState(() {
        _patients = patients;
        _recentIncidents = incidents;
        _notifications = notifications;
        _isLoading = false;
        if (_selectedPatientEmail == null && patients.isNotEmpty) {
          _selectedPatientEmail = patients.first['email'] as String?;
        }
        if (_selectedPatientEmail != null) {
          _loadRecommendations(_selectedPatientEmail!);
          _loadReports(_selectedPatientEmail!);
        }
      });
    } catch (e) {
      print('Doctor home error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecommendations(String patientEmail) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Recommendations')
          .where('patientEmail', isEqualTo: patientEmail)
          .orderBy('date', descending: true)
          .get();
      
      final recs = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        String doctorName = data['doctorName'] as String? ?? '';
        if (doctorName.isEmpty) {
          final docUser = await FirebaseFirestore.instance
              .collection('Users').doc(data['doctorEmail'] as String?).get();
          doctorName = docUser.data()?['name'] as String? ?? data['doctorEmail'] as String? ?? '';
        }
        recs.add({...data, 'id': d.id, 'doctorName': doctorName});
      }
      if (mounted) setState(() => _recommendations = recs);
    } catch (e) {
      print('Error loading recommendations: $e');
    }
  }

  Future<void> _loadReports(String patientEmail) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(patientEmail)
          .collection('DoctorReports')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      final reports = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {'id': d.id, ...data};
      }).toList();
      if (mounted) setState(() => _recentReports = reports);
    } catch (e) {
      print('Error loading reports: $e');
    }
  }

  Map<String, dynamic>? get _selectedPatient {
    if (_selectedPatientEmail == null) return null;
    try {
      return _patients.firstWhere((p) => p['email'] == _selectedPatientEmail);
    } catch (_) {
      return _patients.isNotEmpty ? _patients.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color.fromRGBO(7, 82, 96, 1)));
    }

    final patient = _selectedPatient;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Dr. ${user?.displayName ?? translation(context).doctorRole}',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Color.fromRGBO(7, 82, 96, 1)),
                if (_notifications.length > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('${_notifications.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color.fromRGBO(7, 82, 96, 1)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color.fromRGBO(7, 82, 96, 1),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_patients.length > 1) ...[
              _buildPatientSelector(),
              const SizedBox(height: 12),
            ],
            if (_patients.isEmpty) ...[
              _buildEmptyState(),
            ] else ...[
              if (patient != null) ...[
                _buildPatientHeaderCard(patient),
                const SizedBox(height: 16),
              ],
              if (_selectedPatientEmail != null)
                AutonomyScoreWidget(userEmail: _selectedPatientEmail),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 16),
              if (_recommendations.isNotEmpty) ...[
                _buildSection(translation(context).recommendations, Icons.recommend, const Color(0xFF2E7D32)),
                ..._recommendations.take(3).map(_buildRecommendationCard),
                const SizedBox(height: 16),
              ],
              if (_recentReports.isNotEmpty) ...[
                _buildSection('Rapports médicaux', Icons.assignment, Colors.purple),
                ..._recentReports.take(2).map(_buildReportCard),
                const SizedBox(height: 16),
              ],
              if (_recentIncidents.isNotEmpty) ...[
                _buildSection(translation(context).recentIncidents, Icons.warning_amber, Colors.orange),
                ..._recentIncidents.take(3).map(_buildIncidentCard),
              ],
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final p = _patients[index];
          final isSelected = p['email'] == _selectedPatientEmail;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p['name'] ?? 'Patient ${index + 1}'),
              selected: isSelected,
              selectedColor: const Color.fromRGBO(7, 82, 96, 1),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
              onSelected: (_) {
                setState(() => _selectedPatientEmail = p['email'] as String?);
                _loadRecommendations(p['email'] as String);
                _loadReports(p['email'] as String);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.medical_services, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(translation(context).noPatientsLinked, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(translation(context).goToPatientsSection, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard(Map<String, dynamic> patient) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color.fromRGBO(7, 82, 96, 1).withAlpha(30),
              child: Text('👴', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient['name'] ?? 'Patient', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
                  Text('${patient['age'] ?? 'N/A'} ans • ${patient['address'] ?? ''}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('📱 ${patient['mobile'] ?? ''}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(Icons.description, translation(context).createPrescriptionShort, const Color(0xFF1565C0), () {
                if (_selectedPatient != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CreatePrescriptionScreen(
                      patientEmail: _selectedPatientEmail!,
                      patientName: _selectedPatient!['name'] ?? '',
                      doctorEmail: user!.email!,
                    ),
                  ));
                }
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(Icons.recommend, translation(context).addRecommendationShort, const Color(0xFF2E7D32), () {
                _showRecommendationDialog();
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(Icons.assignment, 'Voir rapports', Colors.purple, () {
                if (_selectedPatientEmail != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DoctorReportsScreen(
                      patientEmail: _selectedPatientEmail!,
                      patientName: _selectedPatient?['name'] ?? 'Patient',
                    ),
                  ));
                }
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('📊', translation(context).patients, '${_patients.length}', const Color(0xFF1565C0))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('⚠️', translation(context).incidentHistory, '${_recentIncidents.length}', const Color(0xFFFF9800))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('🔔', translation(context).notifications, '${_notifications.length}', const Color(0xFFD32F2F))),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final content = rec['content'] ?? '';
    final doctorName = rec['doctorName'] ?? rec['doctorEmail'] ?? '';
    final date = rec['date'] ?? '';
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.recommend, size: 18, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(doctorName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32))),
                ),
                Text(date.toString().substring(0, 10), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Text(content, style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final title = report['title'] ?? 'Rapport médical';
    final doctorName = report['doctorName'] ?? '';
    final date = report['createdAt'] ?? '';
    final dateStr = date.toString().length >= 10 ? date.toString().substring(0, 10) : date.toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment, size: 20, color: Colors.purple.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (doctorName.isNotEmpty)
                    Text('Dr. $doctorName', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  Text(dateStr, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final type = incident['type'] ?? 'Incident';
    final severity = incident['severity'] ?? 1;
    final date = incident['dateTime'] ?? incident['date'] ?? '';
    final colors = [Colors.green, Colors.orange, Colors.red, const Color(0xFFB71C1C)];
    final color = colors[(severity as int).clamp(1, 4) - 1];

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(_formatDate(date), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(translation(context).notifications, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (_notifications.isEmpty) Text(translation(context).noNotifications),
            ..._notifications.take(5).map((n) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n['title'] ?? '', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (n['body'] != null) Text(n['body']!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showRecommendationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(translation(context).addRecommendation),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: translation(context).recommendationHint,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(translation(context).cancelBtn)),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty && _selectedPatientEmail != null) {
                await FirebaseFirestore.instance.collection('Recommendations').add({
                  'doctorEmail': user!.email,
                  'doctorName': user?.displayName ?? '',
                  'patientEmail': _selectedPatientEmail,
                  'content': controller.text.trim(),
                  'date': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).recommendationSent)));
              }
            },
            child: Text(translation(context).sendBtn),
          ),
        ],
      ),
    );
  }
}
