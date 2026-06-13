import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/brain_games.dart';
import 'package:mymeds_app/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mymeds_app/services/talkback_screen_mixin.dart';

class DailyAssistantScreen extends StatefulWidget {
  const DailyAssistantScreen({super.key});

  @override
  State<DailyAssistantScreen> createState() => _DailyAssistantScreenState();
}

class _DailyAssistantScreenState extends State<DailyAssistantScreen> with TalkbackScreenMixin {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _currentLanguage = 'fr';

  static String get _openRouterKey => ApiConfig.openRouterApiKey;
  static const _baseUrl = ApiConfig.openRouterBaseUrl;

  final List<Map<String, dynamic>> _gameRecommendations = [
    {
      'icon': Icons.grid_4x4,
      'nameKey': 'gameMemoryMatch',
      'descKey': 'gameMemoryMatchDesc',
      'color': Colors.blue,
    },
    {
      'icon': Icons.calculate,
      'nameKey': 'gameMathChallenge',
      'descKey': 'gameMathChallengeDesc',
      'color': Color(0xFF5B5EA6),
    },
    {
      'icon': Icons.touch_app,
      'nameKey': 'gameReactionTest',
      'descKey': 'gameReactionTestDesc',
      'color': Colors.orange,
    },
    {
      'icon': Icons.psychology,
      'nameKey': 'gameColorMatch',
      'descKey': 'gameColorMatchDesc',
      'color': Colors.purple,
    },
    {
      'icon': Icons.search,
      'nameKey': 'gameHiddenObject',
      'descKey': 'gameHiddenObjectDesc',
      'color': Colors.deepPurple,
    },
    {
      'icon': Icons.numbers,
      'nameKey': 'gameSequenceMemory',
      'descKey': 'gameSequenceMemoryDesc',
      'color': Colors.indigo,
    },
  ];

  String _getSystemPrompt(String lang) {
    if (lang == 'ar') {
      return '''أنت "صديقي" - مساعد يومي دافئ ومتعاطف لكبار السن.
شخصيتك:
- ودود جداً، تتحدث بأسلوب دافئ وراعوي
- تشجع على البقاء نشيطاً وصحياً
- تقدم نصائح بسيطة ومفيدة للحياة اليومية
- تسأل أسئلة لطيفة عن يوم المستخدم
- تقترح ألعاباً عقلية ممتعة عندما يكون ذلك مناسباً
- ذكاؤك حنون مثل جدة/جد محب
قواعد مهمة:
- جمل قصيرة (2-3 كحد أقصى)
- استخدم الإيموجي لتجعل المحادثة مبهجة 😊
- لا تستخدم كلمات طبية معقدة
- شجع دائماً على النشاط والصحة
- أنهِ دائماً بجملة تشجيعية دافئة
أنت "صديقي" الرفيق اليومي، ولست نموذج ذكاء اصطناعي.''';
    } else if (lang == 'en') {
      return '''You are "My Friend" - a warm daily assistant for elderly people.
Your personality:
- Very friendly, speak in a warm and caring way
- Encourage staying active and healthy
- Give simple, practical tips for daily life
- Ask gentle questions about the user's day
- Suggest fun brain games when appropriate
- Your intelligence is warm like a loving grandparent
Important rules:
- Short sentences (2-3 max)
- Use emojis to make conversation cheerful 😊
- No complex medical terms
- Always encourage activity and health
- Always end with a warm encouraging sentence
You are "My Friend" the daily companion, not an AI model.''';
    } else {
      return '''Tu es "Mon Ami" - un assistant quotidien chaleureux pour les personnes âgées.
Ta personnalité:
- Très amical, tu parles de manière chaleureuse et attentionnée
- Tu encourages à rester actif et en bonne santé
- Tu donnes des conseils simples et pratiques pour la vie quotidienne
- Tu poses des questions douces sur la journée de l'utilisateur
- Tu suggères des jeux cérébraux amusants quand c'est approprié
- Ton intelligence est affectueuse comme un grand-parent aimant
Règles importantes:
- Phrases courtes (2-3 max)
- Utilise des émojis pour rendre la conversation joyeuse 😊
- Pas de termes médicaux compliqués
- Encourage toujours l'activité et la santé
- Termine toujours par une phrase encourageante et chaleureuse
Tu es "Mon Ami" le compagnon quotidien, pas un modèle AI.''';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    speakOnLoad(translation(context).dailyAssistant);
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _sendInitialGreeting();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('languageCode') ?? 'fr';
    setState(() {
      _currentLanguage = lang;
    });
  }

  Future<void> _sendInitialGreeting() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('languageCode') ?? 'fr';

    String prompt;
    if (lang == 'ar') {
      prompt = 'مرحباً! عرفني بنفسك وأعطني نصيحة صحية واحدة وتحفيزاً واحداً لليوم.';
    } else if (lang == 'en') {
      prompt = 'Hello! Introduce yourself and give me one health tip and one motivation for today.';
    } else {
      prompt = 'Bonjour! Présente-toi et donne-moi un conseil santé et une motivation pour aujourd\'hui.';
    }

    final response = await _callAI(prompt, lang, []);

    if (mounted) {
      setState(() {
        _messages.add({
          'type': 'ai',
          'message': response,
          'isTranslation': false,
        });
      });
    }
  }

