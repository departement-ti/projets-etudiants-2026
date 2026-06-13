import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/autonomy_score_widget.dart';
import 'package:mymeds_app/screens/add_medication1.dart';
import 'package:mymeds_app/screens/daily_activities_screen.dart';
import 'package:mymeds_app/screens/incident_report.dart';
import 'package:mymeds_app/components/language_constants.dart';

class AssistantHome extends StatefulWidget {
  const AssistantHome({super.key});

  @override
  State<AssistantHome> createState() => _AssistantHomeState();
}

class _AssistantHomeState extends State<AssistantHome> {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _recentIncidents = [];
  Map<String, dynamic>? _dailyActivities;
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _recentReports = [];
  bool _isLoading = true;
  String? _selectedPatientEmail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les patients liés
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .get();
      final linked = (userDoc.data()?['linkedPatientsEmails'] as List<dynamic>?)?.cast<String>() ?? [];

      final patients = <Map<String, dynamic>>[];
      for (final email in linked) {
        if (email.isEmpty) continue;
        final patDoc = await FirebaseFirestore.instance.collection('Users').doc(email).get();
        if (patDoc.exists) {
          patients.add({'email': email, ...patDoc.data()!});
        }
      }

      // Charger les rappels/notifications (filtre côté client)
      final reminderSnap = await FirebaseFirestore.instance
          .collection('Reminders')
          .where('caregiverEmail', isEqualTo: user!.email)
          .get();
      final reminders = reminderSnap.docs
          .map((d) => d.data())
          .where((d) => d['read'] == false || d['read'] == null)
          .toList()
        ..sort((a, b) {
          final da = a['createdAt'] ?? '';
          final db = b['createdAt'] ?? '';
          return db.toString().compareTo(da.toString());
        });
      final recentReminders = reminders.take(5).toList();

      // Charger les incidents récents
      final incidentSnap = await FirebaseFirestore.instance
          .collection('Incidents')
          .orderBy('dateTime', descending: true)
          .limit(5)
          .get();
      final incidents = <Map<String, dynamic>>[];
      for (final d in incidentSnap.docs) {
        final data = d.data();
        final elderlyId = data['elderlyId'] as String? ?? data['elderlyEmail'] as String?;
        if (patients.any((p) => p['email'] == elderlyId)) {
          incidents.add(data);
        }
      }

