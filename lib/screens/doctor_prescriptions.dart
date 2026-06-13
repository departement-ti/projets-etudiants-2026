import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/create_prescription_screen.dart';
import 'package:mymeds_app/screens/create_report_screen.dart';

class DoctorPrescriptions extends StatefulWidget {
  const DoctorPrescriptions({super.key});

  @override
  State<DoctorPrescriptions> createState() => _DoctorPrescriptionsState();
}

class _DoctorPrescriptionsState extends State<DoctorPrescriptions> {
  final user = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> _prescriptions = [];
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPrescriptions(),
      _loadPatients(),
    ]);
  }

  Future<void> _loadPrescriptions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Prescriptions')
          .where('doctorEmail', isEqualTo: user!.email)
          .limit(50)
          .get();

      final prescriptions = snapshot.docs.toList();
      prescriptions.sort((a, b) {
        final aDate = a.data()['createdAt'] ?? '';
        final bDate = b.data()['createdAt'] ?? '';
        return bDate.toString().compareTo(aDate.toString());
      });

      setState(() {
        _prescriptions = prescriptions;
      });
    } catch (e) {
      print('Error loading prescriptions: $e');
    }
  }

  Future<void> _loadPatients() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .get();

      final data = userDoc.data() as Map<String, dynamic>?;
      final linkedEmails =
          List<String>.from(data?['linkedPatientsEmails'] ?? []);

      List<Map<String, dynamic>> patients = [];

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

      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPatientSelectionDialog() {
    final t = translation(context);
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.noPatientLinked)),
      );
      return;
    }

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
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.selectPatientForPrescription,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.choosePatientForPrescription,
                    style: GoogleFonts.roboto(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  final patient = _patients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color.fromRGBO(7, 82, 96, 0.1),
                      child: Text(
                        (patient['name']?.isNotEmpty == true
                                ? patient['name']![0]
                                : 'P')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color.fromRGBO(7, 82, 96, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(patient['name'] ?? t.patient),
                    subtitle: Text(patient['email']),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePrescriptionScreen(
                            patientEmail: patient['email'],
                            patientName: patient['name'] ?? t.patient,
                            doctorEmail: user!.email!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportPatientSelectionDialog() {
    final t = translation(context);
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.noPatientLinked)),
      );
      return;
    }

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
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.selectPatientForReport,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.choosePatientForReport,
                    style: GoogleFonts.roboto(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _patients.length,
                itemBuilder: (context, index) {
                  final patient = _patients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade50,
                      child: Icon(
                        Icons.person,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    title: Text(patient['name'] ?? t.patient),
                    subtitle: Text(patient['email']),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateReportScreen(
                            patientEmail: patient['email'],
                            patientName: patient['name'] ?? t.patient,
                            doctorEmail: user!.email!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
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
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(7, 82, 96, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                onSelected: (value) {
                  if (value == 'prescription') {
                    _showPatientSelectionDialog();
                  } else if (value == 'report') {
                    _showReportPatientSelectionDialog();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'prescription',
                    child: Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(t.newPrescription),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(t.newReport),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _prescriptions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPrescriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      final data = prescription.data() as Map<String, dynamic>;
                      return _buildPrescriptionCard(data);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final t = translation(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            t.noPrescriptions,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.prescriptionsAppear,
            style: GoogleFonts.roboto(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showPatientSelectionDialog,
            icon: const Icon(Icons.add),
            label: Text(t.newPrescription),
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

  Widget _buildPrescriptionCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'active';
    final Color statusColor;
    final String statusText;

    switch (status) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'Active';
        break;
      case 'expired':
        statusColor = Colors.red;
        statusText = 'Expirée';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Terminée';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(7, 82, 96, 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Color.fromRGBO(7, 82, 96, 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['patientName'] ?? 'Patient',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Créée le ${data['date'] ?? ''}',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medication, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${data['medications']?.length ?? 0} médicament(s)',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
