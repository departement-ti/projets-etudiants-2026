import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mymeds_app/services/api_config.dart';

class OpenRouterService {
  static String get _apiKey => ApiConfig.openRouterApiKey;
  static const String _baseUrl = ApiConfig.openRouterBaseUrl;

  static String _getSystemPrompt(String language) {
    if (language == 'ar') {
      return '''أنت "صديقي" - مساعد ذكاء اصطناعي دافئ ومتعاطف لتطبيق صحي للمسنين.
شخصيتك:
- ودود جداً وسعيد، تتحدث بأسلوب دافئ وراعوي
- تحب تشجيع كبار السن على البقاء نشيطين
- تقدم نصائح بسيطة ومفيدة للحياة اليومية
- تسأل أسئلة لتعرف على المستخدم بشكل أفضل
- تقترح ألعاب عقلية ممتعة
- ذكاءك حنون Like جدتي/جدك الحنون
لا تستخدم كلمات معقدة. اجعل إجاباتك قصيرة ومبهجة (جملتين أو ثلاث).
ابدأ دائماً بسؤال دافئ عن يوم المستخدم.''';
    } else if (language == 'en') {
      return '''You are "My Friend" - a warm and caring AI assistant for elderly people using a health app.
Your personality:
- Very friendly and happy, speak in a warm and caring way
- Love encouraging elderly users to stay active
- Give simple and practical tips for daily life
- Ask questions to get to know the user better
- Suggest fun brain games
- Your intelligence is warm like a loving grandparent
Do not use complex words. Keep responses short and cheerful (2-3 sentences max).
Always start with a warm question about the user's day.''';
    } else {
      return '''Tu es "Mon Ami" - un assistant IA chaleureux et bienveillant pour les personnes âgées utilisant une application de santé.
Ta personnalité:
- Très amical et joyeux, tu parles de manière chaleureuse et attentionnée
- Tu aimes encourager les personnes âgées à rester actives
- Tu donnes des conseils simples et pratiques pour la vie quotidienne
- Tu poses des questions pour mieux connaître l'utilisateur
- Tu suggères des jeux cérébraux amusants
- Ton intelligence est affectueuse comme un grand-parent aimant
Ne utilise pas de mots compliqués. Garde tes réponses courtes et joyeuses (2-3 phrases max).
Commence toujours par une question chaleureuse sur la journée de l'utilisateur.''';
    }
  }

  static String _getFallbackPrompt(String language) {
    if (language == 'ar') {
      return '''أجب على رسالة المستخدم بأسلوب دافئ ومحب. 
يريد المستخدم أن تبقى إجابتك قصيرة جداً (جملة أو اثنتان).
إذا سأل عن الصحة، أعط نصيحة بسيطة.
شجعه على اللعب أو الحركة.
أجب بالعربية فقط.''';
    } else if (language == 'en') {
      return '''Respond to the user's message in a warm and loving style.
Keep your response very short (1-2 sentences max).
If they ask about health, give a simple tip.
Encourage them to play or move around.
Respond in English only.''';
    } else {
      return '''Réponds au message de l'utilisateur avec un style chaleureux et affectueux.
Garde ta réponse très courte (1-2 phrases max).
Si l'utilisateur demande des conseils santé, donne un conseil simple.
Encourage-le à jouer ou à bouger.
Réponds en français uniquement.''';
    }
  }

  static Future<String> sendMessage(String userMessage,
      {String language = 'fr'}) async {
    try {
      final systemPrompt = _getSystemPrompt(language);
      final fallbackPrompt = _getFallbackPrompt(language);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://mymeds.app',
          'X-Title': 'NeuroCare Assistant',
        },
        body: jsonEncode({
          'model': 'openrouter/auto',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage}
          ],
          'max_tokens': 150,
          'temperature': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];

        if (aiResponse.length > 300) {
          aiResponse = _getDefaultResponse(userMessage, language);
        }

