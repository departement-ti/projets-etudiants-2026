import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/models/mci_prediction.dart';
import 'package:mymeds_app/services/mci_service.dart';

class MCIAssessmentScreen extends StatefulWidget {
  const MCIAssessmentScreen({super.key});

  @override
  State<MCIAssessmentScreen> createState() => _MCIAssessmentScreenState();
}

class _MCIAssessmentScreenState extends State<MCIAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mciService = MCIService();

  int _age = 65;
  String _sleepQuality = 'Good';
  String _memoryIssues = 'Rarely';
  String _forgetfulnessFrequency = 'Monthly';
  double _reactionTime = 0.8;
  String _educationLevel = 'Secondary';
  int _dailyActivityScore = 5;

  bool _loading = false;
  MCIPrediction? _result;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).mciAssessment, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF5B5EA6),
      ),
      body: _result != null ? _buildResult() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 7,
              backgroundColor: const Color(0xFFE8E0EE),
              color: const Color(0xFF5B5EA6),
              minHeight: 6,
            ),
            const SizedBox(height: 24),

            if (_currentStep == 0) ...[
              _buildSectionTitle(translation(context).yourAge, translation(context).howOldAreYou),
              _buildSlider(
                value: _age.toDouble(),
                min: 45, max: 95,
                label: translation(context).yearsLabel(_age),
                divisions: 50,
                onChanged: (v) => setState(() => _age = v.round()),
              ),
            ],

            if (_currentStep == 1) ...[
              _buildSectionTitle(translation(context).sleepQuality, translation(context).howIsSleep),
              _buildSegmentedButton<String>(
                value: _sleepQuality,
                options: const ['Poor', 'Fair', 'Good'],
                labels: [translation(context).poor, translation(context).fair, translation(context).good],
                onChanged: (v) => setState(() => _sleepQuality = v),
              ),
            ],

            if (_currentStep == 2) ...[
              _buildSectionTitle(translation(context).memoryIssues, translation(context).troubleRemembering),
              _buildSegmentedButton<String>(
                value: _memoryIssues,
                options: const ['Rarely', 'Sometimes', 'Frequent'],
                labels: [translation(context).rarely, translation(context).sometimes, translation(context).frequent],
                onChanged: (v) => setState(() => _memoryIssues = v),
              ),
            ],

            if (_currentStep == 3) ...[
              _buildSectionTitle(translation(context).forgetfulness, translation(context).forgetDailyTasks),
              _buildSegmentedButton<String>(
                value: _forgetfulnessFrequency,
                options: const ['Monthly', 'Weekly', 'Daily'],
                labels: [translation(context).monthly, translation(context).weekly, translation(context).daily],
                onChanged: (v) => setState(() => _forgetfulnessFrequency = v),
              ),
            ],

            if (_currentStep == 4) ...[
              _buildSectionTitle(translation(context).reactionTime, translation(context).reactionSeconds),
              _buildSlider(
                value: _reactionTime * 100,
                min: 30, max: 250,
                label: translation(context).secLabel(_reactionTime.toStringAsFixed(1)),
                divisions: 22,
                onChanged: (v) => setState(() => _reactionTime = v / 100),
              ),
              _buildInfoCard(translation(context).normalReactionInfo),
            ],

            if (_currentStep == 5) ...[
              _buildSectionTitle(translation(context).educationLevel, translation(context).highestEducation),
              _buildSegmentedButton<String>(
                value: _educationLevel,
                options: const ['None', 'Primary', 'Secondary', 'Higher'],
                labels: [translation(context).none, translation(context).primary, translation(context).secondary, translation(context).higher],
                onChanged: (v) => setState(() => _educationLevel = v),
              ),
            ],

            if (_currentStep == 6) ...[
              _buildSectionTitle(translation(context).dailyActivity, translation(context).howActiveDaily),
              _buildSlider(
                value: _dailyActivityScore.toDouble(),
                min: 0, max: 10,
                label: translation(context).outOf10(_dailyActivityScore),
                divisions: 10,
                onChanged: (v) => setState(() => _dailyActivityScore = v.round()),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(translation(context).backBtn),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep < 6
                        ? () => setState(() => _currentStep++)
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5EA6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentStep < 6 ? translation(context).nextBtn : translation(context).getResults,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF5B5EA6))),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required String label,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF5B5EA6),
                thumbColor: const Color(0xFF5B5EA6),
                overlayColor: const Color(0xFF5B5EA6).withAlpha(30),
              ),
              child: Slider(
                value: value,
                min: min, max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
            Text(label, style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedButton<T>({
    required T value,
    required List<T> options,
    required List<String> labels,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      children: List.generate(options.length, (i) {
        final selected = options[i] == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onChanged(options[i]),
              style: ElevatedButton.styleFrom(
                backgroundColor: selected
                    ? const Color(0xFF5B5EA6)
                    : const Color(0xFF5B5EA6).withAlpha(20),
                foregroundColor: selected ? Colors.white : const Color(0xFF5B5EA6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF5B5EA6)
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Text(labels[i], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.roboto(fontSize: 13, color: Colors.blue))),
        ],
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return translation(context).scoreExcellent;
    if (score >= 60) return translation(context).scoreGood;
    if (score >= 40) return translation(context).scoreFair;
    return translation(context).needsAttention;
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    setState(() => _loading = true);

    final result = await _mciService.predictMCI(
      userEmail: user!.email!,
      age: _age,
      sleepQuality: _sleepQuality,
      memoryIssues: _memoryIssues,
      forgetfulnessFrequency: _forgetfulnessFrequency,
      reactionTime: _reactionTime,
      educationLevel: _educationLevel,
      dailyActivityScore: _dailyActivityScore,
    );

    setState(() {
      _result = result;
      _loading = false;
    });
  }

  Widget _buildResult() {
    final color = _result!.brainHealthScore >= 60
        ? const Color(0xFF4CAF50)
        : _result!.brainHealthScore >= 40
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            width: 160, height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _result!.brainHealthScore / 100,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFE8E0EE),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_result!.brainHealthScore.round()}%',
                        style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                      ),
                      Text(
                        _getScoreLabel(_result!.brainHealthScore),
                        style: GoogleFonts.roboto(fontSize: 14, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              translation(context).riskLabel(_result!.riskLevel),
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: const Color(0xFF5B5EA6)),
                      const SizedBox(width: 8),
                      Text(translation(context).recommendations, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._result!.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: const Color(0xFF5B5EA6), size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r, style: GoogleFonts.roboto(fontSize: 14))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() { _result = null; _currentStep = 0; }),
              icon: const Icon(Icons.refresh),
              label: Text(translation(context).retakeAssessment, style: GoogleFonts.poppins(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5EA6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
