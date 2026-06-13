import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';

class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('DoctorReports')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _reports = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.medicalReports,
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
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      final data = report.data() as Map<String, dynamic>;
                      return _buildReportCard(data);
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
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            t.noReports,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.reportsAppear,
            style: GoogleFonts.roboto(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
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
        onTap: () => _showReportDetails(data),
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
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Rapport médical',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (data['doctorName'] != null)
                          Text(
                            'Dr. ${data['doctorName']}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (dateTime != null)
                          Text(
                            '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (data['summary'] != null &&
                  data['summary'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  data['summary'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> data) {
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
        initialChildSize: 0.8,
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
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.assignment,
                    size: 48,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  data['title'] ?? 'Rapport médical',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    if (data['doctorName'] != null)
                      Text(
                        'Dr. ${data['doctorName']}',
                        style: GoogleFonts.roboto(
                          color: const Color.fromRGBO(7, 82, 96, 1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (dateTime != null)
                      Text(
                        'Le ${dateTime.day}/${dateTime.month}/${dateTime.year}',
                        style: GoogleFonts.roboto(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              if (data['content'] != null &&
                  data['content'].toString().isNotEmpty) ...[
                Text(
                  'Contenu du rapport',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    data['content'].toString(),
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              if (data['notes'] != null &&
                  data['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Notes du médecin',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, color: Colors.amber[800]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['notes'].toString(),
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
