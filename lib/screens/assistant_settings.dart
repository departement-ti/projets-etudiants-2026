import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/screens/account_settings.dart';
import 'package:mymeds_app/screens/emergency.dart';

class AssistantSettings extends StatelessWidget {
  const AssistantSettings({super.key});

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
                    (user!.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(7, 82, 96, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName ?? user.email ?? 'Utilisateur',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Assistant',
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
            'Général',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Gérer les rappels',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.access_time,
            title: 'Historique des alertes',
            subtitle: 'Voir les notifications passées',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.family_restroom,
            title: 'Gérer les patients',
            subtitle: 'Ajouter ou retirer des patients',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            'Compte',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Mon profil',
            subtitle: 'Modifier mes informations',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Compte & Sécurité',
            subtitle: 'Mot de passe, connexion',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPageUI()),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Support',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Centre d\'aide',
            subtitle: 'FAQ et support',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'À propos',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
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
