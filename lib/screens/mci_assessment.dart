import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: Text('MCI Assessment', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
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
              backgroundColor: Colors.grey[200],
              color: const Color.fromRGBO(7, 82, 96, 1),
              minHeight: 6,
            ),
            const SizedBox(height: 24),

            if (_currentStep == 0) ...[
              _buildSectionTitle('Your Age', 'How old are you?'),
              _buildSlider(
                value: _age.toDouble(),
                min: 45, max: 95,
                label: '$_age years',
                divisions: 50,
                onChanged: (v) => setState(() => _age = v.round()),
              ),
            ],

            if (_currentStep == 1) ...[
              _buildSectionTitle('Sleep Quality', 'How would you rate your sleep?'),
              _buildSegmentedButton<String>(
                value: _sleepQuality,
                options: const ['Poor', 'Fair', 'Good'],
                labels: const ['Poor 😟', 'Fair 🙂', 'Good 😊'],
                onChanged: (v) => setState(() => _sleepQuality = v),
              ),
            ],

            if (_currentStep == 2) ...[
              _buildSectionTitle('Memory Issues', 'Do you have trouble remembering things?'),
              _buildSegmentedButton<String>(
                value: _memoryIssues,
                options: const ['Rarely', 'Sometimes', 'Frequent'],
                labels: const ['Rarely', 'Sometimes', 'Frequent'],
                onChanged: (v) => setState(() => _memoryIssues = v),
              ),
            ],

            if (_currentStep == 3) ...[
              _buildSectionTitle('Forgetfulness', 'How often do you forget daily tasks?'),
              _buildSegmentedButton<String>(
                value: _forgetfulnessFrequency,
                options: const ['Monthly', 'Weekly', 'Daily'],
                labels: const ['Monthly', 'Weekly', 'Daily'],
                onChanged: (v) => setState(() => _forgetfulnessFrequency = v),
              ),
            ],

            if (_currentStep == 4) ...[
              _buildSectionTitle('Reaction Time', 'Approximate reaction time (seconds)'),
              _buildSlider(
                value: _reactionTime * 100,
                min: 30, max: 250,
                label: '${_reactionTime.toStringAsFixed(1)} sec',
                divisions: 22,
                onChanged: (v) => setState(() => _reactionTime = v / 100),
              ),
              _buildInfoCard('Normal reaction time for elderly: 0.5-1.5 seconds'),
            ],

            if (_currentStep == 5) ...[
              _buildSectionTitle('Education Level', 'Your highest education level'),
              _buildSegmentedButton<String>(
                value: _educationLevel,
                options: const ['None', 'Primary', 'Secondary', 'Higher'],
                labels: const ['None', 'Primary', 'Secondary', 'Higher'],
                onChanged: (v) => setState(() => _educationLevel = v),
              ),
            ],

            if (_currentStep == 6) ...[
              _buildSectionTitle('Daily Activity', 'How active are you daily? (0-10)'),
              _buildSlider(
                value: _dailyActivityScore.toDouble(),
                min: 0, max: 10,
                label: '$_dailyActivityScore/10',
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
                    child: const Text('Back'),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep < 6
                        ? () => setState(() => _currentStep++)
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentStep < 6 ? 'Next' : 'Get Results',
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
        Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color.fromRGBO(7, 82, 96, 1))),
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
                activeTrackColor: const Color.fromRGBO(7, 82, 96, 1),
                thumbColor: const Color.fromRGBO(7, 82, 96, 1),
                overlayColor: const Color.fromRGBO(7, 82, 96, 1).withAlpha(30),
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
                    ? const Color.fromRGBO(7, 82, 96, 1)
                    : const Color.fromRGBO(7, 82, 96, 1).withAlpha(20),
                foregroundColor: selected ? Colors.white : const Color.fromRGBO(7, 82, 96, 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected
                        ? const Color.fromRGBO(7, 82, 96, 1)
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
                  backgroundColor: Colors.grey[200],
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
                        _result!.getScoreLabel(),
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
              'MCI Risk: ${_result!.riskLevel}',
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
                      const Icon(Icons.lightbulb, color: Color.fromRGBO(7, 82, 96, 1)),
                      const SizedBox(width: 8),
                      Text('Recommendations', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._result!.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color.fromRGBO(7, 82, 96, 1), size: 20),
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
              label: Text('Retake Assessment', style: GoogleFonts.poppins(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
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
