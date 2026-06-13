import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeniorChatScreen extends StatefulWidget {
  const SeniorChatScreen({super.key});

  @override
  State<SeniorChatScreen> createState() => _SeniorChatScreenState();
}

class _SeniorChatScreenState extends State<SeniorChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  double _fontSize = 20;
  String _currentLang = 'ar';

  static String get _openRouterKey => ApiConfig.openRouterApiKey;
  static const _baseUrl = ApiConfig.openRouterBaseUrl;

  String _getSystemPrompt(String lang) {
    if (lang == 'ar') {
      return '''أنت "رفيق"، مساعد ذكي ولطيف ومتخصص في مساعدة كبار السن في تونس.
القواعد:
- تكلم بالعربية التونسية البسيطة
- جمل قصيرة (2-3 كحد أقصى)
- استخدم الإيموجي لتجعل المحادثة مبهجة
- إذا سأل عن الأدوية: اشرح ببساطة بدون مصطلحات طبية
- إذا ذكر ألم أو مرض: شجعه على الاتصال بالطبيب أو العائلة
- إذا طلب تمرينا: أعطه تمرينا بسيطا وممتعا
- أنهِ دائما بجملة تشجيعية
- أنت "رفيق" الرفيق، ولست نموذج ذكاء اصطناعي''';
    } else {
      return '''Tu es "Rafiq", un assistant intelligent, doux et spécialisé pour aider les personnes âgées en Tunisie.
Règles :
- Parle en français simple
- Phrases courtes (2-3 max)
- Utilise des émojis pour rendre la conversation joyeuse
- Si question sur médicaments : explique simplement
- Si mention de douleur ou maladie : encourage à contacter le médecin ou la famille
- Si demande d'exercice : donne un exercice simple et amusant
- Termine toujours par une phrase encourageante
- Tu es "Rafiq" le compagnon, pas un modèle AI''';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _detectLanguage();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('languageCode') ?? 'ar';
    setState(() {
      _fontSize = prefs.getDouble('chat_font_size') ?? 20;
      _currentLang = lang;
    });
    // Add welcome message in detected language
    _addWelcomeMessage(lang);
  }

  void _addWelcomeMessage(String lang) {
    final t = translation(context);
    _messages.add(ChatMessage(
      text: t.chatWelcome,
      isUser: false,
      time: _formatTime(DateTime.now()),
    ));
  }

  void _detectLanguage() {
    // Already handled in _loadPreferences
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chat_font_size', _fontSize);
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(16, 28);
    });
    _saveFontSize();
  }

  List<QuickAction> _getQuickActions(BuildContext context) {
    final t = translation(context);
    return [
      QuickAction(t.chatQuickMeds, t.chatQuickMedsPrompt),
      QuickAction(t.chatQuickExercise, t.chatQuickExercisePrompt),
      QuickAction(t.chatQuickTired, t.chatQuickTiredPrompt),
      QuickAction(t.chatQuickStory, t.chatQuickStoryPrompt),
    ];
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = ChatMessage(
      text: text.trim(),
      isUser: true,
      time: _formatTime(DateTime.now()),
    );

    setState(() {
      _messages.add(userMsg);
      _inputController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      print('📤 Sending to AI ($_currentLang): $text');

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _getSystemPrompt(_currentLang)},
      ];
      for (final m in _messages) {
        if (m.text.isNotEmpty && !m.text.startsWith('مرحباً') && !m.text.startsWith('Hello') && !m.text.startsWith('Bonjour')) {
          messages.add({
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          });
        }
      }
      messages.add({'role': 'user', 'content': text});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterKey',
          'HTTP-Referer': 'https://mymeds.app',
          'X-Title': 'NeuroCare - Rafiq Assistant',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      String reply;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['choices']?[0]?['message']?['content'] ?? _getFallback(text, _currentLang);
      } else {
        print('❌ API error: ${response.statusCode}');
        reply = _getFallback(text, _currentLang);
      }

      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false, time: _formatTime(DateTime.now())));
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Chat error: $e');
      setState(() {
        _messages.add(ChatMessage(text: _getFallback(text, _currentLang), isUser: false, time: _formatTime(DateTime.now())));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _getFallback(String text, String lang) {
    final isAr = lang == 'ar';
    if (text.contains('أدويتي') || text.contains('médicament') || text.contains('medication')) {
      return isAr ? 'أدوية اليوم مهمة جداً لصحتك! 💊\nتأكد من أخذها في وقتها.' : 'Vos médicaments sont très importants ! 💊\nAssurez-vous de les prendre à temps.';
    }
    if (text.contains('تمرين') || text.contains('exercice')) {
      return isAr ? 'تمرين بسيط: 🧠\n1- عد من 100 إلى 1\n2- تذكر 5 كلمات وكررها\nجرب هذا! 💪' : 'Exercice simple : 🧠\n1- Comptez de 100 à 1\n2- Mémorisez 5 mots\nEssayez ! 💪';
    }
    if (text.contains('تعب') || text.contains('fatigué') || text.contains('tired')) {
      return isAr ? 'أنا آسف لأنك متعب 😌\nخذ قسطاً من الراحة واشرب ماءً. 🌸' : 'Désolé que vous soyez fatigué 😌\nReposez-vous et buvez de l\'eau. 🌸';
    }
    if (text.contains('قصة') || text.contains('histoire') || text.contains('story')) {
      return isAr ? '📖 كان يا ما كان...\nفي قديم الزمان، كان هناك رجل حكيم يعيش في قرية صغيرة... 🌟' : '📖 Il était une fois...\nUn homme sage qui vivait dans un petit village... 🌟';
    }
    return isAr ? 'شكراً لكلامك! 💙\nأنا هنا لمساعدتك. 😊' : 'Merci pour votre message ! 💙\nJe suis là pour vous aider. 😊';
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    final isRtl = _currentLang == 'ar';
    final quickActions = _getQuickActions(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(isRtl ? '🤖 رفيق' : '🤖 Rafiq', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _changeFontSize(-2),
            child: const Text('A−', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _changeFontSize(2),
            child: const Text('A+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: quickActions.map((action) {
                return ActionChip(
                  avatar: Text(action.label.split(' ').first, style: const TextStyle(fontSize: 18)),
                  label: Text(action.label, style: GoogleFonts.poppins(fontSize: _fontSize - 2, fontWeight: FontWeight.w600, color: const Color(0xFF1565C0))),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF1565C0), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  onPressed: () => _sendMessage(action.prompt),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) return _buildLoadingBubble();
                return _buildMessageBubble(_messages[index], isRtl ? TextDirection.rtl : TextDirection.ltr);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -4))]),
            child: SafeArea(
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: GoogleFonts.poppins(fontSize: _fontSize),
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: t.chatPlaceholder,
                        hintStyle: GoogleFonts.poppins(fontSize: _fontSize, color: Colors.grey),
                        filled: true, fillColor: const Color(0xFFF8FBFF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: Color(0xFFBBDEFB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: (_isLoading || _inputController.text.trim().isEmpty) ? Colors.grey : const Color(0xFF1976D2),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: (_isLoading || _inputController.text.trim().isEmpty) ? null : () => _sendMessage(_inputController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, TextDirection dir) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: dir,
        children: [
          if (!msg.isUser) ...[
            Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)])),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20)))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser ? const Color(0xFF1565C0) : Colors.white,
                borderRadius: msg.isUser
                    ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))
                    : const BorderRadius.only(topRight: Radius.circular(4), topLeft: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(msg.isUser ? 35 : 10), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text, style: GoogleFonts.poppins(fontSize: _fontSize, color: msg.isUser ? Colors.white : const Color(0xFF1A1A2E), height: 1.5),
                      textDirection: dir),
                  const SizedBox(height: 4),
                  Text(msg.time, style: GoogleFonts.poppins(fontSize: 11, color: msg.isUser ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFD54F)])),
                child: const Center(child: Text('👴', style: TextStyle(fontSize: 20)))),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)])),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topRight: Radius.circular(4), topLeft: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
            child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Padding(padding: EdgeInsets.only(left: i < 2 ? 4 : 0), child: _BouncingDot(delay: i * 200)))),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  ChatMessage({required this.text, required this.isUser, required this.time});
}

class QuickAction {
  final String label;
  final String prompt;
  const QuickAction(this.label, this.prompt);
}

class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});
  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _controller.repeat(reverse: true); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(offset: Offset(0, -8 * _animation.value), child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1976D2)))),
    );
  }
}
