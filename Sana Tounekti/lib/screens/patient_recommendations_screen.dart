import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';

class PatientRecommendationsScreen extends StatefulWidget {
  const PatientRecommendationsScreen({super.key});

  @override
  State<PatientRecommendationsScreen> createState() =>
      _PatientRecommendationsScreenState();
}

class _PatientRecommendationsScreenState
    extends State<PatientRecommendationsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (user?.email == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Recommendations')
          .where('patientEmail', isEqualTo: user!.email)
          .orderBy('date', descending: true)
          .get();
      final recs = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        String doctorName = data['doctorName'] as String? ?? '';
        if (doctorName.isEmpty) {
          final docUser = await FirebaseFirestore.instance
              .collection('Users')
              .doc(data['doctorEmail'] as String?)
              .get();
          doctorName =
              docUser.data()?['name'] as String? ?? data['doctorEmail'] as String? ?? '';
        }
        recs.add({...data, 'id': d.id, 'doctorName': doctorName});
      }
      if (mounted) setState(() => _recommendations = recs);
    } catch (e) {
      print('Error loading patient recommendations: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.myRecommendations,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.recommend,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        t.noRecommendations,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.doctorWillSendRecommendations,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecommendations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = _recommendations[index];
                      return _buildRecommendationCard(rec);
                    },
                  ),
                ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final content = rec['content'] ?? '';
    final doctorName = rec['doctorName'] ?? rec['doctorEmail'] ?? '';
    final date = rec['date'] ?? '';
    final dateStr = date.toString().length >= 10 ? date.toString().substring(0, 10) : date.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 0.1),
                  child: Text(
                    (doctorName.isNotEmpty ? doctorName[0] : 'D')
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(7, 82, 96, 1),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. $doctorName',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(7, 82, 96, 1),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.recommend,
                    color: Color.fromRGBO(7, 82, 96, 0.5)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(7, 82, 96, 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
                style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
