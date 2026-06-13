import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final String patientEmail;
  final String patientName;
  final String doctorEmail;

  const CreatePrescriptionScreen({
    super.key,
    required this.patientEmail,
    required this.patientName,
    required this.doctorEmail,
  });

  @override
  State<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, String>> _medications = [];

  void _addMedication() {
    if (_medicationController.text.isNotEmpty &&
        _dosageController.text.isNotEmpty) {
      setState(() {
        _medications.add({
          'name': _medicationController.text,
          'dosage': _dosageController.text,
        });
        _medicationController.clear();
        _dosageController.clear();
      });
    }
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    final t = translation(context);
    if (!_formKey.currentState!.validate()) return;
    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.addAtLeastOneMedication)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prescriptionRef =
          await FirebaseFirestore.instance.collection('Prescriptions').add({
        'doctorEmail': widget.doctorEmail,
        'patientEmail': widget.patientEmail,
        'patientName': widget.patientName,
        'title': _titleController.text,
        'instructions': _instructionsController.text,
        'duration': _durationController.text,
        'medications': _medications,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'active',
      });

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.patientEmail)
          .collection('Prescriptions')
          .doc(prescriptionRef.id)
          .set({
        'prescriptionId': prescriptionRef.id,
        'doctorEmail': widget.doctorEmail,
        'title': _titleController.text,
        'medications': _medications,
        'instructions': _instructionsController.text,
        'duration': _durationController.text,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.prescriptionCreated)),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorOccurred}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.newPrescription,
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(7, 82, 96, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person,
                        color: Color.fromRGBO(7, 82, 96, 1)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.patient,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.patientName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.prescriptionTitle,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: t.treatmentDurationHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.enterTitle;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                t.medications,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _medicationController,
                      decoration: InputDecoration(
                        hintText: t.medicationName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        hintText: t.dosage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addMedication,
                    icon: const Icon(Icons.add_circle),
                    color: const Color.fromRGBO(7, 82, 96, 1),
                    iconSize: 36,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_medications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      t.addMedication,
                      style: GoogleFonts.roboto(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...(_medications.asMap().entries.map((entry) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(7, 82, 96, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: Color.fromRGBO(7, 82, 96, 1),
                          ),
                        ),
                        title: Text(entry.value['name'] ?? ''),
                        subtitle: Text('${t.dosage}: ${entry.value['dosage']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeMedication(entry.key),
                        ),
                      ),
                    ))),
              const SizedBox(height: 24),
              Text(
                t.treatmentDuration,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  hintText: t.treatmentDurationHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.instructions,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instructionsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: t.instructionsHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _savePrescription,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(t.createPrescriptionBtn),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
