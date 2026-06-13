import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/patient_prescriptions_screen.dart';
import 'package:mymeds_app/screens/doctor_reports_screen.dart';

class FamilyLinksScreen extends StatefulWidget {
  const FamilyLinksScreen({super.key});

  @override
  State<FamilyLinksScreen> createState() => _FamilyLinksScreenState();
}

class _FamilyLinksScreenState extends State<FamilyLinksScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _linkedFamily = [];
  List<Map<String, dynamic>> _pendingInvitations = [];
  List<Map<String, dynamic>> _pendingDoctorRequests = [];
  List<Map<String, dynamic>> _linkedDoctors = [];
  bool _isLoading = true;
  bool _isInviting = false;

  Future<void> _ensureUserDocumentExists() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.email)
        .get();

    if (!userDoc.exists) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .set({
        'name': user!.displayName ?? '',
        'email': user!.email,
        'role': 'personneAge',
        'linkedFamilyEmails': [],
        'pendingInvitations': [],
        'linkedPatientsEmails': [],
        'pendingPatientRequests': [],
        'linkedDoctorEmails': [],
        'pendingDoctorRequests': [],
        'pendingDoctorInvitations': [],
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureUserDocumentExists().then((_) => _loadFamilyLinks());
  }

  Future<void> _loadFamilyLinks() async {
    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .get();

      final data = userDoc.data() as Map<String, dynamic>?;

      // Charger les proches
      final linkedFamilyEmails =
          List<String>.from(data?['linkedFamilyEmails'] ?? []);
      final pendingFamilyEmails =
          List<String>.from(data?['pendingInvitations'] ?? []);

      // Charger les médecins
      final linkedDoctorEmails =
          List<String>.from(data?['linkedDoctorEmails'] ?? []);
      final pendingDoctorEmails =
          List<String>.from(data?['pendingDoctorRequests'] ?? []);

      List<Map<String, dynamic>> linkedFamily = [];
      List<Map<String, dynamic>> pendingFamily = [];
      List<Map<String, dynamic>> linkedDoctors = [];
      List<Map<String, dynamic>> pendingDoctors = [];

      // Charger les proches liés
      for (final email in linkedFamilyEmails) {
        final familyDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(email)
            .get();
        if (familyDoc.exists) {
          linkedFamily.add({
            'email': email,
            ...familyDoc.data()!,
          });
        }
      }

      // Charger les proches en attente
      for (final email in pendingFamilyEmails) {
        pendingFamily.add({'email': email});
      }

      // Charger les médecins liés
      for (final email in linkedDoctorEmails) {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(email)
            .get();
        if (doctorDoc.exists) {
          linkedDoctors.add({
            'email': email,
            ...doctorDoc.data()!,
          });
        }
      }

      // Charger les demandes de médecins en attente
      for (final email in pendingDoctorEmails) {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(email)
            .get();
        if (doctorDoc.exists) {
          pendingDoctors.add({
            'email': email,
            'name': doctorDoc.data()?['name'] ?? email,
          });
        } else {
          pendingDoctors.add({'email': email, 'name': email});
        }
      }

      setState(() {
        _linkedFamily = linkedFamily;
        _pendingInvitations = pendingFamily;
        _linkedDoctors = linkedDoctors;
        _pendingDoctorRequests = pendingDoctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showInviteDialog() {
    final t = translation(context);
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          t.inviteFamily,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez l\'email de la personne que vous souhaitez inviter à suivre vos médicaments.',
              style: GoogleFonts.roboto(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'proche@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: _isInviting
                ? null
                : () async {
                    if (emailController.text.trim().isNotEmpty) {
                      await _sendInvitation(emailController.text.trim());
                      Navigator.pop(context);
                    }
                  },
            child: _isInviting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.sendRequest),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvitation(String email) async {
    final t = translation(context);
    if (email == user!.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.other} cannot invite themselves')),
      );
      return;
    }

    setState(() => _isInviting = true);

    try {
      final targetDoc =
          await FirebaseFirestore.instance.collection('Users').doc(email).get();

      if (!targetDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.requestFailed)),
        );
        setState(() => _isInviting = false);
        return;
      }

      final targetData = targetDoc.data() as Map<String, dynamic>;
      if (targetData['role'] != 'assistant' && targetData['role'] != 'membreFamille') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.requestFailed)),
        );
        setState(() => _isInviting = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .update({
        'pendingInvitations': FieldValue.arrayUnion([email]),
      });

      await FirebaseFirestore.instance.collection('Users').doc(email).update({
        'pendingPatientRequests': FieldValue.arrayUnion([user!.email]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.invitationSent} $email')),
      );

      await _loadFamilyLinks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorOccurred}: $e')),
      );
    } finally {
      setState(() => _isInviting = false);
    }
  }

  Future<void> _removeFamilyMember(String email) async {
    final t = translation(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          t.reject,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Voulez-vous vraiment retirer $email de vos proches ?',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.reject),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.email)
            .update({
          'linkedFamilyEmails': FieldValue.arrayRemove([email]),
        });

        await FirebaseFirestore.instance.collection('Users').doc(email).update({
          'linkedPatientsEmails': FieldValue.arrayRemove([user!.email]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proche retiré avec succès')),
        );

        await _loadFamilyLinks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.errorOccurred}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.myLinks,
          style: GoogleFonts.poppins(
            color: const Color.fromRGBO(7, 82, 96, 1),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 242, 253, 255),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color.fromRGBO(7, 82, 96, 1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFamilyLinks,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMedicalActions(),
                    const SizedBox(height: 24),
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildPendingDoctorRequests(),
                    const SizedBox(height: 24),
                    _buildLinkedDoctors(),
                    const SizedBox(height: 24),
                    _buildLinkedFamily(),
                    const SizedBox(height: 24),
                    _buildPendingInvitations(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        icon: const Icon(Icons.person_add),
        label: Text(t.inviteFamily),
      ),
    );
  }

  Widget _buildInfoCard() {
    final t = translation(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(7, 82, 96, 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color.fromRGBO(7, 82, 96, 1)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Invitez vos proches à suivre vos médicaments. Ils recevront des alertes quand vous devez prendre vos traitements.',
              style: GoogleFonts.roboto(
                color: const Color.fromRGBO(7, 82, 96, 1),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalActions() {
    final t = translation(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mon espace médical',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.description,
                label: t.prescriptions,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientPrescriptionsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.assignment,
                label: t.medicalReports,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorReportsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedFamily() {
    final t = translation(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t.familyMembers} (${_linkedFamily.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        const SizedBox(height: 12),
        if (_linkedFamily.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      t.noFamilyMembers,
                      style: GoogleFonts.roboto(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Appuyez sur le bouton ci-dessous pour inviter un proche',
                      style: GoogleFonts.roboto(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_linkedFamily.map((member) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(7, 82, 96, 0.1),
                    child: Text(
                      (member['name']?.isNotEmpty == true
                              ? member['name']![0]
                              : 'P')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Color.fromRGBO(7, 82, 96, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(member['name'] ?? member['email']),
                  subtitle: Text(member['email']),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(t.reject),
                          ],
                        ),
                        onTap: () => _removeFamilyMember(member['email']),
                      ),
                    ],
                  ),
                ),
              ))),
      ],
    );
  }

  Widget _buildPendingInvitations() {
    final t = translation(context);
    if (_pendingInvitations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t.pending} (${_pendingInvitations.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 12),
        ...(_pendingInvitations.map((invitation) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.orange.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child:
                      const Icon(Icons.hourglass_empty, color: Colors.orange),
                ),
                title: Text(invitation['email']),
                subtitle: Text(t.pending),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  onPressed: () async {
                    final targetEmail = invitation['email'];
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user!.email)
                        .update({
                      'pendingInvitations':
                          FieldValue.arrayRemove([targetEmail]),
                    });
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(targetEmail)
                        .update({
                      'pendingPatientRequests':
                          FieldValue.arrayRemove([user!.email]),
                    });
                    await _loadFamilyLinks();
                  },
                ),
              ),
            ))),
      ],
    );
  }

  Widget _buildPendingDoctorRequests() {
    final t = translation(context);
    if (_pendingDoctorRequests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t.doctorRequests} (${_pendingDoctorRequests.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 12),
        ...(_pendingDoctorRequests.map((request) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.purple.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child:
                      const Icon(Icons.medical_services, color: Colors.purple),
                ),
                title: Text(request['name'] ?? request['email']),
                subtitle: Text(request['email']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _acceptDoctorRequest(request['email']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectDoctorRequest(request['email']),
                    ),
                  ],
                ),
              ),
            ))),
      ],
    );
  }

  Widget _buildLinkedDoctors() {
    final t = translation(context);
    if (_linkedDoctors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t.myDoctors} (${_linkedDoctors.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
        const SizedBox(height: 12),
        ...(_linkedDoctors.map((doctor) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 0.1),
                  child: Text(
                    (doctor['name']?.isNotEmpty == true
                            ? doctor['name']![0]
                            : 'D')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Color.fromRGBO(7, 82, 96, 1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(doctor['name'] ?? 'Docteur'),
                subtitle: Text(doctor['email']),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: () => _removeDoctor(doctor['email']),
                ),
              ),
            ))),
      ],
    );
  }

  Future<void> _acceptDoctorRequest(String doctorEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .update({
        'linkedDoctorEmails': FieldValue.arrayUnion([doctorEmail]),
        'pendingDoctorRequests': FieldValue.arrayRemove([doctorEmail]),
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(doctorEmail)
          .update({
        'linkedPatientsEmails': FieldValue.arrayUnion([user!.email]),
        'pendingDoctorInvitations': FieldValue.arrayRemove([user!.email]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Médecin lié avec succès!')),
      );

      await _loadFamilyLinks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _rejectDoctorRequest(String doctorEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .update({
        'pendingDoctorRequests': FieldValue.arrayRemove([doctorEmail]),
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(doctorEmail)
          .update({
        'pendingDoctorInvitations': FieldValue.arrayRemove([user!.email]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande refusée')),
      );

      await _loadFamilyLinks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _removeDoctor(String doctorEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Retirer ce médecin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Voulez-vous vraiment retirer ce médecin?',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.email)
            .update({
          'linkedDoctorEmails': FieldValue.arrayRemove([doctorEmail]),
        });

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(doctorEmail)
            .update({
          'linkedPatientsEmails': FieldValue.arrayRemove([user!.email]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Médecin retiré avec succès')),
        );

        await _loadFamilyLinks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
