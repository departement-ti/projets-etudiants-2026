import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/autonomy_score_widget.dart';
import 'package:mymeds_app/components/brain_health_card.dart';
import 'package:mymeds_app/components/cognitive_chart.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/models/mci_prediction.dart';
import 'package:mymeds_app/screens/cognitive_progress.dart';
import 'package:mymeds_app/screens/mci_assessment.dart';
import 'package:mymeds_app/screens/nutrition_screen.dart';
import 'package:mymeds_app/screens/cognitive_exercises.dart';
import 'package:mymeds_app/services/mci_service.dart';
import 'package:mymeds_app/services/cognitive_service.dart';
import 'package:mymeds_app/services/step_counter_service.dart';

class BrainHealthDashboard extends StatefulWidget {
  const BrainHealthDashboard({super.key});

  @override
  State<BrainHealthDashboard> createState() => _BrainHealthDashboardState();
}

class _BrainHealthDashboardState extends State<BrainHealthDashboard> {
  final _mciService = MCIService();
  final _cognitiveService = CognitiveService();
  MCIPrediction? _latestPrediction;
  Map<String, double> _weeklyAverages = {};
  int _todaySteps = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final results = await Future.wait([
      _mciService.getLatestPrediction(user!.email!),
      _cognitiveService.getWeeklyAverages(user.email!),
      Future.value(StepCounterService().todaySteps),
    ]);

    if (mounted) {
      setState(() {
        _latestPrediction = results[0] as MCIPrediction?;
        _weeklyAverages = results[1] as Map<String, double>;
        _todaySteps = results[2] as int;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Brain Health', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { setState(() => _loading = true); _loadData(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color.fromRGBO(7, 82, 96, 1)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_latestPrediction != null)
                      BrainHealthCard(
                        score: _latestPrediction!.brainHealthScore,
                        riskLevel: _latestPrediction!.riskLevel,
                        date: '${_latestPrediction!.date.day}/${_latestPrediction!.date.month}/${_latestPrediction!.date.year}',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const MCIAssessmentScreen(),
                          )).then((_) => _loadData());
                        },
                      )
                    else
                      _buildStartAssessmentCard(),
                    const SizedBox(height: 16),
                    _buildMenuGrid(),
                    const SizedBox(height: 16),
                    const AutonomyScoreWidget(),
                    const SizedBox(height: 16),
                    _buildDailySummary(),
                    const SizedBox(height: 16),
                    if (_weeklyAverages.isNotEmpty)
                      CognitiveChart(
                        title: 'Cognitive Progress',
                        data: _weeklyAverages.entries
                            .map((e) => ChartDataPoint(e.key, e.value))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    if (_latestPrediction?.recommendations.isNotEmpty ?? false)
                      _buildRecommendations(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStartAssessmentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const MCIAssessmentScreen(),
          )).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.psychology, size: 64, color: Color.fromRGBO(7, 82, 96, 1)),
              const SizedBox(height: 12),
              Text(
                'Start Brain Assessment',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Take a quick assessment to evaluate your brain health',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const MCIAssessmentScreen(),
                  )).then((_) => _loadData());
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Begin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMenuButton(Icons.restaurant_menu, 'Nutrition', Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionScreen()));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildMenuButton(Icons.fitness_center, 'Exercises', Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CognitiveExercisesScreen()));
            })),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMenuButton(Icons.assessment, 'MCI Test', Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MCIAssessmentScreen())).then((_) => _loadData());
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildMenuButton(Icons.trending_up, 'Progress', Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CognitiveProgressScreen()));
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 100,
      child: FilledButton(
        onPressed: onTap,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(color.withAlpha(30)),
          foregroundColor: WidgetStatePropertyAll(color),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          elevation: const WidgetStatePropertyAll(1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(Icons.directions_walk, 'Steps', '$_todaySteps'),
                _buildStatItem(Icons.psychology, 'MCI Risk', _latestPrediction?.riskLevel ?? 'N/A'),
                _buildStatItem(Icons.memory, 'Score', '${_latestPrediction?.brainHealthScore.round() ?? '-'}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color.fromRGBO(7, 82, 96, 1), size: 24),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Color.fromRGBO(7, 82, 96, 1)),
                const SizedBox(width: 8),
                Text('Recommendations', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color.fromRGBO(7, 82, 96, 1))),
              ],
            ),
            const SizedBox(height: 8),
            ...(_latestPrediction?.recommendations ?? []).map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16, color: Color.fromRGBO(7, 82, 96, 1))),
                  Expanded(child: Text(r, style: GoogleFonts.roboto(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
