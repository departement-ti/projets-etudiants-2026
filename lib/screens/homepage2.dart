import 'dart:async';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/components/medcard.dart';
import 'package:mymeds_app/screens/account_settings.dart';
import 'package:mymeds_app/screens/add_medication1.dart';
import 'package:mymeds_app/services/alarm_mapping_service.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:awesome_notifications/awesome_notifications.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  //date listener
  final ValueNotifier<CalendarDateTime> _selectedDate =
      ValueNotifier<CalendarDateTime>(
    CalendarDateTime(
        year: DateTime.now().year,
        month: DateTime.now().month,
        day: DateTime.now().day),
  );

  //current user
  User? currentUser = FirebaseAuth.instance.currentUser;

  //document IDs of medicatiions
  List<String> docIds = [];
  List<String> dateIds = [];
  List<String> timeIds = [];
  List<String> dates = [];
  List<String> times = [];

  //alarm list
  late List<AlarmSettings> alarms;

  StreamSubscription? subscription;

  void refresh() {
    setState(() {
      _selectedDate.value;
    });
  }

  String _formatWeekday(CalendarDateTime date) {
    final dt = DateTime(date.year, date.month, date.day);
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[dt.weekday - 1];
  }

  String _formatDate(CalendarDateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Vérifie et demande la permission pour les alarmes exactes (Android 12+)
  Future<bool> _checkAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    
    // Vérifier la permission de notification
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        print('Notification permission denied');
        return false;
      }
    }
    
    print('Alarm permissions checked successfully');
    return true;
  }

  Future setAlarms() async {
    print('Running set alarms...');
    
    // Vérifier les permissions d'abord
    final hasPermission = await _checkAlarmPermission();
    if (!hasPermission) {
      print('Cannot set alarms without proper permissions');
      return;
    }
    
    docIds = [];
    dates = [];
    times = [];

    // Vérifier que l'utilisateur est connecté
    if (currentUser?.email == null) {
      print('No user logged in, cannot set alarms');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .collection('Medications')
          .get();

        for (final document in snapshot.docs) {
        print('Medications Doc ID: ${document.reference.id}');

        final snapshotDates = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.email)
            .collection('Medications')
            .doc(document.reference.id)
            .collection('Logs')
            .get(const GetOptions(source: Source.server));
        
        print('Found ${snapshotDates.docs.length} log entries for this medication');

        for (final document1 in snapshotDates.docs) {
          print('DateTime: ${document1.reference.id}');
          List<String> dateTimeStr = document1.reference.id.split(' ');
          if (dateTimeStr.isEmpty) continue;
          dates.add(dateTimeStr[0]);
          Map<String, dynamic> medData = document.data();
          if (dateTimeStr[0].isEmpty) continue;
          List<String> date = dateTimeStr[0].split('-');
          if (date.length < 3) continue;

          // final snapshotTime = await FirebaseFirestore.instance
          //     .collection('Users')
          //     .doc(currentUser!.email)
          //     .collection('Medications')
          //     .doc(document.reference.id)
          //     .collection('Logs')
          //     .doc(document1.reference.id)
          //     .collection('Times')
          //     .get();

          int year = int.parse(date[0]);
          int month = int.parse(date[1]);
          int day = int.parse(date[2]);

          if (dateTimeStr.length < 2) continue;
          List<String> time = dateTimeStr[1].toString().split(':');
          if (time.length < 2) continue;

          int hours = int.parse(time[0]);
          int mins = int.parse(time[1]);

          DateTime dateTime = DateTime(
            year,
            month,
            day,
            hours,
            mins,
            0,
            0,
          );
          Duration difference = dateTime.difference(DateTime.now());
          print('Difference: $difference');
          // Générer un ID positif unique basé sur la date et le nom du médicament
          int id = '${dateTime.millisecondsSinceEpoch}_${medData['medname'] ?? 'med'}'.hashCode.abs();
          // S'assurer que l'ID est dans une plage valide pour Alarm (positif et pas trop grand)
          id = id % 2147483647; // Max int32
          print('Alarm ID: $id');
          if (!difference.isNegative) {
            // Vérifier si l'alarme existe déjà
            final existingAlarms = Alarm.getAlarms();
            final alarmExists = existingAlarms.any((alarm) => alarm.id == id);
            
            if (!alarmExists) {
              String dosage = '';
              if (medData['strength'] != null &&
                  medData['strength_unit'] != null) {
                dosage = ' - ${medData['strength']} ${medData['strength_unit']}';
              }
              final alarmSettings = AlarmSettings(
                id: id,
                dateTime: dateTime,
                assetAudioPath: 'assets/audio/marimba.mp3',
                loopAudio: true,
                vibrate: false,
                volume: 1.0,
                fadeDuration: 2.0,
                notificationTitle: '💊 ${medData['medname'] ?? 'Medication'}',
                notificationBody:
                    'Take ${medData['medcount'] ?? 1} ${medData['category'] ?? 'tablet'}(s)$dosage',
                enableNotificationOnKill: true,
                androidFullScreenIntent: true,
              );
              try {
                await Alarm.set(alarmSettings: alarmSettings);
                await AlarmMappingService.saveMapping(
                  alarmId: id,
                  medDocId: document.reference.id,
                  logDocId: document1.reference.id,
                  email: currentUser!.email!,
                );
                print('Alarm set successfully for $dateTime');
              } catch (e) {
                print('Error setting alarm: $e');
              }
            } else {
              print('Alarm already exists for ID: $id');
            }
          }
        }
      }
    } on FirebaseException catch (e) {
      print('ERROR: ${e.code}');
    }

    print('Date array: $dates');
    print('Times array: $times');
    
    // Vérifier les alarmes actives après les avoir définies
    await Future.delayed(const Duration(seconds: 1));
    final activeAlarms = Alarm.getAlarms();
    print('Active alarms count: ${activeAlarms.length}');
    for (final alarm in activeAlarms) {
      print('Active alarm: ${alarm.id} - ${alarm.dateTime} - ${alarm.notificationTitle}');
    }
  }

  Future getDocIDs() async {
    docIds = [];
    dateIds = [];
    timeIds = [];

    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.email)
        .collection('Medications')
        .get();

    for (final document in snapshot.docs) {
      // print('Medications Doc ID: ${document.reference.id}');

      final snapshot1 = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .collection('Medications')
          .doc(document.reference.id)
          .collection('Logs')
          .get();

      for (final document1 in snapshot1.docs) {
        print('Date ID: ${document1.reference.id}');
        List<String> dateTime = document1.reference.id.split(' ');
        if (dateTime.length < 2) continue;
        //check selected date from timeline calendar
        if (dateTime[0] == _selectedDate.value.toString()) {
          docIds.add(document.reference.id);
          dateIds.add(dateTime[0]);
          timeIds.add(dateTime[1]);
          // print('${document.reference.id} added for list on ${_selectedDate.value.toString()}');
          // print('Array LENGTH: ${docIds.length}');
        } else {
          // print('Not added to list');
        }
      }
    }
  }

  bool _isFirstLoad = true;

  @override
  initState() {
    super.initState();
    // Utiliser WidgetsBinding pour s'assurer que le widget est monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setAlarms();
    });
    // loadAlarms();
    // subscription ??= Alarm.ringStream.stream.listen(
    //   (alarmSettings) => navigateToRingScreen(alarmSettings),
    // );

    // AwesomeNotifications().setListeners(
    //   onActionReceivedMethod: onActionReceivedMethod,
    //   onNotificationCreatedMethod: onNotificationCreatedMethod,
    //   onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    //   onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    // );

    //notification permission check
    // AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    //   if (!isAllowed) {
    //     showDialog(
    //       context: context,
    //       builder: (context) {
    //         return AlertDialog(
    //           title: Text(
    //             'Notifications',
    //             style: GoogleFonts.roboto(
    //               color: const Color.fromARGB(255, 16, 15, 15),
    //             ),
    //           ),
    //           content: Text(
    //             'Would you like MyMeds to send notifications?',
    //             style: GoogleFonts.roboto(
    //               color: const Color.fromARGB(255, 16, 15, 15),
    //             ),
    //           ),
    //           actions: <Widget>[
    //             TextButton(
    //               child: Text(
    //                 'Don\'t allow',
    //                 style: GoogleFonts.roboto(
    //                   fontWeight: FontWeight.w600,
    //                   color: const Color.fromARGB(255, 82, 82, 82),
    //                 ),
    //               ),
    //               onPressed: () {
    //                 Navigator.of(context).pop();
    //               },
    //             ),
    //             TextButton(
    //               child: Text(
    //                 'Allow',
    //                 style: GoogleFonts.roboto(
    //                   fontWeight: FontWeight.w600,
    //                   color: const Color.fromRGBO(7, 82, 96, 1),
    //                 ),
    //               ),
    //               onPressed: () {
    //                 AwesomeNotifications()
    //                     .requestPermissionToSendNotifications()
    //                     .then((_) => Navigator.of(context).pop());
    //               },
    //             ),
    //           ],
    //         );
    //       },
    //     );
    //   }
    // });
  }

