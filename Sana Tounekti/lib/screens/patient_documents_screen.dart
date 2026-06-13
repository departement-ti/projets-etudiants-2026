import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/talkback_screen_mixin.dart';

class PatientDocumentsScreen extends StatefulWidget {
  const PatientDocumentsScreen({super.key});

  @override
  State<PatientDocumentsScreen> createState() => _PatientDocumentsScreenState();
}

class _PatientDocumentsScreenState extends State<PatientDocumentsScreen>
    with SingleTickerProviderStateMixin, TalkbackScreenMixin {
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    speakOnLoad(translation(context).myDocuments);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.myDocuments,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF5B5EA6),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Text(
                t.prescriptions,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            Tab(
              child: Text(
                t.medicalReports,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PrescriptionsTab(userEmail: user?.email),
          _ReportsTab(userEmail: user?.email),
        ],
      ),
    );
  }
}

class _PrescriptionsTab extends StatefulWidget {
  final String? userEmail;
  const _PrescriptionsTab({this.userEmail});

  @override
  State<_PrescriptionsTab> createState() => _PrescriptionsTabState();
}

class _PrescriptionsTabState extends State<_PrescriptionsTab> {
  List<DocumentSnapshot> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    if (widget.userEmail == null) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userEmail)
          .collection('Prescriptions')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _prescriptions = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(t.noPrescriptions, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(t.prescriptionsAppear, style: GoogleFonts.roboto(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) {
          final data = _prescriptions[index].data() as Map<String, dynamic>;
          return _PrescriptionCard(data: data);
        },
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PrescriptionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    final medications = data['medications'] as List? ?? [];
    final status = data['status'] ?? 'active';
    final createdAt = data['createdAt'] ?? '';
    DateTime? dateTime;
    if (createdAt.isNotEmpty) {
      try { dateTime = DateTime.parse(createdAt); } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetails(context, data),
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
                      color: const Color(0xFF5B5EA6).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description, color: Color(0xFF5B5EA6)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? t.prescriptionDetails,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        if (dateTime != null)
                          Text('${t.createdOn} ${dateTime.day}/${dateTime.month}/${dateTime.year}',
                              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'active' ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'active' ? t.active : t.completed,
                      style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500,
                          color: status == 'active' ? Colors.green[800] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text('${medications.length} ${t.medicationsCount}',
                  style: GoogleFonts.roboto(color: Colors.grey[600])),
              if (data['instructions'] != null && data['instructions'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(data['instructions'].toString(), maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey[600])),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    final t = translation(context);
    final medications = data['medications'] as List? ?? [];
    final createdAt = data['createdAt'] ?? '';
    DateTime? dateTime;
    if (createdAt.isNotEmpty) {
      try { dateTime = DateTime.parse(createdAt); } catch (_) {}
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5EA6).withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.description, size: 48, color: Color(0xFF5B5EA6)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(data['title'] ?? t.prescriptionDetails,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              if (dateTime != null)
                Center(
                  child: Text('${t.createdOn} ${dateTime.day}/${dateTime.month}/${dateTime.year}',
                      style: GoogleFonts.roboto(color: Colors.grey[600])),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(t.medications,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...medications.map((med) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B5EA6).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication, color: Color(0xFF5B5EA6)),
                      ),
                      title: Text(med['name'] ?? ''),
                      subtitle: Text('${t.dosage}: ${med['dosage']}'),
                    ),
                  )),
              if (data['duration'] != null && data['duration'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(t.duration, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(data['duration'].toString(), style: GoogleFonts.roboto(fontSize: 16)),
              ],
              if (data['instructions'] != null && data['instructions'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(t.instructions, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
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
                      Expanded(child: Text(data['instructions'].toString(), style: GoogleFonts.roboto(fontSize: 14))),
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

class _ReportsTab extends StatefulWidget {
  final String? userEmail;
  const _ReportsTab({this.userEmail});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  List<DocumentSnapshot> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (widget.userEmail == null) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userEmail)
          .collection('DoctorReports')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _reports = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(t.noReports, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(t.reportsAppear, style: GoogleFonts.roboto(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final data = _reports[index].data() as Map<String, dynamic>;
          return _ReportCard(data: data);
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    final createdAt = data['createdAt'] ?? '';
    DateTime? dateTime;
    if (createdAt.isNotEmpty) {
      try { dateTime = DateTime.parse(createdAt); } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetails(context, data),
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
                      color: const Color(0xFF5B5EA6).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment, color: Color(0xFF5B5EA6)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? t.medicalReports,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        if (data['doctorName'] != null)
                          Text('Dr. ${data['doctorName']}',
                              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600])),
                        if (dateTime != null)
                          Text('${dateTime.day}/${dateTime.month}/${dateTime.year}',
                              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (data['summary'] != null && data['summary'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(data['summary'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[700])),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    final t = translation(context);
    final createdAt = data['createdAt'] ?? '';
    DateTime? dateTime;
    if (createdAt.isNotEmpty) {
      try { dateTime = DateTime.parse(createdAt); } catch (_) {}
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5EA6).withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.assignment, size: 48, color: Color(0xFF5B5EA6)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(data['title'] ?? t.medicalReports,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    if (data['doctorName'] != null)
                      Text('Dr. ${data['doctorName']}',
                          style: GoogleFonts.roboto(color: const Color(0xFF5B5EA6), fontWeight: FontWeight.w500)),
                    if (dateTime != null)
                      Text('${t.createdOn} ${dateTime.day}/${dateTime.month}/${dateTime.year}',
                          style: GoogleFonts.roboto(color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              if (data['content'] != null && data['content'].toString().isNotEmpty) ...[
                Text(t.detailedContent,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(data['content'].toString(), style: GoogleFonts.roboto(fontSize: 15, height: 1.6)),
                ),
              ],
              if (data['notes'] != null && data['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(t.notesForPatient,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
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
                      Expanded(child: Text(data['notes'].toString(), style: GoogleFonts.roboto(fontSize: 14))),
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
