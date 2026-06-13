import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/account_settings.dart';
import 'package:mymeds_app/screens/alarm_settings.dart';
import 'package:mymeds_app/screens/bmi.dart';
import 'package:mymeds_app/screens/brain_games.dart';
import 'package:mymeds_app/screens/brain_health_dashboard.dart';
import 'package:mymeds_app/screens/daily_activities_screen.dart';
import 'package:mymeds_app/screens/daily_assistant_screen.dart';
import 'package:mymeds_app/screens/emergency.dart';
import 'package:mymeds_app/screens/family_links_screen.dart';
import 'package:mymeds_app/screens/help_center.dart';
import 'package:mymeds_app/screens/set_photo_screen.dart';

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _SettingsState();
}

class _SettingsState extends State<More> {
  Position? _currentPosition;
  //current user
  User? currentUser = FirebaseAuth.instance.currentUser;

  // @override
  // void initState() {
  //   super.initState();
  //   _getCurrentLocation();
  // }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, show a dialog to enable them.
        _showLocationServiceAlertDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // The user has denied access to location permissions.
          print(translation(context).locD);
          return;
        }
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Method to show the dialog to enable location services.
  void _showLocationServiceAlertDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(translation(context).loc),
          content: Text(translation(context).locSe),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                bool serviceEnabled = await Geolocator.openLocationSettings();
                if (serviceEnabled) {
                  // Location services are now enabled, try getting the location again.
                  await _getCurrentLocation();
                }
              },
              child: Text(translation(context).enable),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(translation(context).cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      height: 108,
      child: FilledButton(
        onPressed: onTap,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
              Color.fromARGB(255, 217, 237, 239)),
          foregroundColor: WidgetStatePropertyAll(
              Color.fromRGBO(7, 82, 96, 1)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
          elevation: WidgetStatePropertyAll(2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //app logo and user icon
              Container(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image(
                  image: const AssetImage('lib/assets/icons/more.gif'),
                  height: MediaQuery.of(context).size.height * 0.18,
                  color: const Color.fromARGB(255, 241, 250, 251),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              // Button grid - 2 columns for senior accessibility
              Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMenuButton(context, Icons.image_outlined, translation(context).presImg, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SetPhotoScreen()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuButton(context, Icons.location_on_outlined, translation(context).nearby, () async {
                        await _getCurrentLocation();
                        if (_currentPosition != null) { MapsLauncher.launchQuery(translation(context).nearby); }
                      })),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildMenuButton(context, Icons.health_and_safety_outlined, translation(context).bmi, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BMI()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuButton(context, Icons.alarm_rounded, translation(context).upalarm, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AlarmSettingsPage()));
                      })),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildMenuButton(context, Icons.family_restroom, translation(context).myRelatives, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilyLinksScreen()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuButton(context, Icons.psychology_outlined, translation(context).brainGames, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BrainGamesScreen()));
                      })),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildMenuButton(context, Icons.psychology_outlined, 'Brain Health', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BrainHealthDashboard()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuButton(context, Icons.smart_toy_outlined, translation(context).dailyAssistant, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyAssistantScreen()));
                      })),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildMenuButton(context, Icons.call_outlined, translation(context).emgcall, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const Emergency()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuButton(context, Icons.checklist, translation(context).activities, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyActivitiesScreen()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuButton(context, Icons.person_outlined, translation(context).signOut, () async {
                        await FirebaseAuth.instance.signOut();
                      })),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildMenuButton(context, Icons.settings_outlined, translation(context).settings, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPageUI()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMenuButton(context, Icons.help_outlined, translation(context).helpCenter, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenter()));
                      })),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),

              //3rd ROW

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Column(
              //       mainAxisAlignment: MainAxisAlignment.start,
              //       children: [
              //         Container(
              //           width: 160,
              //           height: 100,
              //           child: ElevatedButton.icon(
              //             onPressed: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) => const SetPhotoScreen(),
              //                 ),
              //               );
              //             },
              //             icon: const Icon(
              //               Icons.account_box,
              //               color: Colors.black,
              //             ),
              //             label: const Text('Profile',
              //                 style: TextStyle(color: Colors.black)),
              //             style: ElevatedButton.styleFrom(
              //                 backgroundColor:
              //                     const Color.fromARGB(255, 254, 37, 37),
              //                 shape: RoundedRectangleBorder(
              //                   borderRadius: BorderRadius.circular(10),
              //                 )),
              //           ),
              //         ),
              //       ],
              //     ),
              //     const SizedBox(
              //       width: 20,
              //     ),
              //     Column(
              //       mainAxisAlignment: MainAxisAlignment.start,
              //       children: [
              //         Container(
              //           width: 160,
              //           height: 100,
              //           child: ElevatedButton.icon(
              //             onPressed: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) => const SetPhotoScreen(),
              //                 ),
              //               );
              //             },
              //             icon: const Icon(
              //               Icons.medical_information,
              //               color: Colors.black,
              //             ),
              //             label: const Text('Medicine',
              //                 style: TextStyle(color: Colors.black)),
              //             style: ElevatedButton.styleFrom(
              //               backgroundColor:
              //                   const Color.fromARGB(255, 68, 243, 255),
              //               shape: RoundedRectangleBorder(
              //                 borderRadius: BorderRadius.circular(10),
              //               ),
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
              // const SizedBox(
              //   width: 40,
              //   height: 30,
              // ),

              // //4th ROW

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Column(
              //       mainAxisAlignment: MainAxisAlignment.start,
              //       children: [
              //         Container(
              //           width: 160,
              //           height: 100,
              //           child: ElevatedButton.icon(
              //             onPressed: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) => const SetPhotoScreen(),
              //                 ),
              //               );
              //             },
              //             icon: const Icon(
              //               Icons.history,
              //               color: Colors.black,
              //             ),
              //             label: const Text('History',
              //                 style: TextStyle(color: Colors.black)),
              //             style: ElevatedButton.styleFrom(
              //                 backgroundColor:
              //                     const Color.fromARGB(255, 255, 136, 0),
              //                 shape: RoundedRectangleBorder(
              //                   borderRadius: BorderRadius.circular(10),
              //                 )),
              //           ),
              //         ),
              //       ],
              //     ),
              //     const SizedBox(
              //       width: 20,
              //     ),
              //     Column(
              //       mainAxisAlignment: MainAxisAlignment.start,
              //       children: [
              //         Container(
              //           width: 160,
              //           height: 100,
              //           child: ElevatedButton.icon(
              //             onPressed: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (context) => const SetPhotoScreen(),
              //                 ),
              //               );
              //             },
              //             icon: const Icon(
              //               Icons.food_bank,
              //               color: Colors.black,
              //             ),
              //             label: const Text('Foods',
              //                 style: TextStyle(color: Colors.black)),
              //             style: ElevatedButton.styleFrom(
              //               backgroundColor:
              //                   const Color.fromARGB(255, 152, 0, 246),
              //               shape: RoundedRectangleBorder(
              //                 borderRadius: BorderRadius.circular(10),
              //               ),
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
