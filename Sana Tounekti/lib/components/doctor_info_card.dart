import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorInfoCard extends StatelessWidget {
  final Map<String, dynamic> doctorData;

  const DoctorInfoCard({super.key, required this.doctorData});

  @override
  Widget build(BuildContext context) {
    final cabinetName = doctorData['cabinetName'] as String?;
    final cabinetAddress = doctorData['cabinetAddress'] as String?;
    final cabinetPhone = doctorData['cabinetPhone'] as String?;
    final cabinetHours = doctorData['cabinetHours'] as String?;
    final specialties = List<String>.from(doctorData['specialties'] ?? []);
    final availability = doctorData['availability'] as Map<String, dynamic>?;

    final hasCabinetInfo =
        cabinetName != null && cabinetName.isNotEmpty;
    final hasSpecialties = specialties.isNotEmpty;
    final hasAvailability = availability != null && availability.values.any(
          (v) => v != null && (v as Map)['start'] != null,
    );

    if (!hasCabinetInfo && !hasSpecialties && !hasAvailability) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(7, 82, 96, 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCabinetInfo) ...[
            _buildInfoRow(Icons.business, cabinetName),
            if (cabinetAddress != null && cabinetAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildInfoRow(Icons.location_on, cabinetAddress),
              ),
            if (cabinetPhone != null && cabinetPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildInfoRow(Icons.phone, cabinetPhone),
              ),
          ],
          if (hasCabinetInfo && (hasSpecialties || hasAvailability))
            const Divider(height: 16),
          if (hasSpecialties) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Spécialités',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromRGBO(7, 82, 96, 1),
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: specialties.take(5).map(
                (s) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(7, 82, 96, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color.fromRGBO(7, 82, 96, 1),
                    ),
                  ),
                ),
              ).toList(),
            ),
            if (specialties.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${specialties.length - 5} autres',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
          if (hasSpecialties && hasAvailability)
            const SizedBox(height: 6),
          if (hasAvailability) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Disponibilités',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromRGBO(7, 82, 96, 1),
                ),
              ),
            ),
            ...availability.entries
                .where((e) =>
                    e.value != null &&
                    (e.value as Map)['start'] != null &&
                    (e.value as Map)['end'] != null)
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              e.key,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${e.value!['start']} - ${e.value!['end']}',
                            style: GoogleFonts.poppins(fontSize: 11),
                          ),
                        ],
                      ),
                    )),
          ],
          if (cabinetHours != null && cabinetHours.isNotEmpty) ...[
            if (hasAvailability || hasSpecialties)
              const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildInfoRow(Icons.schedule, cabinetHours),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color.fromRGBO(7, 82, 96, 1)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
