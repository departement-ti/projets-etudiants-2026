import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/account_settings.dart';
import 'package:mymeds_app/screens/add_medication1.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:week_of_year/week_of_year.dart';

class Statistic extends StatefulWidget {
  const Statistic({super.key});

  @override
  State<Statistic> createState() => _StatisticState();
}

class _StatisticState extends State<Statistic> {
  //current user
  User? currentUser = FirebaseAuth.instance.currentUser;
  late int taken = 0;
  late int missed = 0;
  late int maximum = 0;
  late int interval = 1;

  late bool isDailyEmpty = false;
  late bool isWeekyEmpty = false;

  late List<GDPData> _chartData;
  late List<_ChartDataW> data;
  late TooltipBehavior _tooltip;
  late Color takenColor; // Color for the "Taken" series
  late Color missedColor; // Color for the "Missed" series

  late Future<void> _dailyUsageFuture;

  @override
  void initState() {
    super.initState();
    _dailyUsageFuture = getDailyUsage();
    _tooltip = TooltipBehavior(enable: true);
    missedColor = const Color.fromARGB(255, 6, 129, 151);
    takenColor = const Color.fromARGB(255, 183, 197, 200);
  }

  Future getDailyUsage() async {
    _chartData = [];
    taken = 0;
    missed = 0;

    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.email)
        .collection('Medications')
        .get(const GetOptions(source: Source.serverAndCache));

    for (final document in snapshot.docs) {
      final snapshot1 = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .collection('Medications')
          .doc(document.reference.id)
          .collection('Logs')
          .get(const GetOptions(source: Source.serverAndCache));

      for (final document1 in snapshot1.docs) {
        // print('Date ID: ${document1.reference.id}');
        List<String> dateTime = document1.reference.id.split(' ');
        //check today
        List<String> date = dateTime[0].split('-');
        int year = int.parse(date[0]);
        int month = int.parse(date[1]);
        int day = int.parse(date[2]);
        final now = DateTime.now();

        if (DateTime(year, month, day) ==
            DateTime(now.year, now.month, now.day)) {
          final snapshot2 = await FirebaseFirestore.instance
              .collection('Users')
              .doc(currentUser!.email)
              .collection('Medications')
              .doc(document.reference.id)
              .collection('Logs')
              .doc(document1.reference.id)
              .get(const GetOptions(source: Source.serverAndCache));

          Map<String, dynamic>? logData = snapshot2.data() != null
              ? snapshot2.data() as Map<String, dynamic>
              : <String, dynamic>{};
          bool? isTaken = logData['isTaken'];
          if (isTaken!) {
            taken++;
          } else {
            missed++;
          }
        }
      }
    }
    _chartData = [
      GDPData('Taken', taken),
      GDPData('Skipped', missed),
    ];