      setState(() {
        _patients = patients;
        _reminders = reminders;
        _recentIncidents = incidents;
        _isLoading = false;
        if (_selectedPatientEmail == null && patients.isNotEmpty) {
          _selectedPatientEmail = patients.first['email'] as String?;
        }
      });
      // Charger les activités du jour
      if (_selectedPatientEmail != null) {
        _loadDailyActivities();
        _loadRecommendations(_selectedPatientEmail!);
        _loadReports(_selectedPatientEmail!);
      }
    } catch (e) {
      print('Error loading family dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDailyActivities() async {
    if (_selectedPatientEmail == null) return;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_selectedPatientEmail)
          .collection('DailyActivities')
          .doc(todayStr)
          .get();
      if (mounted) setState(() => _dailyActivities = doc.exists ? doc.data() : null);
    } catch (_) {}
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

  int _remindersCount() => _reminders.length;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
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
        title: Text(
          '${_getGreeting()}, ${user?.displayName ?? translation(context).assistantRole}',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Color.fromRGBO(7, 82, 96, 1)),
                if (_remindersCount() > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('${_remindersCount()}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showRemindersDialog(),
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
            // Sélecteur de patient
            if (_patients.length > 1) ...[
              _buildPatientSelector(),
              const SizedBox(height: 12),
            ],
            if (_patients.isEmpty) ...[
              _buildEmptyState(),
            ] else ...[
              // Infos patient
              if (patient != null) ...[
                _buildPatientCard(patient),
                const SizedBox(height: 16),
              ],

              // Score autonomie
              if (_selectedPatientEmail != null)
                AutonomyScoreWidget(userEmail: _selectedPatientEmail),

              const SizedBox(height: 16),

              // Résumé activités quotidiennes
              _buildDailyActivitiesSummary(),

              const SizedBox(height: 16),

              // Actions rapides
              _buildQuickActions(),

              const SizedBox(height: 16),

              // Recommandations du médecin
              if (_recommendations.isNotEmpty) ...[
                _buildSection(translation(context).recommendations, Icons.recommend, const Color(0xFF2E7D32)),
                ..._recommendations.take(3).map(_buildRecommendationCard),
                const SizedBox(height: 16),
              ],

              // Rapports médicaux
              if (_recentReports.isNotEmpty) ...[
                _buildSection('Rapports médicaux', Icons.assignment, Colors.purple),
                ..._recentReports.take(2).map(_buildReportCard),
                const SizedBox(height: 16),
              ],

              // Incidents récents
              if (_recentIncidents.isNotEmpty) ...[
                _buildSection(translation(context).recentIncidents, Icons.warning_amber, Colors.orange),
                ..._recentIncidents.take(3).map(_buildIncidentCard),
                const SizedBox(height: 16),
              ],

              // Rappels
              if (_reminders.isNotEmpty) ...[
                _buildSection(translation(context).notifications, Icons.notifications_active, Colors.blue),
                ..._reminders.take(3).map(_buildReminderCard),
                const SizedBox(height: 32),
              ],
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
                _loadDailyActivities();
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
            const Icon(Icons.family_restroom, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(translation(context).noPatientsLinked, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(translation(context).goToPatientsToLink, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['name'] ?? 'Patient';
    final address = patient['address'] ?? 'Adresse non renseignée';
    final mobile = patient['mobile'] ?? 'Tél non renseigné';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color.fromRGBO(7, 82, 96, 1).withAlpha(30),
              child: Text('👴', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('📱 $mobile', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivitiesSummary() {
    final activities = _dailyActivities;
    if (activities == null || _selectedPatientEmail == null) return const SizedBox();

    final water = activities['waterGlasses'] ?? 0;
    final meals = activities['mealsTaken'] ?? 0;
    final exercises = activities['exercisesDone'] ?? 0;
    final walks = activities['walksTaken'] ?? 0;
    final morning = activities['morningRoutine'] ?? false;
    final evening = activities['eveningRoutine'] ?? false;
    final social = activities['socialInteraction'] ?? false;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(translation(context).todaysActivities, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DailyActivitiesScreen(targetEmail: _selectedPatientEmail),
                    ));
                  },
                  child: Text(translation(context).detailsArrow, style: GoogleFonts.poppins(fontSize: 12, color: const Color.fromRGBO(7, 82, 96, 1))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12, runSpacing: 8,
              children: [
                _buildActivityChip('💧', '$water/8', water >= 8),
                _buildActivityChip('🍽️', '$meals/3', meals >= 3),
                _buildActivityChip('🏋️', '${exercises}x', exercises > 0),
                _buildActivityChip('🚶', '${walks}x', walks > 0),
                _buildActivityChip('🌅', '', morning),
                _buildActivityChip('🌙', '', evening),
                _buildActivityChip('👥', '', social),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChip(String emoji, String label, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done ? Colors.green.withAlpha(30) : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: done ? Colors.green : Colors.grey[300]!, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: done ? Colors.green[700] : Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(Icons.medical_services, translation(context).addMedicationShort, const Color(0xFF2196F3), () {
            if (_selectedPatientEmail != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddMedication1(targetUserEmail: _selectedPatientEmail),
              ));
            }
          }),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionCard(Icons.warning_amber, translation(context).reportIncidentShort, const Color(0xFFFF9800), () {
            if (_selectedPatient != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => IncidentReportScreen(
                  elderlyId: _selectedPatientEmail ?? '',
                  elderlyName: _selectedPatient?['name'],
                ),
              ));
            }
          }),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionCard(Icons.checklist, translation(context).dailyActivitiesShort, const Color(0xFF4CAF50), () {
            if (_selectedPatientEmail != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => DailyActivitiesScreen(targetEmail: _selectedPatientEmail),
              ));
            }
          }),
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
            Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
    final description = incident['description'] ?? '';
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
                  if (description.isNotEmpty)
                    Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_formatDate(date), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final message = reminder['message'] ?? reminder['body'] ?? '';
    final type = reminder['type'] ?? 'info';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(type == 'missed_medication' ? Icons.medication : Icons.notifications, size: 24, color: Colors.red[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
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

  void _showRemindersDialog() {
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
            if (_reminders.isEmpty)
              Text(translation(context).noNotifications),
            ..._reminders.map(_buildReminderCard),
          ],
        ),
      ),
    );
  }
}
