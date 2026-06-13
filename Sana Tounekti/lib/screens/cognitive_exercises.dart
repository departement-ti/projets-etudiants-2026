import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/language_constants.dart';
import 'package:mymeds_app/services/cognitive_service.dart';

class CognitiveExercisesScreen extends StatefulWidget {
  const CognitiveExercisesScreen({super.key});
  @override
  State<CognitiveExercisesScreen> createState() => _CognitiveExercisesScreenState();
}

class _CognitiveExercisesScreenState extends State<CognitiveExercisesScreen> {
  String? _activeTest;
  int _score = 0;
  int _questionIndex = 0;
  int _correctAnswers = 0;
  Stopwatch _timer = Stopwatch();
  int _reactionStartMs = 0;
  bool _testComplete = false;
  String _feedback = '';

  final _cognitiveService = CognitiveService();
  final _random = Random();

  final List<String> _memoryWords = ['Sun', 'Tree', 'Book', 'Cat', 'Water', 'House', 'Apple', 'Chair'];
  List<String> _shownWords = [];
  List<String> _answerOptions = [];
  String _correctAnswer = '';
  int _currentMathA = 0;
  int _currentMathB = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).cognitiveExercises, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF5B5EA6),
      ),
      body: _activeTest == null
          ? _buildMenu()
          : _testComplete
              ? _buildResults()
              : _buildTest(),
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(translation(context).dailyBrainTraining, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF5B5EA6))),
          const SizedBox(height: 4),
          Text(translation(context).chooseExercise, style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),
          _buildTestCard(
            icon: Icons.memory,
            title: translation(context).memoryTest,
            description: 'Remember a list of words and identify them later',
            color: Colors.blue,
            onTap: () => _startMemoryTest(),
          ),
          const SizedBox(height: 12),
          _buildTestCard(
            icon: Icons.speed,
            title: translation(context).reactionSpeed,
            description: 'Tap as fast as possible when the screen changes color',
            color: Colors.red,
            onTap: () => _startReactionTest(),
          ),
          const SizedBox(height: 12),
          _buildTestCard(
            icon: Icons.calculate,
            title: translation(context).mathChallenge,
            description: 'Solve simple math problems quickly',
            color: Color(0xFF5B5EA6),
            onTap: () => _startMathTest(),
          ),
          const SizedBox(height: 12),
          _buildTestCard(
            icon: Icons.visibility,
            title: translation(context).attentionTest,
            description: 'Find matching patterns and colors',
            color: Colors.orange,
            onTap: () => _startAttentionTest(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required IconData icon, required String title, required String description,
    required Color color, required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _startMemoryTest() {
    _shownWords = List.from(_memoryWords)..shuffle();
    _shownWords = _shownWords.take(5).toList();
    _answerOptions.clear();
    _answerOptions.addAll(_shownWords);
    _answerOptions.addAll(['Dog', 'Car', 'Flower']);
    _answerOptions.shuffle();
    setState(() {
      _activeTest = 'memory';
      _questionIndex = 0;
      _correctAnswers = 0;
      _score = 0;
      _testComplete = false;
    });
  }

  void _startReactionTest() {
    setState(() {
      _activeTest = 'reaction';
      _score = 0;
      _questionIndex = 0;
      _testComplete = false;
      _reactionStartMs = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _startMathTest() {
    _generateMathProblem();
    setState(() {
      _activeTest = 'math';
      _questionIndex = 0;
      _correctAnswers = 0;
      _score = 0;
      _testComplete = false;
    });
  }

  void _startAttentionTest() {
    setState(() {
      _activeTest = 'attention';
      _questionIndex = 0;
      _correctAnswers = 0;
      _score = 0;
      _testComplete = false;
    });
  }

  Widget _buildTest() {
    switch (_activeTest) {
      case 'memory':
        return _buildMemoryTest();
      case 'reaction':
        return _buildReactionTest();
      case 'math':
        return _buildMathTest();
      case 'attention':
        return _buildAttentionTest();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMemoryTest() {
    if (_questionIndex == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.memory, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(translation(context).memorizeWords, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16, runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _shownWords.map((w) => Card(
                  color: Colors.blue.withAlpha(15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Text(w, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blue)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => setState(() => _questionIndex = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(translation(context).imReady, style: GoogleFonts.poppins(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    final current = _answerOptions[_questionIndex - 1];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Question ${_questionIndex}/${_answerOptions.length}',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(translation(context).wasWordInList,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: Text(current, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnswerButton(translation(context).no, Colors.red, () => _checkMemoryAnswer(false, current)),
                const SizedBox(width: 20),
                _buildAnswerButton(translation(context).yes, Color(0xFF5B5EA6), () => _checkMemoryAnswer(true, current)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _checkMemoryAnswer(bool yes, String word) {
    final correct = _shownWords.contains(word) == yes;
    if (correct) _correctAnswers++;
    if (_questionIndex >= _answerOptions.length) {
      _score = _correctAnswers * 2;
      _finishTest('memory');
    } else {
      setState(() => _questionIndex++);
    }
  }

  Color _reactionColor = Colors.blue;
  int _reactionStart = 0;
  List<int> _reactionTimes = [];

  Widget _buildReactionTest() {
    return GestureDetector(
      onTap: _questionIndex == 0 ? null : _handleReactionTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: _reactionColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_questionIndex == 0) ...[
                const Icon(Icons.speed, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                Text(translation(context).tapWhenGreen,
                    style: GoogleFonts.poppins(fontSize: 22, color: Colors.white)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _questionIndex = 1; _reactionColor = Colors.blue; });
                    Future.delayed(Duration(seconds: 1 + _random.nextInt(3)), () {
                      if (mounted && _questionIndex > 0) {
                        setState(() {
                          _reactionColor = Color(0xFF5B5EA6);
                          _reactionStart = DateTime.now().millisecondsSinceEpoch;
                        });
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(translation(context).startBtn, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ] else
                Text(
                  _reactionColor == Color(0xFF5B5EA6) ? translation(context).tapNow : translation(context).wait,
                  style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReactionTap() {
    if (_reactionColor == Color(0xFF5B5EA6)) {
      int time = DateTime.now().millisecondsSinceEpoch - _reactionStart;
      _reactionTimes.add(time);
      if (_reactionTimes.length >= 5) {
        _score = (1000 - (_reactionTimes.reduce((a, b) => a + b) ~/ 5)).clamp(0, 1000) ~/ 10;
        _finishTest('reaction', reactionMs: _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length);
      } else {
        setState(() { _reactionColor = Colors.blue; });
        Future.delayed(Duration(seconds: 1 + _random.nextInt(3)), () {
          if (mounted) {
            setState(() {
              _reactionColor = Color(0xFF5B5EA6);
              _reactionStart = DateTime.now().millisecondsSinceEpoch;
            });
          }
        });
      }
    }
  }

  void _generateMathProblem() {
    _currentMathA = _random.nextInt(50) + 1;
    _currentMathB = _random.nextInt(30) + 1;
  }

  Widget _buildMathTest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Question ${_questionIndex + 1}/5',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            Text('$_currentMathA + $_currentMathB = ?',
                style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                hintText: translation(context).answer,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (value) {
                if (int.tryParse(value) == _currentMathA + _currentMathB) _correctAnswers++;
                if (_questionIndex >= 4) {
                  _score = _correctAnswers * 2;
                  _finishTest('math');
                } else {
                  setState(() { _questionIndex++; _generateMathProblem(); });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _patternWord = '';
  String _patternMatch = '';

  Widget _buildAttentionTest() {
    if (_patternWord.isEmpty) {
      _patternWord = ['RED', 'BLUE', 'GREEN', 'ORANGE', 'PURPLE'][_random.nextInt(5)];
      _patternMatch = _patternWord;
    }

    final displayColors = [Colors.red, Colors.blue, Color(0xFF5B5EA6), Colors.orange, Colors.purple];
    final displayColor = displayColors[_random.nextInt(5)];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Question ${_questionIndex + 1}/8',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Does the word match the color?',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Text(
              _patternWord,
              style: GoogleFonts.poppins(
                fontSize: 48, fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnswerButton(translation(context).no, Colors.red, () => _checkAttention(false)),
                const SizedBox(width: 20),
                _buildAnswerButton(translation(context).yes, Color(0xFF5B5EA6), () => _checkAttention(true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _checkAttention(bool match) {
    final colorMap = {
      'RED': Colors.red, 'BLUE': Colors.blue, 'GREEN': Color(0xFF5B5EA6),
      'ORANGE': Colors.orange, 'PURPLE': Colors.purple,
    };
    if (match) _correctAnswers++;
    if (_questionIndex >= 7) {
      _score = _correctAnswers * 1;
      _finishTest('attention');
    } else {
      setState(() {
        _questionIndex++;
        _patternWord = ['RED', 'BLUE', 'GREEN', 'ORANGE', 'PURPLE'][_random.nextInt(5)];
      });
    }
  }

  Widget _buildAnswerButton(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 130, height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _finishTest(String testType, {int reactionMs = 0}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      await _cognitiveService.submitTestResult(
        userEmail: user!.email!,
        testType: testType,
        score: _score.toDouble(),
        maxScore: 10.0,
        reactionTimeMs: reactionMs,
        correctAnswers: _correctAnswers,
        totalQuestions: _questionIndex + 1,
      );
    }

    setState(() {
      _testComplete = true;
      _feedback = _score >= 8 ? translation(context).excellent : _score >= 5 ? translation(context).goodJob : translation(context).keepPracticing;
    });
  }

  Widget _buildResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _score >= 8 ? Icons.emoji_events : _score >= 5 ? Icons.star : Icons.favorite,
              size: 80,
              color: _score >= 8 ? Colors.amber : _score >= 5 ? Color(0xFF5B5EA6) : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(_feedback, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(translation(context).scoreOutOf10(_score), style: GoogleFonts.roboto(fontSize: 20, color: Colors.grey)),
            if (_correctAnswers > 0)
              Text(translation(context).correctAnswers(_correctAnswers), style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() { _activeTest = null; _testComplete = false; _score = 0; _correctAnswers = 0; _questionIndex = 0; _patternWord = ''; _reactionTimes.clear(); _reactionStart = 0; }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5EA6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(translation(context).backToExercises, style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
