import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mymeds_app/screens/brain_games.dart';
import 'package:mymeds_app/screens/daily_assistant_screen.dart';
import 'package:mymeds_app/services/openrouter_service.dart';

class DailyEncouragementDialog extends StatefulWidget {
  const DailyEncouragementDialog({super.key});

  @override
  State<DailyEncouragementDialog> createState() =>
      _DailyEncouragementDialogState();
}

class _DailyEncouragementDialogState extends State<DailyEncouragementDialog> {
  String _language = 'fr';
  String _motivation = '';
  String _gameRecommendation = '';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('languageCode') ?? 'fr';

    setState(() {
      _language = lang;
      _motivation = OpenRouterService.getDailyMotivation(_language);
      _gameRecommendation = OpenRouterService.getGameRecommendation(_language);
    });
  }

  String _getTitle() {
    if (_language == 'ar') return 'مرحباً! كيف حالك؟';
    if (_language == 'en') return 'Hello! How are you?';
    return 'Bonjour! Comment allez-vous?';
  }

  String _getPlayButtonText() {
    if (_language == 'ar') return 'العب الآن';
    if (_language == 'en') return 'Play Now';
    return 'Jouer Maintenant';
  }

  String _getChatButtonText() {
    if (_language == 'ar') return 'تحدث مع المساعد';
    if (_language == 'en') return 'Chat with Assistant';
    return 'Parler avec l\'Assistant';
  }

  String _getLaterButtonText() {
    if (_language == 'ar') return 'لاحقاً';
    if (_language == 'en') return 'Later';
    return 'Plus tard';
  }

  String _getEncouragementTitle() {
    if (_language == 'ar') return 'هل تعلم؟';
    if (_language == 'en') return 'Did you know?';
    return 'Le saviez-vous?';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(7, 82, 96, 1),
              Color.fromRGBO(14, 149, 173, 1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Icon(
                Icons.emoji_emotions,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                _getTitle(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _getEncouragementTitle(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _motivation,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gamepad, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _gameRecommendation,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BrainGamesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_getPlayButtonText()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DailyAssistantScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: Text(_getChatButtonText()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _getLaterButtonText(),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showDailyEncouragementDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final lastShown = prefs.getString('last_encouragement_date');
  final today = DateTime.now().toString().substring(0, 10);

  if (lastShown != today) {
    await prefs.setString('last_encouragement_date', today);

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DailyEncouragementDialog(),
      );
    }
  }
}