//   void loadAlarms() {
//     setState(() {
//       alarms = Alarm.getAlarms();
//       alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
//     });
//   }

// //show alarm ring screen
//   Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
//     print('Opened ring screen');
//     await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => AlarmScreen(alarmSettings: alarmSettings),
//         ));
//     loadAlarms();
//   }

//notification action buttons click
  // Future<void> onActionReceivedMethod(
  //     ReceivedNotification receivedNotification) async {
  //   Map<String, dynamic> notificationData = receivedNotification.toMap();
  //   print(
  //       'Notification action clicked -${notificationData["buttonKeyPressed"]}');
  //   switch (notificationData["buttonKeyPressed"].toString()) {
  //     case 'snooze':
  //       print('CLICKED SNOOZE');
  //       // final now = DateTime.now();
  //       // Alarm.set(
  //       //   alarmSettings: alarmSettings.copyWith(
  //       //     dateTime: DateTime(
  //       //       now.year,
  //       //       now.month,
  //       //       now.day,
  //       //       now.hour,
  //       //       now.minute,
  //       //       0,
  //       //       0,
  //       //     ).add(const Duration(minutes: 1)),
  //       //   ),
  //       // ).then((_) => Navigator.pop(context));
  //       // loadAlarms();
  //       break;
  //     case 'skip':
  //       print('CLICKED SKIP');
  //       // Alarm.stop(alarmSettings.id).then((_) => Navigator.pop(context));
  //       // loadAlarms();
  //       break;
  //     case 'take':
  //       print('CLICKED TAKE');
  //       // Alarm.stop(alarmSettings.id).then((_) => Navigator.pop(context));
  //       // loadAlarms();
  //       break;
  //     default:
  //       print('CLICKED THE NOTIFICATION BODY');
  //       break;
  //   }
  // }

  // static Future<void> onNotificationCreatedMethod(
  //     ReceivedNotification receivedNotification) async {
  //   print('Notification created');
  // }

  // static Future<void> onNotificationDisplayedMethod(
  //     ReceivedNotification receivedNotification) async {
  //   print('Notification displayed');
  // }

  // static Future<void> onDismissActionReceivedMethod(
  //     ReceivedNotification receivedNotification) async {
  //   print('Notification dismissed');
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rafraîchir les alarmes quand on revient sur la page (sauf au premier chargement)
    if (!_isFirstLoad) {
      print('Page resumed - refreshing alarms...');
      setAlarms();
    }
    _isFirstLoad = false;
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  // final alarmSettings = AlarmSettings(
  //   id: 1,
  //   dateTime: DateTime.now(),
  //   assetAudioPath: 'assets/audio/marimba.mp3',
  //   volumeMax: false,
  //   vibrate: false,
  //   notificationTitle: 'Take your medications',
  //   notificationBody: 'This your reminder',
  //   // enableNotificationOnKill: false,
  //   stopOnNotificationOpen: false,
  // );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //app logo and user icon
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //logo and name
                const SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      //logo
                      Image(
                         image: AssetImage('lib/assets/neurocare_logo.png'),
                        height: 65,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                // user icon widget
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const SettingsPageUI();
                            },
                          ),
                        );
                      },
                      // child: currentUser!.photoURL!.isEmpty
                      //     ? CircleAvatar(
                      //         radius: 20,
                      //         backgroundColor:
                      //             Theme.of(context).colorScheme.primary,
                      //         foregroundColor:
                      //             Theme.of(context).colorScheme.surface,
                      //         child: const Icon(Icons.person_outlined),
                      //       )
                      //     : CircleAvatar(
                      //         radius: 20,
                      //         backgroundImage:
                      //             NetworkImage(currentUser!.photoURL!),
                      //         backgroundColor: Colors.transparent,
                      //       ),
                      child: (currentUser?.photoURL?.isEmpty ?? true)
                          ? CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.surface,
                              child: const Icon(Icons.person_outlined),
                            )
                          : CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  NetworkImage(currentUser!.photoURL!),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // calendar, selected date and reminder text widget
          Column(
            children: [
              Container(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: TimelineCalendar(
                    calendarType: CalendarType.GREGORIAN,
                    calendarLanguage: "en",
                    calendarOptions: CalendarOptions(
                      viewType: ViewType.DAILY,
                      toggleViewType: true,
                      headerMonthElevation: 0,
                      headerMonthBackColor:
                          const Color.fromARGB(255, 241, 250, 251),
                    ),
                    dayOptions: DayOptions(
                      compactMode: true,
                      dayFontSize: 18,
                      weekDaySelectedColor:
                          Theme.of(context).colorScheme.primary,
                      selectedBackgroundColor:
                          Theme.of(context).colorScheme.primary,
                      disableDaysBeforeNow: false,
                      unselectedBackgroundColor: Colors.white,
                    ),
                    headerOptions: HeaderOptions(
                      weekDayStringType: WeekDayStringTypes.SHORT,
                      monthStringType: MonthStringTypes.FULL,
                      backgroundColor: const Color.fromARGB(255, 241, 250, 251),
                      headerTextColor: Colors.black,
                    ),
                    onChangeDateTime: (date) {
                      setState(() {
                        _selectedDate.value = date;
                      });
                    },
                    onDateTimeReset: (p0) {
                      setState(() {
                        _selectedDate.value = CalendarDateTime(
                            year: DateTime.now().year,
                            month: DateTime.now().month,
                            day: DateTime.now().day);
                      });
                    },
                    dateTime: _selectedDate.value,
                  ),
                ),
              ),

              //date text and reminder
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //title
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatWeekday(_selectedDate.value),
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: const Color.fromARGB(255, 100, 100, 100),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(_selectedDate.value),
                                style: GoogleFonts.roboto(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (docIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 241, 250, 251),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.medication_outlined,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  '${docIds.length}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    // TextButton(
                    //   onPressed: () async {
                    //     // await Alarm.set(alarmSettings: alarmSettings);
                    //     print('Alarm setted!');
                    //     await AwesomeNotifications().createNotification(
                    //       content: NotificationContent(
                    //         id: 10,
                    //         channelKey: 'basic_channel',
                    //         title: 'Take your medications',
                    //         body: 'Have your taken Vitamin C at 08:00 AM?',
                    //         // color: const Color.fromRGBO(7, 82, 96, 1),
                    //         backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                    //         autoDismissible: false,
                    //         displayOnForeground: true,
                    //         wakeUpScreen: true,
                    //         locked: true,
                    //         notificationLayout: NotificationLayout.Default,
                    //       ),
                    //       actionButtons: [
                    //         NotificationActionButton(
                    //           key: 'skip',
                    //           label: 'Skip',
                    //         ),
                    //         NotificationActionButton(
                    //           key: 'snooze',
                    //           label: 'Snooze',
                    //         ),
                    //         NotificationActionButton(
                    //           key: 'take',
                    //           label: 'Take',
                    //         ),
                    //       ],
                    //     );
                    //   },
                    //   child: const Text('Alarm'),
                    // ),
                    // TextButton(
                    //   onPressed: () {
                    //     AwesomeNotifications().createNotification(
                    //       content: NotificationContent(
                    //         id: 10,
                    //         channelKey: 'basic_channel',
                    //         title: 'Take your medications',
                    //         body: 'Have your taken Vitamin C at 08:00 AM?',
                    //         // color: const Color.fromRGBO(7, 82, 96, 1),
                    //         backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                    //         autoDismissible: false,
                    //         displayOnForeground: true,
                    //         wakeUpScreen: true,
                    //         locked: true,
                    //         notificationLayout: NotificationLayout.Default,
                    //       ),
                    //       actionButtons: [
                    //         NotificationActionButton(
                    //           key: 'skip',
                    //           label: 'Skip',
                    //         ),
                    //         NotificationActionButton(
                    //           key: 'snooze',
                    //           label: 'Snooze',
                    //         ),
                    //         NotificationActionButton(
                    //           key: 'take',
                    //           label: 'Take',
                    //         ),
                    //       ],
                    //     );
                    //   },
                    //   child: const Text('Notify'),
                    // ),
                  ],
                ),
              ),
            ],
          ),

          //timeline widget
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await setAlarms();
                setState(() {});
              },
              color: const Color.fromRGBO(7, 82, 96, 1),
              child: GlowingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                color: const Color.fromARGB(255, 7, 83, 96),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      children: [
                        FutureBuilder(
                          future: getDocIDs(),
                        builder: (context, snapshot) {
                          // print('${snapshot.hasData}');
                          // print(snapshot);
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  const Icon(Icons.error_outline,
                                      size: 50, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading data',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            // print('Building cards');
                            // print('DocID Array Length: ${docIds.length}');
                            if (docIds.isEmpty) {
                              // print('No reminders');
                              //no reminders widget
                              return Column(
                                children: [
                                  const SizedBox(
                                    height: 40,
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.asset(
                                      'lib/assets/icons/no_reminders.gif',
                                      color: const Color.fromARGB(
                                          255, 241, 250, 251),
                                      colorBlendMode: BlendMode.darken,
                                      height: 140.0,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 28,
                                  ),
                                  Text(
                                    translation(context).dashText1,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 28,
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddMedication1(),
                                        ),
                                      );
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                          Color.fromARGB(255, 217, 237, 239)),
                                      foregroundColor: WidgetStatePropertyAll(
                                          Color.fromRGBO(7, 82, 96, 1)),
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(28),
                                          ),
                                        ),
                                      ),
                                      minimumSize: WidgetStatePropertyAll(
                                          Size(double.infinity, 60)),
                                    ),
                                    child: Text(
                                      translation(context).buttonText,
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return ListView.builder(
                                itemCount: docIds.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return ValueListenableBuilder<
                                          CalendarDateTime>(
                                      valueListenable: _selectedDate,
                                      builder: (context, value, child) {
                                        return MedCard(
                                          documentID: docIds[index],
                                          dateID: dateIds[index],
                                          timeID: timeIds[index],
                                          index: index,
                                          size: docIds.length,
                                          selectedDate: value,
                                          refreshCallback: refresh,
                                        );
                                      });
                                },
                              );
                            }
                          } else {
                            return const LinearProgressIndicator();
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
