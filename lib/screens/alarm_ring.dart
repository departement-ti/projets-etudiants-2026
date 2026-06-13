import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/alarm_mapping_service.dart';

class AlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmScreen({Key? key, required this.alarmSettings}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _stopAlarm({bool markAsTaken = true}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Marquer la médication comme prise dans Firestore
      if (markAsTaken) {
        final mapping = await AlarmMappingService.getMapping(widget.alarmSettings.id);
        if (mapping != null) {
          final medDocId = mapping['medDocId'] as String?;
          final logDocId = mapping['logDocId'] as String?;
          final email = mapping['email'] as String?;
          if (medDocId != null && logDocId != null && email != null) {
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(email)
                .collection('Medications')
                .doc(medDocId)
                .collection('Logs')
                .doc(logDocId)
                .update({'isTaken': true});
            print('Medication marked as taken: $medDocId / $logDocId');
          }
        }
      }

      await Alarm.stop(widget.alarmSettings.id);
      await AlarmMappingService.removeMapping(widget.alarmSettings.id);
    } catch (e) {
      print('Error stopping alarm: $e');
    }

    if (mounted) {
      Navigator.pop(context);
    }
    _isProcessing = false;
  }

  Future<void> _snoozeAlarm() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final now = DateTime.now();
      await Alarm.stop(widget.alarmSettings.id);
      await Alarm.set(
        alarmSettings: widget.alarmSettings.copyWith(
          dateTime: DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            0,
            0,
          ).add(const Duration(minutes: 10)),
        ),
      );
    } catch (e) {
      print('Error snoozing alarm: $e');
    }

    if (mounted) {
      Navigator.pop(context);
    }
    _isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    final titleParts = widget.alarmSettings.notificationTitle.split(' ');
    final medName = titleParts.length > 1
        ? titleParts.sublist(1).join(' ')
        : widget.alarmSettings.notificationTitle;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 7, 83, 96),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const SizedBox(height: 10),
                // Heure actuelle
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final now = DateTime.now();
                    return Text(
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.roboto(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.white70,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Nom du médicament avec animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '💊 $medName',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Cloche animée
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 0.1 - 0.05,
                      child: Icon(
                        Icons.notifications_active,
                        size: 80,
                        color: Colors.amber.shade300,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Texte de rappel
                Text(
                  widget.alarmSettings.notificationBody,
                  style: GoogleFonts.roboto(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Image
                Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    'lib/assets/images/taking_med.png',
                    height: 200.0,
                  ),
                ),
                const SizedBox(height: 10),
                // Boutons d'action
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton Skip
                        SizedBox(
                          height: 55,
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: TextButton.icon(
                            onPressed: _isProcessing ? null : () => _stopAlarm(markAsTaken: false),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.white.withAlpha(51)),
                              foregroundColor: const WidgetStatePropertyAll(
                                Colors.white),
                              shape: const WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.skip_next, size: 24),
                            label: Text(
                              translation(context).alarmSkip,
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bouton Snooze (10 minutes)
                        SizedBox(
                          height: 55,
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: TextButton.icon(
                            onPressed: _isProcessing ? null : _snoozeAlarm,
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.amber.shade300),
                              foregroundColor: WidgetStatePropertyAll(
                                Colors.grey.shade900),
                              shape: const WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.snooze, size: 24),
                            label: Text(
                              translation(context).alarmSnooze,
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bouton Take (principal)
                    SizedBox(
                      height: 60,
                      width: MediaQuery.of(context).size.width,
                      child: FilledButton.icon(
                        onPressed: _isProcessing ? null : _stopAlarm,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromRGBO(7, 82, 96, 1),
                          elevation: 4,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(16),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle, size: 28),
                        label: Text(
                          translation(context).alarmTake,
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