  Future<String> _callAI(String text, String lang, List<Map<String, String>> history) async {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _getSystemPrompt(lang)},
      ];

      for (final m in history) {
        if (m['content']!.isNotEmpty) {
          messages.add({
            'role': m['role']!,
            'content': m['content']!,
          });
        }
      }

      messages.add({'role': 'user', 'content': text});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterKey',
          'HTTP-Referer': 'https://neurocare.app',
          'X-Title': 'NeuroCare - Daily Assistant',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'] ??
            _getFallback(text, lang);
      } else {
        return _getFallback(text, lang);
      }
    } catch (e) {
      return _getFallback(text, lang);
    }
  }

  String _getFallback(String text, String lang) {
    if (lang == 'ar') {
      if (text.contains('نصيحة') || text.contains('صحة')) {
        return '💧 اشرب 8 أكواب ماء يومياً - السر في صحة جيدة! 🚶 امشِ 15 دقيقة كل يوم. 💪 أنت قوي وصحتك مهمة جداً!';
      }
      if (text.contains('تحفيز') || text.contains('تشجيع')) {
        return '🌟 كل يوم جديد هو فرصة جميلة! أنت شخص رائع وقوي. 💪 استمر في العناية بنفسك!';
      }
      if (text.contains('لعبة') || text.contains('لعب')) {
        return '🎮 فكرة رائعة! جرب لعبة الذاكرة - ممتازة لتنشيط العقل! 🧠 اضغط على اللعبة للبدء.';
      }
      return 'مرحباً يا صديقي! 😊 كيف حالك اليوم؟ أنا هنا لمساعدتك. 💙';
    } else if (lang == 'en') {
      if (text.contains('health') || text.contains('tip')) {
        return '💧 Drink 8 glasses of water daily! 🚶 Walk 15 minutes every day. 💪 You are strong and your health matters!';
      }
      if (text.contains('motivation')) {
        return '🌟 Every new day is a beautiful opportunity! You are wonderful and strong. 💪 Keep taking care of yourself!';
      }
      if (text.contains('game') || text.contains('play')) {
        return '🎮 Great idea! Try the memory game - excellent for brain activity! 🧠 Tap the game to start.';
      }
      return 'Hello my friend! 😊 How are you today? I\'m here to help you. 💙';
    } else {
      if (text.contains('santé') || text.contains('conseil')) {
        return '💧 Buvez 8 verres d\'eau par jour! 🚶 Marchez 15 minutes chaque jour. 💪 Vous êtes fort et votre santé compte!';
      }
      if (text.contains('motivation')) {
        return '🌟 Chaque nouveau jour est une belle opportunité! Vous êtes formidable et fort. 💪 Continuez à prendre soin de vous!';
      }
      if (text.contains('jeu') || text.contains('jouer')) {
        return '🎮 Excellente idée! Essayez le jeu de mémoire - excellent pour le cerveau! 🧠 Appuyez sur le jeu pour commencer.';
      }
      return 'Bonjour mon ami! 😊 Comment allez-vous aujourd\'hui? Je suis là pour vous aider. 💙';
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'type': 'user',
        'message': text,
        'isTranslation': false,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final history = <Map<String, String>>[];
    for (final m in _messages) {
      if (m['type'] == 'user') {
        history.add({'role': 'user', 'content': m['message'] as String});
      } else if (m['type'] == 'ai' && m['gameData'] == null) {
        history.add({'role': 'assistant', 'content': m['message'] as String});
      }
    }

    final response = await _callAI(text, _currentLanguage, history);

    if (mounted) {
      setState(() {
        _messages.add({
          'type': 'ai',
          'message': response,
          'isTranslation': false,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _recommendGame() {
    final random = DateTime.now().millisecond % _gameRecommendations.length;
    final game = _gameRecommendations[random];

    String prompt;
    if (_currentLanguage == 'ar') {
      prompt = 'اقترح علي لعبة عقلية ممتعة للعب الآن.';
    } else if (_currentLanguage == 'en') {
      prompt = 'Suggest a fun brain game for me to play now.';
    } else {
      prompt = 'Suggère-moi un jeu cérébral amusant à jouer maintenant.';
    }

    setState(() {
      _messages.add({
        'type': 'user',
        'message': prompt,
        'isTranslation': false,
      });
      _messages.add({
        'type': 'ai',
        'message': 'tapToPlay',
        'isTranslation': true,
        'gameData': game,
      });
    });
  }

  Future<void> _sendHealthTip() async {
    String prompt;
    if (_currentLanguage == 'ar') {
      prompt = 'أعطني نصيحة صحية مفيدة لليوم.';
    } else if (_currentLanguage == 'en') {
      prompt = 'Give me a useful health tip for today.';
    } else {
      prompt = 'Donne-moi un conseil santé utile pour aujourd\'hui.';
    }

    setState(() {
      _messages.add({
        'type': 'user',
        'message': prompt,
        'isTranslation': false,
      });
      _isLoading = true;
    });

    final history = <Map<String, String>>[];
    for (final m in _messages) {
      if (m['type'] == 'user') {
        history.add({'role': 'user', 'content': m['message'] as String});
      } else if (m['type'] == 'ai' && m['gameData'] == null) {
        history.add({'role': 'assistant', 'content': m['message'] as String});
      }
    }

    final response = await _callAI(prompt, _currentLanguage, history);

    if (mounted) {
      setState(() {
        _messages.add({
          'type': 'ai',
          'message': response,
          'isTranslation': false,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMotivation() async {
    String prompt;
    if (_currentLanguage == 'ar') {
      prompt = 'شجعني بكلمة تحفيزية جميلة لليوم.';
    } else if (_currentLanguage == 'en') {
      prompt = 'Encourage me with a beautiful motivation for today.';
    } else {
      prompt = 'Encourage-moi avec une belle motivation pour aujourd\'hui.';
    }

    setState(() {
      _messages.add({
        'type': 'user',
        'message': prompt,
        'isTranslation': false,
      });
      _isLoading = true;
    });

    final history = <Map<String, String>>[];
    for (final m in _messages) {
      if (m['type'] == 'user') {
        history.add({'role': 'user', 'content': m['message'] as String});
      } else if (m['type'] == 'ai' && m['gameData'] == null) {
        history.add({'role': 'assistant', 'content': m['message'] as String});
      }
    }

    final response = await _callAI(prompt, _currentLanguage, history);

    if (mounted) {
      setState(() {
        _messages.add({
          'type': 'ai',
          'message': response,
          'isTranslation': false,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getTranslation(String key, dynamic t) {
    switch (key) {
      case 'gameMemoryMatch':
        return t.gameMemoryMatch;
      case 'gameMemoryMatchDesc':
        return t.gameMemoryMatchDesc;
      case 'gameMathChallenge':
        return t.gameMathChallenge;
      case 'gameMathChallengeDesc':
        return t.gameMathChallengeDesc;
      case 'gameReactionTest':
        return t.gameReactionTest;
      case 'gameReactionTestDesc':
        return t.gameReactionTestDesc;
      case 'gameColorMatch':
        return t.gameColorMatch;
      case 'gameColorMatchDesc':
        return t.gameColorMatchDesc;
      case 'gameHiddenObject':
        return t.gameHiddenObject;
      case 'gameHiddenObjectDesc':
        return t.gameHiddenObjectDesc;
      case 'gameSequenceMemory':
        return t.gameSequenceMemory;
      case 'gameSequenceMemoryDesc':
        return t.gameSequenceMemoryDesc;
      case 'tapToPlay':
        return t.tapToPlay;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.dailyAssistant,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5B5EA6),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              _sendInitialGreeting();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, t);
              },
            ),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildQuickActions(t),
          _buildMessageInput(t),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, dynamic t) {
    final isUser = message['type'] == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF5B5EA6),
              child:
                  const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF5B5EA6)
                    : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['isTranslation'] == true)
                    Text(
                      _getTranslation(message['message'], t),
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    )
                  else if (message['gameData'] != null)
                    _buildGameRecommendation(
                        message['gameData'], t, isUser)
                  else
                    Text(
                      message['message'],
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameRecommendation(
      Map<String, dynamic> game, dynamic t, bool isUser) {
    String gameName = _getTranslation(game['nameKey'], t);
    String gameDesc = _getTranslation(game['descKey'], t);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BrainGamesScreen(),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.tapToPlay,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: isUser ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (game['color'] as Color).withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(game['icon'] as IconData,
                      color: game['color'] as Color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          gameDesc,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: isUser ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isUser ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF5B5EA6),
            child:
                const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentLanguage == 'ar'
                      ? 'يكتب...'
                      : _currentLanguage == 'en'
                          ? 'Typing...'
                          : 'Écrit...',
                  style: GoogleFonts.roboto(fontSize: 14),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF5B5EA6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(dynamic t) {
    String playLabel = _currentLanguage == 'ar'
        ? 'العب'
        : _currentLanguage == 'en'
            ? 'Play'
            : 'Jouer';
    String healthLabel = _currentLanguage == 'ar'
        ? 'نصيحة صحية'
        : _currentLanguage == 'en'
            ? 'Health Tip'
            : 'Conseil';
    String motivationLabel = _currentLanguage == 'ar'
        ? 'تحفيز'
        : _currentLanguage == 'en'
            ? 'Motivate'
            : 'Motiver';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickAction(
              icon: Icons.gamepad,
              label: playLabel,
              color: Colors.blue,
              onTap: _recommendGame,
            ),
            const SizedBox(width: 8),
            _buildQuickAction(
              icon: Icons.favorite,
              label: healthLabel,
              color: Colors.red,
              onTap: _sendHealthTip,
            ),
            const SizedBox(width: 8),
            _buildQuickAction(
              icon: Icons.emoji_emotions,
              label: motivationLabel,
              color: Colors.amber,
              onTap: _sendMotivation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(dynamic t) {
    String hintText = _currentLanguage == 'ar'
        ? 'اكتب رسالة...'
        : _currentLanguage == 'en'
            ? 'Type a message...'
            : 'Écrivez un message...';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) => _sendMessage(value),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: const Color(0xFF5B5EA6),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
