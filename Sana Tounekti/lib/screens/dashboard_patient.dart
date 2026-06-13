import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:mymeds_app/services/alarm_stream_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/components/shake_sos_dialog.dart';
import 'package:mymeds_app/components/steps_counter_widget.dart';
import 'package:mymeds_app/screens/add_medication1.dart';
import 'package:mymeds_app/screens/alarm_ring.dart';
import 'package:mymeds_app/screens/chatbot.dart';
import 'package:mymeds_app/screens/senior_chat_screen.dart';
import 'package:mymeds_app/screens/brain_health_dashboard.dart';
import 'package:mymeds_app/screens/daily_encouragement_dialog.dart';
import 'package:mymeds_app/screens/homepage2.dart';
import 'package:mymeds_app/screens/medication.dart';
import 'package:mymeds_app/screens/more.dart';
import 'package:mymeds_app/screens/statistic.dart';
import 'package:mymeds_app/services/shake_detector_service.dart';
import 'package:mymeds_app/services/step_counter_service.dart';
import 'package:mymeds_app/services/missed_medication_service.dart';
import 'package:mymeds_app/l10n/app_localizations.dart';
import 'package:mymeds_app/services/talkback_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardPatient extends StatefulWidget {
  const DashboardPatient({super.key});

  @override
  State<DashboardPatient> createState() => _DashboardPatientState();
}

class _DashboardPatientState extends State<DashboardPatient> {
  final user = FirebaseAuth.instance.currentUser;

  //bottom nav bar
  int _selectedIndex = 0;

  //Floating Action Button
  bool isFABvisible = true;
  bool chatBot = true;

  //alarm list
  late List<AlarmSettings> alarms;

  final AlarmStreamService _alarmService = AlarmStreamService();
  StreamSubscription<AlarmSettings>? _alarmSubscription;
  final ShakeDetectorService _shakeService = ShakeDetectorService();
  final StepCounterService _stepService = StepCounterService();
  final MissedMedicationService _missedMedService = MissedMedicationService();

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

//show alarm ring screen
  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    print('Opened ring screen');
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlarmScreen(alarmSettings: alarmSettings),
        ));
    loadAlarms();
  }

  final _talkback = TalkbackService();

  // // documnet IDs
  // List<String> docIDs = [];

  // //get docIDs
  // Future getDocIDs() async {
  //   await FirebaseFirestore.instance.collection('users').get().then(
  //         (snapshot) => snapshot.docs.forEach(
  //           (documnet) {
  //             print(documnet.reference);
  //             docIDs.add(documnet.reference.id);
  //           },
  //         ),
  //       );
  // }

  @override
  void initState() {
    if (!kIsWeb) {
      loadAlarms();
      _alarmSubscription = _alarmService.alarmStream.listen(navigateToRingScreen);
      _shakeService.addListener(_onShakeDetected);
      if (user?.email != null) {
        _missedMedService.start(user!.email!);
        _startStepCounter();
      }
    }
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDailyEncouragementDialog(context);
    });
  }

  Future<void> _startStepCounter() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepService.start(user!.email!);
    } else {
      print('❌ Permission ACTIVITY_RECOGNITION refusée');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).stepPermissionDenied),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onShakeDetected() {
    if (!mounted) return;
    ShakeSOSOverlay.show(context);
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    _shakeService.removeListener(_onShakeDetected);
    _stepService.stop();
    _missedMedService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //pages
    final List<Widget> pages = <Widget>[
      //main page
      const HomePage2(),
      //medication
      const Mediaction(),
      //statistic
      const Statistic(),
      //settings
      const More(),
    ];

    //scaffold
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: StepsCounterWidget(),
            ),
            Expanded(
              child: pages.elementAt(_selectedIndex),
            ),
          ],
        ),
      ),
      //floating action button
      floatingActionButton: isFABvisible
          ? Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                onPressed: () {
                  !chatBot
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMedication1(),
                          ),
                        )
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SeniorChatScreen(),
                          ),
                        );
                },
                backgroundColor: const Color(0xFFE8865E),
                foregroundColor: Colors.white,
                elevation: 4,
                child: Icon(
                  !chatBot ? Icons.add : Icons.smart_toy_outlined,
                  size: 36,
                ),
              ),
            )
          : null,
      //bottom navigation
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFFFF5EE),
        height: 80,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, size: 32),
            label: translation(context).home,
            selectedIcon: const Icon(Icons.home_rounded, color: Color(0xFF5B5EA6), size: 32),
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined, size: 32),
            label: translation(context).medications,
            selectedIcon: const Icon(Icons.medication, color: Color(0xFF5B5EA6), size: 32),
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined, size: 32),
            label: translation(context).statistics,
            selectedIcon: const Icon(Icons.analytics_rounded, color: Color(0xFF5B5EA6), size: 32),
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_customize_outlined, size: 32),
            label: translation(context).more,
            selectedIcon: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF5B5EA6), size: 32),
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int) {
          switch (int) {
            case 0:
              isFABvisible = true;
              chatBot = true;
              break;
            case 1: //home
              //show FAB in medication page
              isFABvisible = true;
              chatBot = false;
              break;
            case 2:
              isFABvisible = false;
              chatBot = false;
              break;
            case 3:
              chatBot = false;
              isFABvisible = false;
              break;
          }

          setState(() {
            _selectedIndex = int;
          });
          final tabLabels = [
            translation(context).home,
            translation(context).medications,
            translation(context).statistics,
            translation(context).more,
          ];
          _talkback.setLanguage(
            AppLocalizations.of(context)?.localeName ?? 'fr',
          ).then((_) {
            _talkback.speak(tabLabels[int]);
          });
        },
      ),
    );
  }
}
