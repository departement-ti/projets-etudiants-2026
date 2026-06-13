import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/l10n/app_localizations.dart';
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
import 'package:mymeds_app/screens/patient_documents_screen.dart';
import 'package:mymeds_app/screens/patient_recommendations_screen.dart';
import 'package:mymeds_app/services/talkback_service.dart';

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _SettingsState();
}

class _SettingsState extends State<More> {
  final TalkbackService _talkback = TalkbackService();
  Position? _currentPosition;
  User? currentUser = FirebaseAuth.instance.currentUser;
  String _userName = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (currentUser?.email == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? '';
          _userRole = data['role'] ?? '';
        });
      }
    } catch (_) {}
  }

  String _localizedRole(String role) {
    final t = translation(context);
    switch (role) {
      case 'personneAge': return t.patientRole;
      case 'doctor': return t.doctorRole;
      case 'assistant':
      case 'membreFamille': return t.assistantRole;
      default: return role;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceAlertDialog();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() => _currentPosition = position);
      }
    } catch (_) {}
  }

  void _showLocationServiceAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translation(context).loc),
        content: Text(translation(context).locSe),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool serviceEnabled = await Geolocator.openLocationSettings();
              if (serviceEnabled) await _getCurrentLocation();
            },
            child: Text(translation(context).enable),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translation(context).cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(t.health, Icons.favorite_outline),
                    _buildMenuGrid([
                      _MenuItem(Icons.psychology_outlined, t.brainHealth, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrainHealthDashboard()))),
                      _MenuItem(Icons.psychology, t.brainGames, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrainGamesScreen()))),
                      _MenuItem(Icons.health_and_safety_outlined, t.bmi, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BMI()))),
                      _MenuItem(Icons.checklist, t.activities, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyActivitiesScreen()))),
                      _MenuItem(Icons.smart_toy_outlined, t.dailyAssistant, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyAssistantScreen()))),
                      _MenuItem(Icons.recommend, translation(context).medicalRecommendations, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientRecommendationsScreen()))),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle(t.safety, Icons.shield_outlined),
                    _buildMenuGrid([
                      _MenuItem(Icons.call_outlined, t.emgcall, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Emergency()))),
                      _MenuItem(Icons.family_restroom, t.myRelatives, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyLinksScreen()))),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle(t.tools, Icons.build_outlined),
                    _buildMenuGrid([
                      _MenuItem(Icons.description_outlined, t.myDocuments, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientDocumentsScreen()))),
                      _MenuItem(Icons.alarm_rounded, t.upalarm, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmSettingsPage()))),
                      _MenuItem(Icons.location_on_outlined, t.nearby, () async {
                        await _getCurrentLocation();
                        if (_currentPosition != null) {
                          MapsLauncher.launchQuery(t.nearby);
                        }
                      }),
                    ]),
                    const SizedBox(height: 24),
                    _buildTalkbackTile(t, _talkback),
                    const SizedBox(height: 24),
                    _buildSectionTitle(t.settings, Icons.tune_outlined),
                    _buildMenuGrid([
                      _MenuItem(Icons.settings_outlined, t.settings, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPageUI()))),
                      _MenuItem(Icons.help_outlined, t.helpCenter, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenter()))),
                      _MenuItem(Icons.logout, t.signOut, () async {
                        await FirebaseAuth.instance.signOut();
                      }, isDestructive: true),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final t = translation(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B5EA6), Color(0xFF7B6FB0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPageUI())),
                  child: (currentUser?.photoURL?.isEmpty ?? true)
                      ? CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withAlpha(50),
                          child: const Icon(Icons.person, size: 36, color: Colors.white),
                        )
                      : CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(currentUser!.photoURL!),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty ? _userName : t.user,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.email ?? '',
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.white70),
                      ),
                      if (_userRole.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _localizedRole(_userRole),
                            style: GoogleFonts.roboto(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5B5EA6)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5B5EA6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(List<_MenuItem> items) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            height: 64,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              shadowColor: const Color(0xFF5B5EA6).withAlpha(20),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.isDestructive
                              ? Colors.red.withAlpha(20)
                              : const Color(0xFF5B5EA6).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.isDestructive ? Colors.red : const Color(0xFF5B5EA6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: item.isDestructive ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: item.isDestructive ? Colors.red.withAlpha(100) : Colors.grey[400],
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTalkbackTile(AppLocalizations t, TalkbackService talkback) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 64,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 1,
          shadowColor: const Color(0xFF5B5EA6).withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5EA6).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volume_up_outlined,
                    color: Color(0xFF5B5EA6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.talkback,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        t.talkbackDesc,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: talkback.isEnabled,
                  activeColor: const Color(0xFF5B5EA6),
                  onChanged: (val) {
                    setState(() {
                      talkback.setEnabled(val);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? t.talkbackEnabled : t.talkbackDisabled),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  _MenuItem(this.icon, this.label, this.onTap, {this.isDestructive = false});
}
