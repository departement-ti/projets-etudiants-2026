import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/cognitive_chart.dart';
import 'package:mymeds_app/models/cognitive_score.dart';
import 'package:mymeds_app/services/cognitive_service.dart';
import 'package:mymeds_app/services/mci_service.dart';

class CognitiveProgressScreen extends StatefulWidget {
  const CognitiveProgressScreen({super.key});
  @override
  State<CognitiveProgressScreen> createState() => _CognitiveProgressScreenState();
}

class _CognitiveProgressScreenState extends State<CognitiveProgressScreen>
    with SingleTickerProviderStateMixin {
  final _cognitiveService = CognitiveService();
  final _mciService = MCIService();
  late TabController _tabController;

  List<CognitiveScore> _scores = [];
  Map<String, double> _weeklyAverages = {};
  List<dynamic> _mciHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final results = await Future.wait([
      _cognitiveService.getScoreHistory(user!.email!),
      _cognitiveService.getWeeklyAverages(user.email!),
      _mciService.getPredictionHistory(user.email!),
    ]);

    if (mounted) {
      setState(() {
        _scores = results[0] as List<CognitiveScore>;
        _weeklyAverages = results[1] as Map<String, double>;
        _mciHistory = results[2] as List<dynamic>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Cognitive'),
            Tab(text: 'Brain Health'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color.fromRGBO(7, 82, 96, 1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCognitiveTab(),
                _buildBrainHealthTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildCognitiveTab() {
    final chartData = _weeklyAverages.entries
        .map((e) => ChartDataPoint(e.key, e.value))
        .toList();

    final lastScores = <String, CognitiveScore?>{};
    for (final s in _scores) {
      lastScores.putIfAbsent(s.testType, () => s);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chartData.isNotEmpty) ...[
            CognitiveChart(
              title: 'Weekly Performance',
              data: chartData,
            ),
            const SizedBox(height: 16),
          ],
          Text('Latest Scores', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
          const SizedBox(height: 12),
          if (lastScores.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.psychology, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('No test scores yet. Complete some cognitive exercises!',
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...lastScores.entries.map((entry) {
              final s = entry.value!;
              final color = s.percentage >= 80 ? Colors.green : s.percentage >= 50 ? Colors.orange : Colors.red;
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('${s.percentage.round()}%',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.testType[0].toUpperCase() + s.testType.substring(1),
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(s.getPerformanceLevel(),
                                style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('${s.date.day}/${s.date.month}/${s.date.year}',
                          style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBrainHealthTab() {
    final chartData = _mciHistory.map((p) {
      return ChartDataPoint(
        '${p.date.day}/${p.date.month}',
        p.brainHealthScore,
      );
    }).toList().reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chartData.isNotEmpty) ...[
            CognitiveChart(
              title: 'Brain Health Score Evolution',
              data: chartData,
              lineColor: Colors.purple,
            ),
            const SizedBox(height: 16),
          ],
          if (_mciHistory.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.healing, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('Take an MCI assessment to track your brain health over time.',
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MCI Assessments', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
          const SizedBox(height: 12),
          if (_mciHistory.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.history, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('No assessment history yet.', style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ..._mciHistory.map((p) => Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: (p.brainHealthScore >= 60 ? Colors.green : p.brainHealthScore >= 40 ? Colors.orange : Colors.red).withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${p.brainHealthScore.round()}%',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold,
                                color: p.brainHealthScore >= 60 ? Colors.green : p.brainHealthScore >= 40 ? Colors.orange : Colors.red)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Risk: ${p.riskLevel}',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text('${p.date.day}/${p.date.month}/${p.date.year}',
                              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(p.getScoreLabel(),
                        style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