    if (taken == 0 && missed == 0) {
      setState(() {
        isDailyEmpty = true;
      });
    }
  }

  Future getWeeklyUsage() async {
    data = [];
    int max = 0;
    maximum = 0;
    interval = 1;

    int monTaken = 0;
    int monMissed = 0;

    int tueTaken = 0;
    int tueMissed = 0;

    int wedTaken = 0;
    int wedMissed = 0;

    int thuTaken = 0;
    int thuMissed = 0;

    int friTaken = 0;
    int friMissed = 0;

    int satTaken = 0;
    int satMissed = 0;

    int sunTaken = 0;
    int sunMissed = 0;

    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.email)
        .collection('Medications')
        .get(const GetOptions(source: Source.serverAndCache));

    for (final document in snapshot.docs) {
      final snapshot1 = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .collection('Medications')
          .doc(document.reference.id)
          .collection('Logs')
          .get(const GetOptions(source: Source.serverAndCache));

      for (final document1 in snapshot1.docs) {
        // print('Date ID: ${document1.reference.id}');
        List<String> dateTime = document1.reference.id.split(' ');
        if (dateTime.isEmpty) continue;
        //check today
        List<String> date = dateTime[0].split('-');
        if (date.length < 3) continue;
        int year = int.parse(date[0]);
        int month = int.parse(date[1]);
        int day = int.parse(date[2]);
        final dbDate = DateTime(year, month, day);
        int weekday = dbDate.weekday;

        final now = DateTime.now();
        final currentWeek = now.weekOfYear;
        Duration difference = dbDate.difference(DateTime.now());
        print('Difference: $difference');

        if ((dbDate.weekOfYear == currentWeek) && difference.isNegative) {
          final snapshot2 = await FirebaseFirestore.instance
              .collection('Users')
              .doc(currentUser!.email)
              .collection('Medications')
              .doc(document.reference.id)
              .collection('Logs')
              .doc(document1.reference.id)
              .get(const GetOptions(source: Source.serverAndCache));

          Map<String, dynamic>? logData = snapshot2.data() != null
              ? snapshot2.data() as Map<String, dynamic>
              : <String, dynamic>{};
          bool? isTaken = logData['isTaken'];

          switch (weekday) {
            case 1: // Monday
              if (isTaken!) {
                monTaken++;
              } else {
                monMissed++;
              }
              break;
            case 2: // Tuesday
              if (isTaken!) {
                tueTaken++;
              } else {
                tueMissed++;
              }
              break;
            case 3: // Wednesday
              if (isTaken!) {
                wedTaken++;
              } else {
                wedMissed++;
              }
              break;
            case 4: // Thursday
              if (isTaken!) {
                thuTaken++;
              } else {
                thuMissed++;
              }
              break;
            case 5: // Friday
              if (isTaken!) {
                friTaken++;
              } else {
                friMissed++;
              }
              break;
            case 6: // Saturday
              if (isTaken!) {
                satTaken++;
              } else {
                satMissed++;
              }
              break;
            case 7: // Sunday
              if (isTaken!) {
                sunTaken++;
              } else {
                sunMissed++;
              }
              break;
            default:
              print("Invalid weekday!");
              break;
          }

          if (monTaken > max) {
            max = monTaken;
          } else if (monMissed > max) {
            max = monMissed;
          }

          if (tueTaken > max) {
            max = tueTaken;
          } else if (tueMissed > max) {
            max = tueMissed;
          }

          if (wedTaken > max) {
            max = wedTaken;
          } else if (wedMissed > max) {
            max = wedMissed;
          }

          if (thuTaken > max) {
            max = thuTaken;
          } else if (thuMissed > max) {
            max = thuMissed;
          }

          if (friTaken > max) {
            max = friTaken;
          } else if (friMissed > max) {
            max = friMissed;
          }

          if (satTaken > max) {
            max = satTaken;
          } else if (satMissed > max) {
            max = satMissed;
          }

          if (sunTaken > max) {
            max = sunTaken;
          } else if (sunMissed > max) {
            max = sunMissed;
          }
        }
      }
    }
    data = [
      _ChartDataW('MON', monTaken.toDouble(), monMissed.toDouble()),
      _ChartDataW('TUE', tueTaken.toDouble(), tueMissed.toDouble()),
      _ChartDataW('WED', wedTaken.toDouble(), wedMissed.toDouble()),
      _ChartDataW('THU', thuTaken.toDouble(), thuMissed.toDouble()),
      _ChartDataW('FRI', friTaken.toDouble(), friMissed.toDouble()),
      _ChartDataW('SAT', satTaken.toDouble(), satMissed.toDouble()),
      _ChartDataW('SUN', sunTaken.toDouble(), sunMissed.toDouble()),
    ];

    interval = determineInterval(max);
    maximum = calculateLeastMaxY(max, interval);

    if (max == 0) {
      setState(() {
        isWeekyEmpty = true;
      });
    }
  }

  int determineInterval(int maxYValue) {
    if (maxYValue <= 0) return 1;
    const maxTickCount = 3;

    int interval = (maxYValue / maxTickCount).ceil();
    if (interval <= 0) interval = 1;

    if (interval % 2 != 0) {
      interval += 2 - (interval % 2);
    }

    return interval > 0 ? interval : 1;
  }

  int calculateLeastMaxY(int maxYValue, int interval) {
    if (interval <= 0) interval = 1;
    return ((maxYValue ~/ interval) + 1) * interval;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            //app logo and user icon
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //logo and name
                    const Column(
                      children: [
                        //logo
                        Image(
                           image: AssetImage('lib/assets/neurocare_logo.png'),
                          height: 65,
                        ),
                        //app name
                        // Text(
                        //   'MyMeds',
                        //   style: GoogleFonts.poppins(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.w600,
                        //     color: const Color.fromRGBO(7, 82, 96, 1),
                        //   ),
                        // ),
                      ],
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
            ),
            Expanded(
              child: GlowingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                color: const Color.fromARGB(255, 7, 83, 96),
                child: SingleChildScrollView(
                  physics: const ScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        translation(context).today,
                        style: GoogleFonts.roboto(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 16, 15, 15),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),

                      FutureBuilder(
                        future: _dailyUsageFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            // return Text('Taken: $taken, Missed: $missed');
                            return !isDailyEmpty
                                ? SfCircularChart(
                                    legend: const Legend(
                                      isVisible: true,
                                      alignment: ChartAlignment.center,
                                      position: LegendPosition.bottom,
                                      overflowMode: LegendItemOverflowMode.wrap,
                                    ),
                                    series: <CircularSeries>[
                                      DoughnutSeries<GDPData, String>(
                                        dataSource: _chartData,
                                        xValueMapper: (GDPData data, _) =>
                                            data.type,
                                        yValueMapper: (GDPData data, _) =>
                                            data.amount,
                                        dataLabelSettings:
                                            const DataLabelSettings(
                                          isVisible: true,
                                          labelPosition:
                                              ChartDataLabelPosition.inside,
                                          labelAlignment:
                                              ChartDataLabelAlignment.top,
                                          useSeriesColor: true,
                                        ),
                                        enableTooltip: true, // Enable tooltips
                                        pointColorMapper: (GDPData data, _) {
                                          if (data.type == 'Taken') {
                                            return takenColor;
                                          } else {
                                            return missedColor;
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Image.asset(
                                            'lib/assets/icons/pills.gif',
                                            color: const Color.fromARGB(
                                                255, 7, 82, 96),
                                            colorBlendMode: BlendMode.srcIn,
                                            height: 100.0,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Text(
                                          'Your daily medication usage\n will be displayed here',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.roboto(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                          }
                          return const CircularProgressIndicator();
                        },
                      ),

                      // const SizedBox(
                      //   height: 20,
                      // ),
                      // FilledButton(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => AddMedication1(),
                      //       ),
                      //     );
                      //   },
                      //   style: const ButtonStyle(
                      //     backgroundColor: MaterialStatePropertyAll(
                      //         Color.fromARGB(255, 217, 237, 239)),
                      //     foregroundColor: MaterialStatePropertyAll(
                      //         Color.fromRGBO(7, 82, 96, 1)),
                      //     shape: MaterialStatePropertyAll(
                      //       RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.all(
                      //           Radius.circular(20),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      //   child: Text(
                      //     'Add a medication',
                      //     style: GoogleFonts.roboto(
                      //       fontWeight: FontWeight.w600,
                      //       fontSize: 16,
                      //     ),
                      //   ),
                      // ),

                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        translation(context).thisWeek,
                        style: GoogleFonts.roboto(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 16, 15, 15),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),

                      FutureBuilder(
                        future: getWeeklyUsage(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return !isWeekyEmpty
                                ? Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    child: SfCartesianChart(
                                      legend: const Legend(
                                        isVisible: true,
                                        overflowMode:
                                            LegendItemOverflowMode.wrap,
                                        alignment: ChartAlignment.center,
                                        position: LegendPosition.bottom,
                                        itemPadding: 30,
                                      ),
                                      primaryXAxis: CategoryAxis(),
                                      primaryYAxis: NumericAxis(
                                          minimum: 0,
                                          maximum: maximum > 0
                                              ? maximum.toDouble()
                                              : 10,
                                          interval: interval > 0
                                              ? interval.toDouble()
                                              : 1),
                                      tooltipBehavior: _tooltip,
                                      series: <CartesianSeries<dynamic,
                                          dynamic>>[
                                        ColumnSeries<_ChartDataW, String>(
                                          dataSource: data,
                                          xValueMapper: (_ChartDataW data, _) =>
                                              data.x,
                                          yValueMapper: (_ChartDataW data, _) =>
                                              data.y,
                                          name: 'Taken',
                                          color:
                                              takenColor, // Use the same color here
                                        ),
                                        ColumnSeries<_ChartDataW, String>(
                                          dataSource: data,
                                          xValueMapper: (_ChartDataW data, _) =>
                                              data.x,
                                          yValueMapper: (_ChartDataW data, _) =>
                                              data.y1,
                                          name: 'Skipped',
                                          color:
                                              missedColor, // Use the same color here
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: Image.asset(
                                            'lib/assets/icons/bar-chart.gif',
                                            color: const Color.fromARGB(
                                                255, 241, 250, 251),
                                            colorBlendMode: BlendMode.darken,
                                            height: 100.0,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Text(
                                          'Your weekly medication usage\n will be displayed here',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.roboto(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
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
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    Color.fromARGB(
                                                        255, 217, 237, 239)),
                                            foregroundColor:
                                                WidgetStatePropertyAll(
                                                    Color.fromRGBO(
                                                        7, 82, 96, 1)),
                                            shape: WidgetStatePropertyAll(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(28),
                                                ),
                                              ),
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                                Size(double.infinity, 56)),
                                          ),
                                          child: Text(
                                            'Add a medication',
                                            style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                          }
                          return const CircularProgressIndicator();
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),

            // SfCircularChart(
            //   title: ChartTitle(
            //     text: 'Daily Dosage Usage',
            //     textStyle: const TextStyle(fontSize: 15),
            //   ),
            //   legend: const Legend(
            //     isVisible: true,
            //     alignment: ChartAlignment.center,
            //     position: LegendPosition.bottom,
            //     overflowMode: LegendItemOverflowMode.wrap,
            //   ),
            //   series: <CircularSeries>[
            //     DoughnutSeries<GDPData, String>(
            //       dataSource: _chartData,
            //       xValueMapper: (GDPData data, _) => data.type,
            //       yValueMapper: (GDPData data, _) => data.amount,
            //       dataLabelSettings: const DataLabelSettings(
            //         isVisible: true,
            //         labelPosition: ChartDataLabelPosition.inside,
            //         labelAlignment: ChartDataLabelAlignment.top,
            //         useSeriesColor: true,
            //       ),
            //       enableTooltip: true, // Enable tooltips
            //       pointColorMapper: (GDPData data, _) {
            //         if (data.type == 'Taken') {
            //           return takenColor;
            //         } else {
            //           return missedColor;
            //         }
            //       },
            //     ),
            //   ],
            // ),

            // SfCartesianChart(
            //   legend: const Legend(
            //     isVisible: true,
            //     overflowMode: LegendItemOverflowMode.wrap,
            //     alignment: ChartAlignment.center,
            //     position: LegendPosition.bottom,
            //     itemPadding: 30,
            //   ),
            //   primaryXAxis: CategoryAxis(),
            //   primaryYAxis: NumericAxis(minimum: 0, maximum: 18, interval: 5),
            //   tooltipBehavior: _tooltip,
            //   series: <ChartSeries<_ChartDataW, String>>[
            //     ColumnSeries<_ChartDataW, String>(
            //       dataSource: data,
            //       xValueMapper: (_ChartDataW data, _) => data.x,
            //       yValueMapper: (_ChartDataW data, _) => data.y,
            //       name: 'Taken',
            //       color: takenColor, // Use the same color here
            //     ),
            //     ColumnSeries<_ChartDataW, String>(
            //       dataSource: data,
            //       xValueMapper: (_ChartDataW data, _) => data.x,
            //       yValueMapper: (_ChartDataW data, _) => data.y1,
            //       name: 'Skipped',
            //       color: missedColor, // Use the same color here
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  // List<GDPData> getChartData() {
  //   List<GDPData> chartData = [
  //     GDPData('Taken', 10),
  //     GDPData('Missed', 5),
  //   ];
  //   return chartData;
  // }

  // List<_ChartDataW> getChartDataW() {
  //   final List<_ChartDataW> data = [
  //     _ChartDataW('MON', 12, 5),
  //     _ChartDataW('TUE', 15, 4),
  //     _ChartDataW('WED', 10, 5),
  //     _ChartDataW('THU', 8, 2),
  //     _ChartDataW('FRI', 14, 3),
  //     _ChartDataW('SAT', 12, 8),
  //     _ChartDataW('SUN', 15, 6),
  //   ];
  //   return data;
  // }
}

class GDPData {
  GDPData(this.type, this.amount);
  final String type;
  final int amount;
}

class _ChartDataW {
  _ChartDataW(this.x, this.y, this.y1);
  final String x;
  final double y;
  final double y1;
}
