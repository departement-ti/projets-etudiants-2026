import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';

class PatientPrescriptionsScreen extends StatefulWidget {
  const PatientPrescriptionsScreen({super.key});

  @override
  State<PatientPrescriptionsScreen> createState() =>
      _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState
    extends State<PatientPrescriptionsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('Prescriptions')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _prescriptions = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading prescriptions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.myPrescriptions,
          style: GoogleFonts.poppins(
            color: const Color.fromRGBO(7, 82, 96, 1),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 242, 253, 255),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color.fromRGBO(7, 82, 96, 1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPrescriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      final data = prescription.data() as Map<String, dynamic>;
                      return _buildPrescriptionCard(data);
                    },
                  ),
                ),
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
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> data) {
    final t = translation(context);
    final medications = data['medications'] as List? ?? [];
    final status = data['status'] ?? 'active';
    final createdAt = data['createdAt'] ?? '';

    DateTime? dateTime;
    if (createdAt.isNotEmpty) {
      try {
        dateTime = DateTime.parse(createdAt);
      } catch (e) {
        dateTime = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPrescriptionDetails(data),
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
                          data['title'] ?? t.prescriptionDetails,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (dateTime != null)
                          Text(
                            '${t.createdOn} ${dateTime.day}/${dateTime.month}/${dateTime.year}',
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
                      color: status == 'active'
                          ? Colors.green[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'active' ? t.active : t.completed,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: status == 'active'
                            ? Colors.green[800]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '${medications.length} ${t.medicationsCount}',
                style: GoogleFonts.roboto(
                  color: Colors.grey[600],
                ),
              ),
              if (data['instructions'] != null &&
                  data['instructions'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data['instructions'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionDetails(Map<String, dynamic> data) {
    final t = translation(context);
    final medications = data['medications'] as List? ?? [];
    final createdAt = data['createdAt'] ?? '';

    DateTime? dateTime;
    if (createdAt.isNotEmpty) {
      try {
        dateTime = DateTime.parse(createdAt);
      } catch (e) {
        dateTime = null;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(7, 82, 96, 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.description,
                    size: 48,
                    color: Color.fromRGBO(7, 82, 96, 1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  data['title'] ?? t.prescriptionDetails,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (dateTime != null)
                Center(
                  child: Text(
                    '${t.createdOn} ${dateTime.day}/${dateTime.month}/${dateTime.year}',
                    style: GoogleFonts.roboto(color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                t.medications,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...(medications.map((med) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(7, 82, 96, 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Color.fromRGBO(7, 82, 96, 1),
                        ),
                      ),
                      title: Text(med['name'] ?? ''),
                      subtitle: Text('${t.dosage}: ${med['dosage']}'),
                    ),
                  ))),
              if (data['duration'] != null &&
                  data['duration'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  t.duration,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['duration'].toString(),
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
              ],
              if (data['instructions'] != null &&
                  data['instructions'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  t.instructions,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[800]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['instructions'].toString(),
                          style: GoogleFonts.roboto(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
