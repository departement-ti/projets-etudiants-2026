import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:mymeds_app/services/alarm_stream_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/screens/alarm_ring.dart';
import 'package:mymeds_app/screens/daily_encouragement_dialog.dart';
import 'package:mymeds_app/screens/assistant_home.dart';
import 'package:mymeds_app/screens/assistant_patients.dart';
import 'package:mymeds_app/screens/assistant_settings.dart';
import 'package:mymeds_app/screens/statistic.dart';
import 'package:mymeds_app/components/language_constants.dart';

class DashboardAssistant extends StatefulWidget {
  const DashboardAssistant({super.key});

  @override
  State<DashboardAssistant> createState() => _DashboardAssistantState();
}

class _DashboardAssistantState extends State<DashboardAssistant> {
  final user = FirebaseAuth.instance.currentUser;

  int _selectedIndex = 0;

  bool isFABvisible = false;
  bool chatBot = false;

  late List<AlarmSettings> alarms;

  final AlarmStreamService _alarmService = AlarmStreamService();
  StreamSubscription<AlarmSettings>? _alarmSubscription;

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    print('Opened ring screen');
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlarmScreen(alarmSettings: alarmSettings),
        ));
    loadAlarms();
  }

  @override
  void initState() {
    if (!kIsWeb) {
      loadAlarms();
      _alarmSubscription = _alarmService.alarmStream.listen(navigateToRingScreen);
    }
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDailyEncouragementDialog(context);
    });
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const AssistantHome(),
      const AssistantPatients(),
      const Statistic(),
      const AssistantSettings(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translation(context).assistantSpaceTitle,
          style: GoogleFonts.poppins(
            color: const Color.fromRGBO(7, 82, 96, 1),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 242, 253, 255),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: pages.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(255, 242, 253, 255),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: translation(context).home,
            selectedIcon: const Icon(
              Icons.home_rounded,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            label: translation(context).patients,
            selectedIcon: const Icon(
              Icons.people,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            label: translation(context).statistics,
            selectedIcon: const Icon(
              Icons.analytics_rounded,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: translation(context).settings,
            selectedIcon: const Icon(
              Icons.settings,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int) {
          setState(() {
            _selectedIndex = int;
          });
        },
      ),
    );
  }
}
