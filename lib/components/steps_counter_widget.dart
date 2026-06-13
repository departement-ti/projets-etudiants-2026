import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/step_counter_service.dart';

/// Widget affichant le nombre de pas du jour avec message d'encouragement
class StepsCounterWidget extends StatefulWidget {
  const StepsCounterWidget({super.key});

  @override
  State<StepsCounterWidget> createState() => _StepsCounterWidgetState();
}

class _StepsCounterWidgetState extends State<StepsCounterWidget> {
  final StepCounterService _service = StepCounterService();
  int _steps = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateSteps();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateSteps());
  }

  void _updateSteps() {
    if (!mounted) return;
    setState(() {
      _steps = _service.todaySteps;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getEncouragement(int steps, BuildContext context) {
    final t = translation(context);
    if (steps >= 10000) return t.stepEncouragement10000;
    if (steps >= 8000) return t.stepEncouragement8000;
    if (steps >= 5000) return t.stepEncouragement5000;
    if (steps >= 2000) return t.stepEncouragement2000;
    if (steps >= 500) return t.stepEncouragement500;
    return t.stepEncouragement0;
  }

  double _getProgress() {
    return (_steps / 10000).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_walk,
                        color: Color.fromRGBO(7, 82, 96, 1)),
                    const SizedBox(width: 8),
                    Text(
                      t.stepsToday,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromRGBO(7, 82, 96, 1),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_steps / 10000',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(7, 82, 96, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _getProgress(),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _steps >= 10000
                      ? Colors.green
                      : _steps >= 5000
                          ? Colors.orange
                          : const Color.fromRGBO(7, 82, 96, 1),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEncouragement(_steps, context),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
