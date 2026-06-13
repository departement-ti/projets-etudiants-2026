import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class EventCard extends StatelessWidget {
  final String documentID;
  final bool isPast;
  final String medName;
  final String dosage;
  final String category;
  final int medcount;
  final String time;
  final String time24H;
  final bool isTaken;
  final String selectedDate;
  final VoidCallback refreshCallback;

  const EventCard({
    super.key,
    required this.documentID,
    required this.isPast,
    required this.medName,
    required this.dosage,
    required this.category,
    required this.medcount,
    required this.time,
    required this.time24H,
    required this.isTaken,
    required this.selectedDate,
    required this.refreshCallback,
  });

  String categoryImagePath(String catgoryStr) {
    switch (catgoryStr) {
      case 'Capsule':
        return 'lib/assets/icons/pills.png';
      case 'Tablet':
        return 'lib/assets/icons/tablet.png';
      case 'Liquid':
        return 'lib/assets/icons/liquid.png';
      case 'Topical':
        return 'lib/assets/icons/tube.png';
      case 'Cream':
        return 'lib/assets/icons/cream.png';
      case 'Drops':
        return 'lib/assets/icons/drops.png';
      case 'Foam':
        return 'lib/assets/icons/foam.png';
      case 'Gel':
        return 'lib/assets/icons/tube.png';
      case 'Herbal':
        return 'lib/assets/icons/herbal.png';
      case 'Inhaler':
        return 'lib/assets/icons/inhalator.png';
      case 'Injection':
        return 'lib/assets/icons/syringe.png';
      case 'Lotion':
        return 'lib/assets/icons/lotion.png';
      case 'Nasal Spray':
        return 'lib/assets/icons/nasalspray.png';
      case 'Ointment':
        return 'lib/assets/icons/tube.png';
      case 'Patch':
        return 'lib/assets/icons/patch.png';
      case 'Powder':
        return 'lib/assets/icons/powder.png';
      case 'Spray':
        return 'lib/assets/icons/spray.png';
      case 'Suppository':
        return 'lib/assets/icons/suppository.png';
      default:
        return 'lib/assets/icons/medicine.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    String takenTxt;
    IconData takenIcon;

    User? currentUser = FirebaseAuth.instance.currentUser;
    CollectionReference medications = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.email)
        .collection('Medications');
    List<String> dateStr = selectedDate.split('-');
    if (dateStr.length < 3) {
      dateStr = ['0', '0', '0'];
    }

    if (DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day) ==
        DateTime(int.parse(dateStr[0]), int.parse(dateStr[1]),
            int.parse(dateStr[2]))) {
      if (isTaken) {
        takenTxt = 'Taken';
        takenIcon = Icons.done;
      } else {
        takenTxt = 'Missed';
        takenIcon = Icons.close;
      }
    } else {
      takenTxt = 'Not yet';
      takenIcon = Icons.schedule;
    }

    Future takeMed() async {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Medications')
          .doc(documentID)
          .collection('Logs')
          .doc('$selectedDate $time24H')
          .set({
        'isTaken': true,
        'timeTaken': DateTime.now().toString(),
      });
    }

    Future missMed() async {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Medications')
          .doc(documentID)
          .collection('Logs')
          .doc('$selectedDate $time24H')
          .set({
        'isTaken': false,
        'timeTaken': '',
      });
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              actions: [
                Visibility(
                  visible: selectedDate ==
                      DateTime.now().toString().substring(0, 10),
                  child: TextButton.icon(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      missMed();
                      refreshCallback();
                      Navigator.pop(context);
                    },
                    label: const Text('Skip'),
                  ),
                ),
                Visibility(
                  visible: selectedDate ==
                      DateTime.now().toString().substring(0, 10),
                  child: TextButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    onPressed: () {
                      takeMed();
                      refreshCallback();
                      Navigator.pop(context);
                    },
                    label: const Text('Take'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
              content: FutureBuilder(
                future: medications
                    .doc(documentID)
                    .get(const GetOptions(source: Source.cache)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      Map<String, dynamic>? medData =
                          snapshot.data!.data() != null
                              ? snapshot.data!.data() as Map<String, dynamic>
                              : <String, dynamic>{};
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            medData['medname'] ?? '',
                            style: GoogleFonts.roboto(
                              color: const Color.fromARGB(255, 16, 15, 15),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (medData['strength'] != null) ...[
                            Text(
                              '${medData['strength']} ${medData['strength_unit']}',
                              style: GoogleFonts.roboto(
                                color: const Color.fromARGB(255, 16, 15, 15),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            'Take ${medData['medcount']} ${medData['category']}(s) at $time',
                            style: GoogleFonts.roboto(
                              color: const Color.fromARGB(255, 16, 15, 15),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Since ${medData['start_date']}',
                            style: GoogleFonts.roboto(
                              color: const Color.fromARGB(255, 16, 15, 15),
                              fontSize: 16,
                            ),
                          ),
                          if (medData['user_note'] != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Note: ${medData['user_note']}',
                              style: GoogleFonts.roboto(
                                color: const Color.fromARGB(255, 16, 15, 15),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      enabled: true,
                      child: const SingleChildScrollView(
                        physics: NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [BannerPlaceholder()],
                        ),
                      ),
                    );
                  }
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    enabled: true,
                    child: const SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [BannerPlaceholder()],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(25, 14, 25, 14),
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD4C5E2),
              blurRadius: 6.0,
              offset: Offset(0, 3),
            )
          ],
          color: isTaken
              ? const Color(0xFFC9B8DB)
              : Theme.of(context).colorScheme.primary,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(categoryImagePath(category)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    medName,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: !isTaken
                          ? Theme.of(context).colorScheme.surface
                          : const Color.fromARGB(255, 16, 15, 15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$medcount $category(s)',
                    maxLines: 1,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      color: !isTaken
                          ? Theme.of(context).colorScheme.surface
                          : const Color.fromARGB(255, 16, 15, 15),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: !isTaken
                        ? Theme.of(context).colorScheme.surface
                        : const Color.fromARGB(255, 16, 15, 15),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      takenIcon,
                      color: !isTaken
                          ? Theme.of(context).colorScheme.surface
                          : const Color.fromARGB(255, 16, 15, 15),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      takenTxt,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: !isTaken
                            ? Theme.of(context).colorScheme.surface
                            : const Color.fromARGB(255, 16, 15, 15),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BannerPlaceholder extends StatelessWidget {
  const BannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 25.0,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 20.0,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 20.0,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 20.0,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 20.0,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 20.0,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 20.0,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
