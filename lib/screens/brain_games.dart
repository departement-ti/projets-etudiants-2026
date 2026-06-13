import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/screens/hidden_object_game.dart';
import 'package:mymeds_app/services/autonomy_score_service.dart';

class BrainGamesScreen extends StatelessWidget {
  const BrainGamesScreen({super.key});

  static Future<void> saveCognitiveScore(
      String gameName, double score, double maxScore) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) return;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('CognitiveScores')
          .add({
        'game': gameName,
        'score': score,
        'maxScore': maxScore,
        'date': DateTime.now().toIso8601String(),
      });

      await AutonomyScoreService().calculateScore(user.email!);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.brainGames),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? constraints.maxWidth * 0.05 : 16),
            child: isWide
                ? _buildWideLayout(context)
                : _buildNarrowLayout(context),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final t = translation(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildGameCard(
              context: context,
              icon: Icons.grid_4x4,
              title: t.gameMemoryMatch,
              description: t.gameMemoryMatchDesc,
              color: Colors.blue,
              gameWidget: const MemoryGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            _buildGameCard(
              context: context,
              icon: Icons.calculate,
              title: t.gameMathChallenge,
              description: t.gameMathChallengeDesc,
              color: Colors.green,
              gameWidget: const MathGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            _buildGameCard(
              context: context,
              icon: Icons.touch_app,
              title: t.gameReactionTest,
              description: t.gameReactionTestDesc,
              color: Colors.orange,
              gameWidget: const ReactionGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            _buildGameCard(
              context: context,
              icon: Icons.psychology,
              title: t.gameColorMatch,
              description: t.gameColorMatchDesc,
              color: Colors.purple,
              gameWidget: const ColorMatchGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            _buildGameCard(
              context: context,
              icon: Icons.spellcheck,
              title: t.gameWordScramble,
              description: t.gameWordScrambleDesc,
              color: Colors.teal,
              gameWidget: const WordScrambleGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            _buildGameCard(
              context: context,
              icon: Icons.numbers,
              title: t.gameSequenceMemory,
              description: t.gameSequenceMemoryDesc,
              color: Colors.indigo,
              gameWidget: const SequenceGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            _buildGameCard(
              context: context,
              icon: Icons.grid_3x3,
              title: t.gameTicTacToe,
              description: t.gameTicTacToeDesc,
              color: Colors.red,
              gameWidget: const TicTacToeGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            _buildGameCard(
              context: context,
              icon: Icons.memory,
              title: 'Pattern Memory',
              description: 'Repeat the color sequence to train memory',
              color: Colors.pink,
              gameWidget: const PatternMemoryGame(),
              width: (MediaQuery.of(context).size.width - 80) / 2,
            ),
            if (!kIsWeb)
              _buildGameCard(
                context: context,
                icon: Icons.search,
                title: t.gameHiddenObject,
                description: t.gameHiddenObjectDesc,
                color: Colors.deepPurple,
                gameWidget: const HiddenObjectGame(),
                width: (MediaQuery.of(context).size.width - 80) / 2,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    final t = translation(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGameCard(
          context: context,
          icon: Icons.grid_4x4,
          title: t.gameMemoryMatch,
          description: t.gameMemoryMatchDesc,
          color: Colors.blue,
          gameWidget: const MemoryGame(),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context: context,
          icon: Icons.calculate,
          title: t.gameMathChallenge,
          description: t.gameMathChallengeDesc,
          color: Colors.green,
          gameWidget: const MathGame(),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context: context,
          icon: Icons.touch_app,
          title: t.gameReactionTest,
          description: t.gameReactionTestDesc,
          color: Colors.orange,
          gameWidget: const ReactionGame(),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context: context,
          icon: Icons.psychology,
          title: t.gameColorMatch,
          description: t.gameColorMatchDesc,
          color: Colors.purple,
          gameWidget: const ColorMatchGame(),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context: context,
          icon: Icons.spellcheck,
          title: t.gameWordScramble,
          description: t.gameWordScrambleDesc,
          color: Colors.teal,
          gameWidget: const WordScrambleGame(),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context: context,
          icon: Icons.numbers,
          title: t.gameSequenceMemory,
          description: t.gameSequenceMemoryDesc,
          color: Colors.indigo,
          gameWidget: const SequenceGame(),
        ),
        const SizedBox(height: 16),
        if (!kIsWeb)
          _buildGameCard(
            context: context,
            icon: Icons.search,
            title: t.gameHiddenObject,
            description: t.gameHiddenObjectDesc,
            color: Colors.deepPurple,
            gameWidget: const HiddenObjectGame(),
          ),
        const SizedBox(height: 16),
        _buildGameCard(
          context: context,
          icon: Icons.grid_3x3,
          title: t.gameTicTacToe,
          description: t.gameTicTacToeDesc,
          color: Colors.red,
          gameWidget: const TicTacToeGame(),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          context: context,
          icon: Icons.memory,
          title: 'Pattern Memory',
          description: 'Repeat the color sequence to train memory',
          color: Colors.pink,
          gameWidget: const PatternMemoryGame(),
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Widget gameWidget,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => gameWidget),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(7, 82, 96, 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  List<String> cards = [];
  List<bool> revealed = [];
  List<bool> matched = [];
  int moves = 0;
  int pairs = 0;
  int? firstIndex;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final emojis = ['🍎', '🍊', '🍋', '🍇', '🍓', '🫐', '🍒', '🥝'];
    cards = [...emojis, ...emojis]..shuffle();
    revealed = List.filled(16, false);
    matched = List.filled(16, false);
    moves = 0;
    pairs = 0;
    firstIndex = null;
  }

  void _onCardTap(int index) {
    if (isChecking || matched[index] || revealed[index]) return;

    setState(() => revealed[index] = true);

    if (firstIndex == null) {
      firstIndex = index;
    } else {
      moves++;
      if (cards[firstIndex!] == cards[index]) {
        setState(() {
          matched[firstIndex!] = true;
          matched[index] = true;
          pairs++;
          firstIndex = null;
        });
        if (pairs == 8) _showWinDialog();
      } else {
        isChecking = true;
        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() {
            revealed[firstIndex!] = false;
            revealed[index] = false;
            firstIndex = null;
            isChecking = false;
          });
        });
      }
    }
  }

  void _showWinDialog() {
    final t = translation(context);
    BrainGamesScreen.saveCognitiveScore('Mémoire', 100, 100);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🎉 ${t.gameCongratulations}'),
        content: Text('${t.gameYouWon} $moves ${t.gameMoves}!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _initGame());
            },
            child: Text(t.gamePlayAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gameMemoryMatch),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double padding = constraints.maxWidth > 500 ? 32 : 16;
          double cardSize = (constraints.maxWidth - padding * 2 - 24) / 4;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$moves ${t.gameMoves} | $pairs/8',
                    style: GoogleFonts.poppins(fontSize: 16)),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: 16,
                      itemBuilder: (ctx, i) => GestureDetector(
                        onTap: () => _onCardTap(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: matched[i]
                                ? Colors.green[100]
                                : revealed[i]
                                    ? Colors.white
                                    : const Color.fromRGBO(7, 82, 96, 1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: revealed[i] || matched[i]
                                ? Text(cards[i],
                                    style: const TextStyle(fontSize: 28))
                                : const Icon(Icons.question_mark,
                                    color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MathGame extends StatefulWidget {
  const MathGame({super.key});

  @override
  State<MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> {
  int score = 0;
  int questionNum = 0;
  String question = '';
  int answer = 0;
  List<int> options = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    questionNum++;
    int op = random.nextInt(4);
    int a = random.nextInt(12) + 1;
    int b = random.nextInt(12) + 1;

    switch (op) {
      case 0:
        question = '$a + $b = ?';
        answer = a + b;
        break;
      case 1:
        question = '$a - $b = ?';
        answer = a - b;
        break;
      case 2:
        question = '$a × $b = ?';
        answer = a * b;
        break;
      case 3:
        a = (random.nextInt(10) + 1) * b;
        question = '$a ÷ $b = ?';
        answer = a ~/ b;
        break;
    }
    options = _generateOptions(answer);
  }

  List<int> _generateOptions(int correct) {
    Set<int> opts = {correct};
    while (opts.length < 4) {
      int wrong = correct + random.nextInt(10) - 5;
      if (wrong > 0 && wrong != correct) opts.add(wrong);
    }
    List<int> list = opts.toList()..shuffle();
    return list;
  }

  void _checkAnswer(int selected) {
    setState(() {
      if (selected == answer) {
        score += 10;
      } else {
        score = max(0, score - 5);
      }
      _generateQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gameMathChallenge),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 500;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: EdgeInsets.all(isWide ? 32 : 16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(7, 82, 96, 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('Question #$questionNum',
                        style: GoogleFonts.poppins(color: Colors.white70)),
                    const SizedBox(height: 16),
                    Text(question,
                        style: GoogleFonts.poppins(
                            fontSize: isWide ? 40 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$t.gameScore: $score',
                    style: GoogleFonts.poppins(fontSize: 18)),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: isWide ? 4 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isWide ? 2 : 1.5,
                      children: options.map((opt) {
                        return FilledButton(
                          onPressed: () => _checkAnswer(opt),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                          ),
                          child: Text('$opt',
                              style: GoogleFonts.poppins(
                                  fontSize: isWide ? 24 : 20)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ReactionGame extends StatefulWidget {
  const ReactionGame({super.key});

  @override
  State<ReactionGame> createState() => _ReactionGameState();
}

class _ReactionGameState extends State<ReactionGame> {
  bool isWaiting = false;
  bool isReady = false;
  bool showResult = false;
  List<int> times = [];
  DateTime? startTime;

  void _startGame() {
    setState(() {
      isWaiting = true;
      isReady = false;
      showResult = false;
    });

    Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(3000)), () {
      if (isWaiting && mounted) {
        setState(() {
          isReady = true;
          startTime = DateTime.now();
        });
      }
    });
  }

  void _onTap() {
    if (!isWaiting) {
      _startGame();
      return;
    }

    DateTime tapTime = DateTime.now();

    if (isReady && startTime != null) {
      int reactionMs = tapTime.difference(startTime!).inMilliseconds;
      setState(() {
        times.add(reactionMs);
        showResult = true;
        isWaiting = false;
        isReady = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too early! Wait for green.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isWaiting = false);
    }
  }

  int get averageTime =>
      times.isEmpty ? 0 : (times.reduce((a, b) => a + b) ~/ times.length);

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gameReactionTest),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: _onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: isReady
              ? Colors.green
              : isWaiting
                  ? Colors.red
                  : Colors.grey[300],
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isReady
                        ? 'TAP NOW!'
                        : isWaiting
                            ? 'Wait...'
                            : t.gameTapToStart,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isReady ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (showResult) ...[
                    const SizedBox(height: 20),
                    Text('Last: ${times.last}ms',
                        style: GoogleFonts.poppins(
                            fontSize: 24, color: Colors.white)),
                    Text('Average: ${averageTime}ms',
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: Colors.white70)),
                    Text('Attempts: ${times.length}',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 20),
                    Text(t.gameTapToStart,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ColorMatchGame extends StatefulWidget {
  const ColorMatchGame({super.key});

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends State<ColorMatchGame>
    with SingleTickerProviderStateMixin {
  final List<String> colorNames = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Purple',
    'Orange',
    'Cyan',
    'Pink',
    'Lime',
    'Brown',
  ];
  final List<Color> palette = [
    Colors.red,
    Colors.blue,
    Colors.green,
    const Color(0xFFD4A017),
    Colors.purple,
    Colors.orange,
    Colors.cyan,
    Colors.pink,
    Colors.lime,
    Colors.brown,
  ];

  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  String currentWord = '';
  Color currentColor = Colors.black;
  Color targetColor = Colors.red;
  int score = 0;
  int streak = 0;
  int bestStreak = 0;
  int questionNum = 0;
  int lives = 3;
  bool gameOver = false;
  bool showingResult = false;
  bool? wasCorrect;
  double timeLeft = 5.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _nextQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    _timer?.cancel();
    final random = Random();
    int colorIdx = random.nextInt(palette.length);
    int wordIdx = random.nextInt(colorNames.length);
    // Ensure Stroop effect (color != word color)
    while (colorIdx == wordIdx) {
      wordIdx = random.nextInt(colorNames.length);
    }
    int targetIdx = random.nextInt(palette.length);
    setState(() {
      currentWord = colorNames[wordIdx];
      currentColor = palette[colorIdx];
      targetColor = palette[targetIdx];
      showingResult = false;
      wasCorrect = null;
      timeLeft = 5.0;
    });
    _animController.reset();
    _animController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        timeLeft -= 0.1;
        if (timeLeft <= 0) {
          timer.cancel();
          _timeUp();
        }
      });
    });
  }

  void _timeUp() {
    setState(() {
      lives--;
      streak = 0;
      showingResult = true;
      wasCorrect = false;
      if (lives <= 0) {
        gameOver = true;
      }
    });
    if (!gameOver) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _nextQuestion();
      });
    }
  }

  void _onAnswer(String guessColor) {
    _timer?.cancel();
    questionNum++;
    bool correct = currentColor.value == _colorNameToColor(guessColor).value;
    setState(() {
      showingResult = true;
      wasCorrect = correct;
      if (correct) {
        streak++;
        if (streak > bestStreak) bestStreak = streak;
        score += 10 + (streak * 2);
      } else {
        streak = 0;
        lives--;
        if (lives <= 0) gameOver = true;
      }
    });
    if (!gameOver) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _nextQuestion();
      });
    }
  }

  Color _colorNameToColor(String name) {
    switch (name) {
      case 'Red': return Colors.red;
      case 'Blue': return Colors.blue;
      case 'Green': return Colors.green;
      case 'Yellow': return const Color(0xFFD4A017);
      case 'Purple': return Colors.purple;
      case 'Orange': return Colors.orange;
      case 'Cyan': return Colors.cyan;
      case 'Pink': return Colors.pink;
      case 'Lime': return Colors.lime;
      case 'Brown': return Colors.brown;
      default: return Colors.black;
    }
  }

  void _restart() {
    setState(() {
      score = 0;
      streak = 0;
      bestStreak = 0;
      questionNum = 0;
      lives = 3;
      gameOver = false;
      showingResult = false;
    });
    _nextQuestion();
  }

  List<Color> _getAnswerColors() {
    // Generate 4 color buttons including the correct one
    final random = Random();
    final colors = <Color>[currentColor];
    while (colors.length < 4) {
      final c = palette[random.nextInt(palette.length)];
      if (!colors.any((x) => x.value == c.value)) {
        colors.add(c);
      }
    }
    colors.shuffle();
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    final targetColorName = colorNames[palette.indexOf(targetColor)];
    final answerColors = _getAnswerColors();

    if (gameOver) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.gameColorMatch),
          backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                const SizedBox(height: 16),
                Text('$t.gameScore: $score',
                    style: GoogleFonts.poppins(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Best Streak: $bestStreak',
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _restart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  icon: const Icon(Icons.replay),
                  label: Text('Play Again',
                      style: GoogleFonts.poppins(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.gameColorMatch),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(lives, (i) => const Icon(Icons.favorite, color: Colors.red, size: 20)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 6,
              color: timeLeft > 2
                  ? const Color.fromRGBO(7, 82, 96, 1)
                  : timeLeft > 1
                      ? Colors.orange
                      : Colors.red,
            ),
            ClipRRect(
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: timeLeft / 5.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timeLeft > 2
                        ? const Color.fromRGBO(7, 82, 96, 1)
                        : timeLeft > 1
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Q#$questionNum', style: GoogleFonts.poppins(color: Colors.grey)),
                  Text('Streak: $streak 🔥',
                      style: GoogleFonts.poppins(
                          color: const Color.fromRGBO(7, 82, 96, 1),
                          fontWeight: FontWeight.w600)),
                  Text('$t.gameScore: $score',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(7, 82, 96, 1))),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (showingResult)
                              Column(
                                children: [
                                  Icon(
                                    wasCorrect! ? Icons.check_circle : Icons.close,
                                    color: wasCorrect! ? Colors.green : Colors.red,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    wasCorrect! ? 'Correct! +${10 + (streak * 2)}' : 'Wrong!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: wasCorrect! ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            Text(
                              'Tap the color that matches:\n"$targetColorName"',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              currentWord,
                              style: GoogleFonts.poppins(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: currentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      ...answerColors.take(2).map((c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: _ColorButton(
                                color: c,
                                onTap: showingResult
                                    ? null
                                    : () => _onAnswer(
                                        colorNames[palette.indexOf(c)]),
                              ),
                            ),
                          )),
                    ],
                  ),
                  Row(
                    children: [
                      ...answerColors.skip(2).take(2).map((c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: _ColorButton(
                                color: c,
                                onTap: showingResult
                                    ? null
                                    : () => _onAnswer(
                                        colorNames[palette.indexOf(c)]),
                              ),
                            ),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;
  const _ColorButton({required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text('●',
              style: TextStyle(fontSize: 24, color: Colors.white)),
        ),
      ),
    );
  }
}

class WordScrambleGame extends StatefulWidget {
  const WordScrambleGame({super.key});

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  final List<List<String>> wordList = [
    ['MEDICINE', 'MENDICE'],
    ['HEALTH', 'HTAHLE'],
    ['DOCTOR', 'COROTD'],
    ['PHARMACY', 'HARMPYC'],
    ['SYRUP', 'PRYSU'],
    ['VIRUS', 'SURVI'],
    ['SLEEP', 'PEELS'],
    ['PAIN', 'NIAP'],
    ['FEVER', 'VEEFR'],
    ['COLD', 'LDCO'],
  ];

  String originalWord = '';
  String scrambledWord = '';
  int currentIndex = 0;
  int score = 0;
  final TextEditingController controller = TextEditingController();
  bool showingResult = false;
  bool wasCorrect = false;

  @override
  void initState() {
    super.initState();
    _nextWord();
  }

  void _nextWord() {
    if (currentIndex >= wordList.length) {
      _showFinalScore();
      return;
    }
    setState(() {
      originalWord = wordList[currentIndex][0];
      List<String> letters = wordList[currentIndex][1].split('')..shuffle();
      scrambledWord = letters.join();
      showingResult = false;
      controller.clear();
    });
  }

  void _checkAnswer() {
    String answer = controller.text.toUpperCase().trim();
    bool correct = answer == originalWord;
    setState(() {
      showingResult = true;
      wasCorrect = correct;
      if (correct) score += 10;
      currentIndex++;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _nextWord();
    });
  }

  void _showFinalScore() {
    final t = translation(context);
    BrainGamesScreen.saveCognitiveScore(
        'Mots mélangés', score.toDouble(), (wordList.length * 10).toDouble());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${t.gameCongratulations}'),
        content: Text('${t.gameYourScore}: $score/${wordList.length * 10}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                currentIndex = 0;
                score = 0;
              });
              _nextWord();
            },
            child: Text(t.gamePlayAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gameWordScramble),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 500;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 32 : 20),
              child: Column(
                children: [
                  Text('Word ${currentIndex + 1}/${wordList.length}',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text('$t.gameScore: $score',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(7, 82, 96, 1))),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(7, 82, 96, 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      scrambledWord,
                      style: GoogleFonts.poppins(
                        fontSize: isWide ? 48 : 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (showingResult)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: wasCorrect ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(wasCorrect ? Icons.check_circle : Icons.cancel,
                              color: wasCorrect ? Colors.green : Colors.red),
                          const SizedBox(width: 10),
                          Text(
                              wasCorrect
                                  ? t.gameCorrect
                                  : 'The word was: $originalWord',
                              style: GoogleFonts.poppins(
                                  color:
                                      wasCorrect ? Colors.green : Colors.red)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: isWide ? 400 : double.infinity,
                    child: TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Type the unscrambled word',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: showingResult ? null : _checkAnswer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: showingResult ? null : _checkAnswer,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                      padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 48 : 32, vertical: 14),
                    ),
                    child: Text('Submit',
                        style: GoogleFonts.poppins(fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SequenceGame extends StatefulWidget {
  const SequenceGame({super.key});

  @override
  State<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<SequenceGame> {
  List<int> sequence = [];
  List<int> userSequence = [];
  int level = 1;
  int score = 0;
  bool showingSequence = true;
  bool isUserTurn = false;
  int currentShowIndex = 0;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    sequence.add(Random().nextInt(9) + 1);
    _showSequence();
  }

  void _showSequence() {
    setState(() {
      showingSequence = true;
      isUserTurn = false;
      currentShowIndex = 0;
      userSequence = [];
    });

    for (int i = 0; i < sequence.length; i++) {
      Future.delayed(Duration(milliseconds: 600 * (i + 1)), () {
        if (mounted) setState(() => currentShowIndex = i + 1);
      });
    }

    Future.delayed(Duration(milliseconds: 600 * (sequence.length + 1)), () {
      if (mounted)
        setState(() {
          showingSequence = false;
          isUserTurn = true;
        });
    });
  }

  void _addNumber(int num) {
    if (!isUserTurn) return;
    setState(() => userSequence.add(num));
    if (userSequence.length == sequence.length) {
      _checkSequence();
    }
  }

  void _checkSequence() {
    bool correct = true;
    for (int i = 0; i < userSequence.length; i++) {
      if (userSequence[i] != sequence[i]) {
        correct = false;
        break;
      }
    }

    if (correct) {
      setState(() {
        score += level * 10;
        level++;
      });
      _startLevel();
    } else {
      _showGameOver();
    }
  }

  void _showGameOver() {
    final t = translation(context);
    BrainGamesScreen.saveCognitiveScore(
        'Séquence mémoire', score.toDouble(), 100);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.gameGameOver),
        content: Text('$t.gameScore: $score\n$t.gameLevel: $level'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                sequence = [];
                level = 1;
                score = 0;
                userSequence = [];
              });
              _startLevel();
            },
            child: Text(t.gamePlayAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gameSequenceMemory),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 500;
            double buttonSize = isWide ? 80 : 60;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('$t.gameLevel: $level',
                          style: GoogleFonts.poppins(fontSize: 16)),
                      Text('$t.gameScore: $score',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color.fromRGBO(7, 82, 96, 1))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: showingSequence
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Watch the sequence:',
                                  style:
                                      GoogleFonts.poppins(color: Colors.grey)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: List.generate(sequence.length, (i) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: i < currentShowIndex
                                          ? const Color.fromRGBO(7, 82, 96, 1)
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      i < currentShowIndex
                                          ? '${sequence[i]}'
                                          : '?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: i < currentShowIndex
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(t.gameYourTurn,
                                style: GoogleFonts.poppins(color: Colors.grey)),
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (userSequence.isNotEmpty)
                    Text('Your input: ${userSequence.join(' ')}',
                        style: GoogleFonts.poppins(fontSize: 16)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(9, (i) {
                          return SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: FilledButton(
                              onPressed:
                                  isUserTurn ? () => _addNumber(i + 1) : null,
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(7, 82, 96, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('${i + 1}',
                                  style: GoogleFonts.poppins(
                                      fontSize: isWide ? 24 : 20,
                                      fontWeight: FontWeight.bold)),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  String? winner;
  int playerScore = 0;
  int aiScore = 0;

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      winner = null;
    });
  }

  void _onTap(int index) {
    if (board[index].isNotEmpty || winner != null) return;

    setState(() => board[index] = currentPlayer);

    if (_checkWinner(board[index])) {
      setState(() {
        winner = currentPlayer;
        if (winner == 'X') playerScore++;
      });
      return;
    }

    if (!board.contains('')) {
      setState(() => winner = 'Draw');
      return;
    }

    setState(() => currentPlayer = 'O');
    Future.delayed(const Duration(milliseconds: 500), () => _aiMove());
  }

  void _aiMove() {
    if (winner != null) return;

    int? move = _getBestMove();
    if (move != null) {
      setState(() => board[move] = 'O');

      if (_checkWinner('O')) {
        setState(() {
          winner = 'O';
          aiScore++;
        });
      } else if (!board.contains('')) {
        setState(() => winner = 'Draw');
      } else {
        setState(() => currentPlayer = 'X');
      }
    }
  }

  int? _getBestMove() {
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'O';
        if (_checkWinner('O')) {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }

    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'X';
        if (_checkWinner('X')) {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }

    if (board[4].isEmpty) return 4;

    List<int> corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int i in corners) {
      if (board[i].isEmpty) return i;
    }

    return null;
  }

  bool _checkWinner(String player) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (var line in lines) {
      if (board[line[0]] == player &&
          board[line[1]] == player &&
          board[line[2]] == player) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gameTicTacToe),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 500;
            double boardSize = isWide
                ? constraints.maxWidth * 0.5
                : constraints.maxWidth * 0.85;
            boardSize = boardSize.clamp(250.0, 400.0);
            double cellSize = (boardSize - 16) / 3;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('You (X)', style: TextStyle(fontSize: 16)),
                          Text('$playerScore',
                              style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromRGBO(7, 82, 96, 1))),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('AI (O)', style: TextStyle(fontSize: 16)),
                          Text('$aiScore',
                              style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (winner != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: winner == 'X'
                            ? Colors.green[100]
                            : winner == 'O'
                                ? Colors.red[100]
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        winner == 'Draw'
                            ? t.gameDraw
                            : winner == 'X'
                                ? t.gameYouWon
                                : 'AI Wins!',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(9, (i) {
                        return GestureDetector(
                          onTap: () => _onTap(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                board[i],
                                style: GoogleFonts.poppins(
                                  fontSize: isWide ? 48 : 36,
                                  fontWeight: FontWeight.bold,
                                  color: board[i] == 'X'
                                      ? const Color.fromRGBO(7, 82, 96, 1)
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _resetGame,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                    ),
                    child: Text(t.gamePlayAgain,
                        style: GoogleFonts.poppins(fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class PatternMemoryGame extends StatefulWidget {
  const PatternMemoryGame({super.key});

  @override
  State<PatternMemoryGame> createState() => _PatternMemoryGameState();
}

class _PatternMemoryGameState extends State<PatternMemoryGame>
    with SingleTickerProviderStateMixin {
  final List<Color> tileColors = [
    const Color(0xFFFF1744), // Red
    const Color(0xFF2979FF), // Blue
    const Color(0xFF00E676), // Green
    const Color(0xFFFFEA00), // Yellow
  ];

  late AnimationController _flashController;
  List<int> sequence = [];
  List<int> userInput = [];
  int currentRound = 1;
  int score = 0;
  bool showingSequence = false;
  bool isUserTurn = false;
  bool gameOver = false;
  int? highlightedTile;
  int highestScore = 0;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startNewGame();
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _startNewGame() {
    sequence = [];
    userInput = [];
    score = 0;
    currentRound = 1;
    gameOver = false;
    _addToSequence();
  }

  void _addToSequence() {
    final random = Random();
    sequence.add(random.nextInt(4));
    _playSequence();
  }

  Future<void> _playSequence() async {
    setState(() {
      showingSequence = true;
      isUserTurn = false;
      userInput = [];
    });

    await Future.delayed(const Duration(seconds: 1));
    for (final tile in sequence) {
      setState(() => highlightedTile = tile);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => highlightedTile = null);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      showingSequence = false;
      isUserTurn = true;
    });
  }

  void _onTileTap(int tileIndex) {
    if (!isUserTurn || gameOver) return;

    setState(() => highlightedTile = tileIndex);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => highlightedTile = null);

      final expectedTile = sequence[userInput.length];
      if (tileIndex == expectedTile) {
        userInput.add(tileIndex);
        if (userInput.length == sequence.length) {
          setState(() {
            score += currentRound * 10;
            currentRound++;
          });
          _addToSequence();
        }
      } else {
        setState(() {
          gameOver = true;
          isUserTurn = false;
          if (score > highestScore) highestScore = score;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = translation(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Memory'),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: gameOver
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.memory, size: 80, color: Colors.amber),
                    const SizedBox(height: 16),
                    Text('$t.gameScore: $score',
                        style: GoogleFonts.poppins(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Round reached: $currentRound',
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: Colors.grey[600])),
                    if (highestScore > 0) ...[
                      const SizedBox(height: 8),
                      Text('Best: $highestScore',
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey[400])),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _startNewGame,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                      ),
                      icon: const Icon(Icons.replay),
                      label: Text(t.gamePlayAgain,
                          style: GoogleFonts.poppins(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = (constraints.maxWidth - 48) / 2 - 8;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Round $currentRound',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(7, 82, 96, 1))),
                              Text('$t.gameScore: $score',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, color: Colors.grey[600])),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: showingSequence
                                  ? Colors.orange.withAlpha(50)
                                  : isUserTurn
                                      ? Colors.green.withAlpha(50)
                                      : Colors.grey.withAlpha(50),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              showingSequence
                                  ? 'Watch...'
                                  : isUserTurn
                                      ? 'Your Turn!'
                                      : 'Get ready',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: showingSequence
                                    ? Colors.orange
                                    : isUserTurn
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(4, (index) {
                            final isHighlighted = highlightedTile == index;
                            return GestureDetector(
                              onTap: isUserTurn && !gameOver
                                  ? () => _onTileTap(index)
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: tileSize,
                                height: tileSize,
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? tileColors[index]
                                      : tileColors[index].withAlpha(100),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: tileColors[index],
                                    width: isHighlighted ? 4 : 2,
                                  ),
                                  boxShadow: isHighlighted
                                      ? [
                                          BoxShadow(
                                            color: tileColors[index].withAlpha(60),
                                            blurRadius: 20,
                                            spreadRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: isHighlighted
                                      ? Icon(Icons.brightness_1,
                                          size: 40, color: Colors.white)
                                      : Text(
                                          '${index + 1}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: tileColors[index],
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
