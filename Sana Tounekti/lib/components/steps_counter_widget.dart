import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/step_counter_service.dart';

class StepsCounterWidget extends StatefulWidget {
  const StepsCounterWidget({super.key});

  @override
  State<StepsCounterWidget> createState() => _StepsCounterWidgetState();
}

class _StepsCounterWidgetState extends State<StepsCounterWidget> {
  final StepCounterService _service = StepCounterService();
  int _steps = 0;
  Timer? _timer;
  bool _isExpanded = false;

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

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(steps >= 10000 ? 0 : 1)}k';
    }
    return steps.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    final progress = _getProgress();
    final pct = (progress * 100).toInt();

    return Card(
      elevation: 2,
      shadowColor: const Color(0xFF5B5EA6).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFFFF5EE).withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B5EA6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_walk,
                          color: Color(0xFF5B5EA6), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.stepsToday,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5B5EA6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatSteps(_steps)} / 10k',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8B7D9C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: const Color(0xFF8B7D9C),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatSteps(_steps),
                              style: GoogleFonts.poppins(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: const Color(0xFF2D2B3A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '/ 10 000 pas',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF8B7D9C),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 7,
                                  backgroundColor: const Color(0xFFE8E0EE),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _steps >= 10000
                                        ? const Color(0xFF5B5EA6)
                                        : _steps >= 5000
                                            ? const Color(0xFFE8865E)
                                            : const Color(0xFF5B5EA6),
                                  ),
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5B5EA6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE8E0EE),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _steps >= 10000
                              ? const Color(0xFF5B5EA6)
                              : _steps >= 5000
                                  ? const Color(0xFFE8865E)
                                  : const Color(0xFF5B5EA6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.emoji_events,
                            size: 16, color: const Color(0xFFE8865E)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getEncouragement(_steps, context),
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8B7D9C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