        return aiResponse;
      } else {
        return _getDefaultResponse(userMessage, language);
      }
    } catch (e) {
      return _getDefaultResponse(userMessage, language);
    }
  }

  static String _getDefaultResponse(String message, String language) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('bonjour') ||
        lowerMessage.contains('hello') ||
        lowerMessage.contains('مرحبا') ||
        lowerMessage.contains('salut') ||
        lowerMessage.contains('صباح') ||
        lowerMessage.contains('مسا')) {
      return _getGreeting(language);
    }

    if (lowerMessage.contains('bien') ||
        lowerMessage.contains('good') ||
        lowerMessage.contains('جيد') ||
        lowerMessage.contains('بخير')) {
      return _getPositiveResponse(language);
    }

    if (lowerMessage.contains('mal') ||
        lowerMessage.contains('bad') ||
        lowerMessage.contains('سيء') ||
        lowerMessage.contains('تعبان')) {
      return _getConcernResponse(language);
    }

    if (lowerMessage.contains('jeu') ||
        lowerMessage.contains('game') ||
        lowerMessage.contains('لعب') ||
        lowerMessage.contains(' игра')) {
      return _getGameResponse(language);
    }

    if (lowerMessage.contains('santé') ||
        lowerMessage.contains('health') ||
        lowerMessage.contains('صحة') ||
        lowerMessage.contains('malade')) {
      return _getHealthResponse(language);
    }

    if (lowerMessage.contains('médicament') ||
        lowerMessage.contains('medication') ||
        lowerMessage.contains('دواء') ||
        lowerMessage.contains('حبوب')) {
      return _getMedicationResponse(language);
    }

    if (lowerMessage.contains('merci') ||
        lowerMessage.contains('thanks') ||
        lowerMessage.contains('شكرا') ||
        lowerMessage.contains('بارك')) {
      return _getThanksResponse(language);
    }

    if (lowerMessage.contains('孤单') ||
        lowerMessage.contains('lonely') ||
        lowerMessage.contains('seul') ||
        lowerMessage.contains('وحيد') ||
        lowerMessage.contains('ممل')) {
      return _getLonelyResponse(language);
    }

    if (lowerMessage.contains('famille') ||
        lowerMessage.contains('family') ||
        lowerMessage.contains('عائلة') ||
        lowerMessage.contains('أبناء')) {
      return _getFamilyResponse(language);
    }

    return _getGeneralResponse(language);
  }

  static String _getGreeting(String language) {
    final greetings = language == 'ar'
        ? [
            'صباح الخير يا صديقي! كيف دلوقتي؟ 😊',
            'أهلاً وسهلاً! عامل إيه النهارده؟ 🌟',
            'مرحباً يا عزيزي! اتمني يومك يكون حلو! ☀️',
          ]
        : language == 'en'
            ? [
                'Good morning, dear friend! How are you today? 😊',
                'Hello there! How\'s your day going? 🌟',
                'Hey! Hope you\'re having a wonderful day! ☀️',
              ]
            : [
                'Bonjour mon ami! Comment allez-vous ce matin? 😊',
                'Salut! Comment va votre journée? 🌟',
                'Bonsoir! J\'espère que vous allez bien! ☀️',
              ];

    return greetings[DateTime.now().minute % greetings.length];
  }

  static String _getPositiveResponse(String language) {
    final responses = language == 'ar'
        ? [
            'يا سلام! ده خبر حلو أوي!继续保持 النشاط يا معالي! 😊',
            'ممتاز! الفرحة بتبان عليك! دا بيفرحني جداً! 🌟',
            'الحمد لله! سعيد إنك مبسوط!继续保持 ده! ☀️',
          ]
        : language == 'en'
            ? [
                'That\'s wonderful to hear! Keep that positivity going! 😊',
                'Great! Your happiness makes me so happy too! 🌟',
                'Praise God! I\'m glad you\'re feeling good! Keep it up! ☀️',
              ]
            : [
                'C\'est merveilleux! Je suis si heureux que vous alliez bien! 😊',
                'Excellent! Ça me fait plaisir de vous voir heureux! 🌟',
                'Dieu merci! Je suis ravi que vous vous sentiez bien! ☀️',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String _getConcernResponse(String language) {
    final responses = language == 'ar'
        ? [
            'أنا هنا معاك يا صديقي! اشرب مي كتير ورتاح شوية. 🤗',
            'متقلقش، كل يوم وراه يوم جديد! اتكلم مع حد تحبه. 💙',
            'صباح الهم مش ليه! اشرب شاي سخن واحسن حالك. 🍵',
          ]
        : language == 'en'
            ? [
                'I\'m here for you, friend! Drink water and rest a bit. 🤗',
                'Don\'t worry, every day brings new hope! Talk to someone you love. 💙',
                'Bad days pass! Drink some warm tea and take it easy. 🍵',
              ]
            : [
                'Je suis là avec vous, mon ami! Buvez beaucoup d\'eau et reposez-vous. 🤗',
                'Ne vous inquiétez pas, chaque jour apporte de l\'espoir! Parlez à quelqu\'un que vous aimez. 💙',
                'Les mauvais jours passent! Buvez un thé chaud et reposez-vous. 🍵',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String _getGameResponse(String language) {
    final responses = language == 'ar'
        ? [
            'فكرة حلوة! تعالى نلعب لعبة الذاكرة معاً! ده هيفرح دماغك. 🧠',
            'اللعاب ممتاز للعقل! جرب تحدي الرياضيات - بسيط وممتع! 🎮',
            'نورت! الألعاب العقلية بتخليك شاب方法和! تعالى نبدأ. ✨',
          ]
        : language == 'en'
            ? [
                'Great idea! Let\'s play a memory game! It\'s so good for your brain. 🧠',
                'Playing is excellent for the mind! Try the Math Challenge - it\'s fun! 🎮',
                'Wonderful! Brain games keep you young! Let\'s start! ✨',
              ]
            : [
                'Excellente idée! Jouons à un jeu de mémoire! C\'est excellent pour le cerveau. 🧠',
                'Jouer est excellent pour l\'esprit! Essayez le Défi Maths - c\'est amusant! 🎮',
                'Magnifique! Les jeux cérébraux vous gardent jeune! Commençons! ✨',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String _getHealthResponse(String language) {
    final responses = language == 'ar'
        ? [
            'لازم تشرب 8 كوب مي يومياً! المي بيفرق معاك كتير. 💧',
            'المشي كل يوم 15 دقيقة! هتلاقي نفسك أفضل بكتير. 🚶',
            'النوم كويس مهم جداً! حاول تنام 7 أو 8 ساعات. 😴',
          ]
        : language == 'en'
            ? [
                'You must drink 8 glasses of water daily! Water makes a big difference. 💧',
                'Walking 15 minutes every day! You\'ll feel so much better. 🚶',
                'Good sleep is very important! Try to get 7-8 hours. 😴',
              ]
            : [
                'Vous devez boire 8 verres d\'eau par jour! L\'eau fait une grande différence. 💧',
                'Marcher 15 minutes chaque jour! Vous vous sentirez beaucoup mieux. 🚶',
                'Le bon sommeil est très important! Essayez de dormir 7-8 heures. 😴',
              ];

    return responses[DateTime.now().hour % responses.length];
  }

  static String _getMedicationResponse(String language) {
    final responses = language == 'ar'
        ? [
            'صحتك أهم حاجة! خد أدويتك في الميعاد كل يوم. 💊',
            'الأدوية مهمة جداً! حط منبه عشان متنساش. ⏰',
            'اهتمامك بصحتك شيء جميل!继续保持吃药 يا معالي. ❤️',
          ]
        : language == 'en'
            ? [
                'Your health is the most important thing! Take your medicine on time every day. 💊',
                'Medications are very important! Set an alarm so you don\'t forget. ⏰',
                'Taking care of your health is beautiful! Keep taking your meds. ❤️',
              ]
            : [
                'Votre santé est la chose la plus importante! Prenez vos médicaments à l\'heure. 💊',
                'Les médicaments sont très importants! Réglez une alarme pour ne pas oublier. ⏰',
                'Prendre soin de votre santé est magnifique! Continuez vos médicaments. ❤️',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String _getThanksResponse(String language) {
    final responses = language == 'ar'
        ? [
            'العفو يا صديقي! دا واجبي! 😊',
            'خدمة ليك يا غالي! لو محتاج أي حاجة أنا هنا. 💙',
            'بالتوفيق! يومك يكون جميل! ✨',
          ]
        : language == 'en'
            ? [
                'You\'re welcome, dear friend! That\'s what I\'m here for! 😊',
                'My pleasure! If you need anything, I\'m here. 💙',
                'You\'re welcome! Wishing you a beautiful day! ✨',
              ]
            : [
                'De rien, mon ami! C\'est avec plaisir! Si vous avez besoin de quoi que ce soit, je suis là. 😊',
                'Avec plaisir! Je suis là si vous avez besoin de quoi que ce soit. 💙',
                'De rien! Je vous souhaite une merveilleuse journée! ✨',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String _getLonelyResponse(String language) {
    final responses = language == 'ar'
        ? [
            'أنا هنا يا صديقي! مش لوحدك. اتصل حد بتحبه就说说话. 💙',
            'كلنا محتاجين ناس حواليتنا! كلم حد من عيلتك أو صاحبك. 📞',
            'الوحدة صعبة، بس أنت مش لوحدك أبداً. أنا هنا اسمعك! 🤗',
          ]
        : language == 'en'
            ? [
                'I\'m here, friend! You\'re not alone. Call someone you love and chat. 💙',
                'We all need people around us! Call family or a friend. 📞',
                'Loneliness is hard, but you\'re never alone. I\'m here to listen! 🤗',
              ]
            : [
                'Je suis là, mon ami! Vous n\'êtes pas seul. Appelez quelqu\'un que vous aimez et parlez. 💙',
                'Nous avons tous besoin de gens autour de nous! Appelez votre famille ou un ami. 📞',
                'La solitude est difficile, mais vous n\'êtes jamais seul. Je suis là pour vous écouter! 🤗',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String _getFamilyResponse(String language) {
    final responses = language == 'ar'
        ? [
            'العيلة نعمة! كلم حد منهم وقله "بحبك". ❤️',
            'أهلك هم دلوقتي! الإتصال بيهم بيفرحهم جداً. 📱',
            'العائلة هي كل حاجة! حاول تزورهم أو تتصل بيهم. 💕',
          ]
        : language == 'en'
            ? [
                'Family is a blessing! Call one of them and say "I love you". ❤️',
                'Your loved ones are here for you! Calling them makes them so happy. 📱',
                'Family is everything! Try to visit or call them. 💕',
              ]
            : [
                'La famille est une bénédiction! Appelez l\'un d\'eux et dites-lui "Je t\'aime". ❤️',
                'Vos proches sont là pour vous! Les appeler les rend si heureux. 📱',
                'La famille c\'est tout! Essayez de leur rendre visite ou de les appeler. 💕',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String _getGeneralResponse(String language) {
    final responses = language == 'ar'
        ? [
            'أنا بحبك! قولي إيه اللي عندك النهارده؟ 😊',
            'صباح الخير يا صاح! عايز نتكلم عن إيه؟ 🌟',
            'يا مرحبا! أنا هنا عشانك. قولي إيه الأخبار؟ ☀️',
            'نورت! عامل إيه؟ عايز مساعدة في إيه؟ 💙',
          ]
        : language == 'en'
            ? [
                'I love you! Tell me how your day is going? 😊',
                'Good day, friend! What would you like to talk about? 🌟',
                'Hello there! I\'m here for you. What\'s new? ☀️',
                'Hey! How are you? Need help with something? 💙',
              ]
            : [
                'Je t\'aime! Parlez-moi de votre journée? 😊',
                'Bonne journée, mon ami! De quoi aimeriez-vous parler? 🌟',
                'Bonjour! Je suis là pour vous. Quoi de neuf? ☀️',
                'Salut! Comment allez-vous? Besoin d\'aide avec quelque chose? 💙',
              ];

    return responses[DateTime.now().minute % responses.length];
  }

  static String getGameRecommendation(String language) {
    final games = language == 'ar'
        ? [
            '🎮 لعبة الذاكرة - ممتازة لتحسين الذاكرة!',
            '🔢 تحدي الرياضيات - يحافظ على نشاط عقلك!',
            '🎨 لعبة الألوان - ممتعة ومفيدة لسرعة الاستجابة!',
            '❌⭕ لعبة إكس أو - كلاسيكية ومسلية!',
            '🧩 لعبة الشطرنج - تتطلب تفكير!',
            '🃏 لعبة الت matching - تقوي الذاكرة!',
          ]
        : language == 'en'
            ? [
                '🎮 Memory Match - excellent for improving memory!',
                '🔢 Math Challenge - keeps your mind active!',
                '🎨 Color Match - fun and great for quick responses!',
                '❌⭕ Tic Tac Toe - classic and entertaining!',
                '🧩 Puzzle Game - requires thinking!',
                '🃏 Matching Game - strengthens memory!',
              ]
            : [
                '🎮 Jeu de Mémoire - excellent pour améliorer la mémoire!',
                '🔢 Défi Maths - garde votre esprit actif!',
                '🎨 Jeu de Couleurs - amusant et excellent pour les réflexes!',
                '❌⭕ Morpion - classique et divertissant!',
                '🧩 Jeu de Puzzle - demande de la réflexion!',
                '🃏 Jeu de Correspondance - renforce la mémoire!',
              ];

    return games[DateTime.now().minute % games.length];
  }

  static String getDailyMotivation(String language) {
    final motivations = language == 'ar'
        ? [
            '🌟 كل يوم جديد هو فرصة جديدة! أنت أقوى مما تتخيل!',
            '💪 خطواتك الصغيرة بتوصلك لمكان كبير.继续保持努力!',
            '❤️ صحتك هي أغلى حاجة عندك. اهتم بيها كل يوم!',
            '🌈 بعد كل يوم صعب، يوم حلو بييجي. استنى الفرحة!',
            '👴 أنت ملهم لأسرتك كلها! دا دورك العظيم.',
            '✨ الحياة جميلة لو بصينا ليها بعين حلوة. ابتسم!',
            '🏃 الحركة、民族 وثقتك，强在哪里؟ حافظ على صحتك!',
          ]
        : language == 'en'
            ? [
                '🌟 Every new day is a new opportunity! You\'re stronger than you think!',
                '💪 Your small steps lead to big places. Keep going!',
                '❤️ Your health is your most precious treasure. Take care of it!',
                '🌈 After every hard day, a good one comes. Wait for the joy!',
                '👴 You inspire your whole family! That\'s your great role.',
                '✨ Life is beautiful if we look at it with kind eyes. Smile!',
                '🏃 Keep moving! Activity is the secret of youth.',
              ]
            : [
                '🌟 Chaque nouveau jour est une nouvelle opportunité! Vous êtes plus fort que vous ne le pensez!',
                '💪 Vos petits pas vous mènent loin. Continuez!',
                '❤️ Votre santé est votre trésor le plus précieux. Prenez-en soin!',
                '🌈 Après chaque jour difficile, un bon jour arrive. Attendez la joie!',
                '👴 Vous inspirez toute votre famille! C\'est votre grand rôle.',
                '✨ La vie est belle si on la regarde avec de beaux yeux. Souriez!',
                '🏃 Bougez! L\'activité est le secret de la jeunesse.',
              ];

    return motivations[DateTime.now().day % motivations.length];
  }

  static String getHealthTip(String language) {
    final tips = language == 'ar'
        ? [
            '💧 اشرب 8 أكواب مي يومياً - ده السر في نضارة البشرة!',
            '🚶 امشي 15 دقيقة كل يوم - هتحس ب الفرق في أسبوع!',
            '😴 نم 7-8 ساعات - النوم الجيد بيريح الجسم والدماغ.',
            '☀️ اقعد على الشمس 10 دقائق الصبح - مفيد للعظام!',
            '🥗 كل فواكه وخضروات - فيها فيتامينات مهمة جداً.',
            '📱 قلل وقت الشاشات - عيونك بتتحتاجراحة.',
            '🧠 العب ألعاب عقلية كل يوم - بتحافظ على صفاء الذهن.',
            '💊 خد أدويتك في ميعادها - دا مهم جداً لصحة!',
          ]
        : language == 'en'
            ? [
                '💧 Drink 8 glasses of water daily - that\'s the secret to glowing skin!',
                '🚶 Walk 15 minutes every day - you\'ll feel the difference in a week!',
                '😴 Sleep 7-8 hours - good sleep rests both body and brain.',
                '☀️ Sit in the sun for 10 minutes in the morning - great for bones!',
                '🥗 Eat fruits and vegetables - they have very important vitamins.',
                '📱 Reduce screen time - your eyes need rest.',
                '🧠 Play brain games every day - it keeps your mind sharp.',
                '💊 Take your medicine on time - this is very important for your health!',
              ]
            : [
                '💧 Buvez 8 verres d\'eau par jour - c\'est le secret d\'une peau éclatante!',
                '🚶 Marchez 15 minutes chaque jour - vous sentirez la différence en une semaine!',
                '😴 Dormez 7-8 heures - le bon sommeil repose le corps et le cerveau.',
                '☀️ Asseyez-vous au soleil 10 minutes le matin - excellent pour les os!',
                '🥗 Mangez des fruits et légumes - ils contiennent des vitamines très importantes.',
                '📱 Réduisez le temps d\'écran - vos yeux ont besoin de repos.',
                '🧠 Jouez à des jeux cérébraux chaque jour - ça garde l\'esprit vif.',
                '💊 Prenez vos médicaments à l\'heure - c\'est très important pour votre santé!',
              ];

    return tips[DateTime.now().hour % tips.length];
  }
}
