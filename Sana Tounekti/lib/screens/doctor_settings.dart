import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/cabinet_info_screen.dart';
import 'package:mymeds_app/screens/specialties_screen.dart';
import 'package:mymeds_app/screens/availability_screen.dart';

class DoctorSettings extends StatelessWidget {
  const DoctorSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 0.1),
                  child: Text(
                    (user!.displayName ?? user.email ?? 'D')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(7, 82, 96, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dr. ${user.displayName ?? user.email ?? translation(context).doctorRole}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  translation(context).doctorRole,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Cabinet médical',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.business,
            title: 'Informations du cabinet',
            subtitle: 'Adresse, horaires, téléphone',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CabinetInfoScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.medical_services_outlined,
            title: 'Spécialités',
            subtitle: 'Gérer vos spécialités',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SpecialtiesScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.calendar_month,
            title: 'Disponibilités',
            subtitle: 'Gérer vos horaires de consultation',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AvailabilityScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            translation(context).notificationSettings,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Alertes patients',
            subtitle: 'Configurer les notifications',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: 'Notifications email',
            subtitle: 'Rappels et alertes par email',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            translation(context).accountSection,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title:             translation(context).myProfile,
            subtitle: 'Modifier mes informations',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Sécurité',
            subtitle: 'Mot de passe et authentification',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.payment,
            title: 'Abonnement',
            subtitle: 'Gérer votre abonnement',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            translation(context).supportSection,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: translation(context).helpCenter,
            subtitle: 'FAQ et support technique',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: translation(context).aboutSection,
            subtitle: translation(context).appVersion,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: Text(translation(context).logoutBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(7, 82, 96, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color.fromRGBO(7, 82, 96, 1)),
        ),
        title:
            Text(title, style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: GoogleFonts.roboto(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
