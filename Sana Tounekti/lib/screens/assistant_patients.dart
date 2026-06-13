import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/doctor_info_card.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/add_medication1.dart';
import 'package:mymeds_app/screens/incident_report.dart';

class AssistantPatients extends StatefulWidget {
  const AssistantPatients({super.key});

  @override
  State<AssistantPatients> createState() => _AssistantPatientsState();
}

class _AssistantPatientsState extends State<AssistantPatients> {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .get();

      final data = userDoc.data() as Map<String, dynamic>?;
      final linkedEmails =
          List<String>.from(data?['linkedPatientsEmails'] ?? []);
      final pendingEmails =
          List<String>.from(data?['pendingPatientRequests'] ?? []);

      List<Map<String, dynamic>> patients = [];
      List<Map<String, dynamic>> pending = [];

      for (final email in linkedEmails) {
        final patientDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(email)
            .get();
        if (patientDoc.exists) {
          patients.add({
            'email': email,
            ...patientDoc.data()!,
          });
        }
      }

      for (final email in pendingEmails) {
        pending.add({'email': email});
      }

      setState(() {
        _patients = patients;
        _pendingRequests = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddPatientDialog() {
    final t = translation(context);
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          t.addPatient,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez l\'email du patient. Une demande sera envoyée et le patient devra l\'accepter.',
              style: GoogleFonts.roboto(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: t.patient,
                hintText: 'patient@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (emailController.text.trim().isNotEmpty) {
                final targetEmail = emailController.text.trim();

                final targetDoc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(targetEmail)
                    .get();

                if (!targetDoc.exists) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.requestFailed)),
                  );
                  return;
                }

                final targetData = targetDoc.data() as Map<String, dynamic>;
                if (targetData['role'] != 'personneAge') {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.requestFailed)),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(targetEmail)
                    .update({
                  'pendingPatientRequests':
                      FieldValue.arrayUnion([user!.email]),
                });

                Navigator.pop(context);
                _loadPatients();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${t.requestSent} $targetEmail')),
                );
              }
            },
            child: Text(t.sendRequest),
          ),
        ],
      ),
    );
  }

  void _showLinkPatientToDoctorDialog(String patientEmail) {
    final t = translation(context);
    final emailController = TextEditingController();
    Map<String, dynamic>? foundDoctor;
    bool showDetails = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            t.linkToDoctor,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez l\'email du médecin pour ce patient.',
                style: GoogleFonts.roboto(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'medecin@email.com',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (value) async {
                  if (value.trim().isEmpty) return;
                  final doc = await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(value.trim())
                      .get();
                  if (!doc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.requestFailed)),
                    );
                    return;
                  }
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['role'] != 'doctor') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.requestFailed)),
                    );
                    return;
                  }
                  setDialogState(() {
                    foundDoctor = {'email': value.trim(), ...data};
                    showDetails = true;
                  });
                },
              ),
              if (showDetails && foundDoctor != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  const Color.fromRGBO(7, 82, 96, 0.1),
                              child: Text(
                                (foundDoctor!['name'] ?? 'D')[0]
                                    .toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      const Color.fromRGBO(7, 82, 96, 1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. ${foundDoctor!['name'] ?? ''}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    foundDoctor!['email'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        DoctorInfoCard(doctorData: foundDoctor!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel),
            ),
            if (showDetails && foundDoctor != null)
              FilledButton(
                onPressed: () async {
                  final doctorEmail = foundDoctor!['email'] as String;
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(doctorEmail)
                      .update({
                    'pendingDoctorRequests':
                        FieldValue.arrayUnion([patientEmail]),
                    'patientFromFamille':
                        FieldValue.arrayUnion([patientEmail]),
                  });
                  Navigator.pop(context);
                  _loadPatients();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${t.requestSent} $doctorEmail')),
                  );
                },
                child: Text(t.sendRequest),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_pendingRequests.isNotEmpty) _buildPendingRequestsSection(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: t.searchPatient,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _patients.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPatients,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredPatients().length,
                    itemBuilder: (context, index) {
                      final patient = _filteredPatients()[index];
                      return _buildPatientCard(patient['email'], patient);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestsSection() {
    final t = translation(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '${t.pendingRequests} (${_pendingRequests.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_pendingRequests.map((request) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(request['email']),
                subtitle: Text(t.clickToAccept),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _acceptRequest(request['email']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectRequest(request['email']),
                    ),
                  ],
                ),
                onTap: () => _acceptRequest(request['email']),
              ))),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(String patientEmail) async {
    final t = translation(context);
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .update({
        'linkedPatientsEmails': FieldValue.arrayUnion([patientEmail]),
        'pendingPatientRequests': FieldValue.arrayRemove([patientEmail]),
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(patientEmail)
          .update({
        'linkedFamilyEmails': FieldValue.arrayUnion([user!.email]),
        'pendingInvitations': FieldValue.arrayRemove([user!.email]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.linked)),
      );

      await _loadPatients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorOccurred}: $e')),
      );
    }
  }

  Future<void> _rejectRequest(String patientEmail) async {
    final t = translation(context);
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .update({
        'pendingPatientRequests': FieldValue.arrayRemove([patientEmail]),
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(patientEmail)
          .update({
        'pendingInvitations': FieldValue.arrayRemove([user!.email]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.pending)),
      );

      await _loadPatients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorOccurred}: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filteredPatients() {
    if (_searchQuery.isEmpty) return _patients;
    return _patients.where((doc) {
      final name = (doc['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  Widget _buildEmptyState() {
    final t = translation(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            t.noLinkedPatients,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.linkPatient,
            style: GoogleFonts.roboto(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPatientDialog,
            icon: const Icon(Icons.add),
            label: Text(t.linkPatient),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(String patientId, Map<String, dynamic> data) {
    final t = translation(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPatientDetails(patientId, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color.fromRGBO(7, 82, 96, 0.1),
                    child: Text(
                      (data['name'] ?? 'P')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(7, 82, 96, 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? t.patient,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.medication,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '0 ${t.medications.toLowerCase()}',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.active,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLinkPatientToDoctorDialog(patientId),
                  icon: const Icon(Icons.medical_services, size: 18),
                  label: Text(t.linkToDoctor),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color.fromRGBO(7, 82, 96, 1),
                    side: const BorderSide(color: Color.fromRGBO(7, 82, 96, 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientDetails(String patientId, Map<String, dynamic> data) {
    final t = translation(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 0.1),
                  child: Text(
                    (data['name'] ?? 'P')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(7, 82, 96, 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  data['name'] ?? t.patient,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailRow(Icons.email, 'Email', patientId),
              _buildDetailRow(
                  Icons.phone, t.phone, data['mobile'] ?? t.notProvided),
              _buildDetailRow(Icons.location_on, t.address,
                  data['address'] ?? t.notProvided),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMedication1(
                          targetUserEmail: data['email'] as String?,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle),
                  label: Text('Ajouter un médicament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncidentReportScreen(
                          elderlyId: patientId,
                          elderlyName: data['name'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.report_problem, size: 18),
                  label: const Text('Signaler un incident'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromRGBO(7, 82, 96, 1)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
