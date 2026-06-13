import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/services/autonomy_score_service.dart';

class AutonomyScoreWidget extends StatefulWidget {
  final String? userEmail;

  const AutonomyScoreWidget({super.key, this.userEmail});

  @override
  State<AutonomyScoreWidget> createState() => _AutonomyScoreWidgetState();
}

class _AutonomyScoreWidgetState extends State<AutonomyScoreWidget> {
  final AutonomyScoreService _scoreService = AutonomyScoreService();
  dynamic _latestScore;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final email = widget.userEmail ??
        FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final score = await _scoreService.getLatestScore(email);
      setState(() {
        _latestScore = score;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _calculateAndRefresh() async {
    final email = widget.userEmail ??
        FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    setState(() => _loading = true);
    try {
      final score = await _scoreService.calculateScore(email);
      setState(() {
        _latestScore = score;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _scoreLevelLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Satisfaisant';
    if (score >= 40) return 'Modéré';
    return 'Critique';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : _latestScore == null
                ? _buildNoScore()
                : _buildScoreDisplay(),
      ),
    );
  }

  Widget _buildNoScore() {
    return Column(
      children: [
        Icon(Icons.analytics_outlined,
            size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Score d\'autonomie',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Aucun score calculé',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _calculateAndRefresh,
          icon: const Icon(Icons.calculate),
          label: const Text('Calculer maintenant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    final score = (_latestScore.score is double)
        ? _latestScore.score
        : (_latestScore.score as num).toDouble();

    final color = _scoreColor(score);
    final label = _scoreLevelLabel(score);

    return Column(
      children: [
        Text(
          'Score d\'autonomie',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${score.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '/100',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _calculateAndRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Actualiser'),
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
      ],
    );
  }
}
