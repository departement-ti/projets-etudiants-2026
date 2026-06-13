import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mymeds_app/components/language_constants.dart';

class HiddenObjectGame extends StatefulWidget {
  const HiddenObjectGame({super.key});

  @override
  State<HiddenObjectGame> createState() => _HiddenObjectGameState();
}

class _HiddenObjectGameState extends State<HiddenObjectGame> {
  int _currentStep =
      0; // 0: selection, 1: preparation, 2: search, 3: photo, 4: result

  String _selectedObject = '';
  String _selectedRoom = '';
  int _preparationSeconds = 0;
  int _searchSeconds = 0;
  int _hintsUsed = 0;
  String _photoPath = '';

  Timer? _preparationTimer;
  Timer? _searchTimer;

  bool _objectFound = false;

  final List<Map<String, dynamic>> _objects = [
    {
      'name': 'Clés',
      'icon': Icons.vpn_key,
      'emoji': '🔑',
      'places': ['table', 'étagère', 'poche', 'cintre']
    },
    {
      'name': 'Lunettes',
      'icon': Icons.visibility,
      'emoji': '👓',
      'places': ['table de nuit', 'canapé', 'salle de bain', 'étagère']
    },
    {
      'name': 'Téléphone',
      'icon': Icons.phone_android,
      'emoji': '📱',
      'places': ['lit', 'canapé', 'bureau', 'cuisine']
    },
    {
      'name': 'Livre',
      'icon': Icons.menu_book,
      'emoji': '📖',
      'places': ['étagère', 'table', 'lit', 'fauteuil']
    },
    {
      'name': 'Télécommande',
      'icon': Icons.tv,
      'emoji': '📺',
      'places': ['canapé', 'table basse', 'fauteuil', 'étagère']
    },
    {
      'name': 'Montre',
      'icon': Icons.watch,
      'emoji': '⌚',
      'places': ['table de nuit', 'étagère', 'bureau', 'table']
    },
    {
      'name': 'Stylo',
      'icon': Icons.edit,
      'emoji': '🖊️',
      'places': ['tiroir', 'bureau', 'table', 'étagère']
    },
    {
      'name': 'Bouteille d\'eau',
      'icon': Icons.water_drop,
      'emoji': '💧',
      'places': ['réfrigérateur', 'table', ' comptoir', 'évier']
    },
    {
      'name': 'Portefeuille',
      'icon': Icons.wallet,
      'emoji': '👛',
      'places': ['sac', 'étagère', 'table', 'cintre']
    },
    {
      'name': 'Mouchoirs',
      'icon': Icons.delete_outline,
      'emoji': '🧻',
      'places': ['tiroir', 'sac', 'table', 'étagère']
    },
    {
      'name': 'Casquette',
      'icon': Icons.sports_golf,
      'emoji': '🧢',
      'places': ['cintre', 'étagère', 'patère', 'canapé']
    },
    {
      'name': 'Sac',
      'icon': Icons.shopping_bag,
      'emoji': '🛍️',
      'places': ['sol', 'étagère', 'cintre', 'fauteuil']
    },
  ];

  final List<Map<String, dynamic>> _rooms = [
    {
      'name': 'Salon',
      'icon': Icons.weekend,
      'emoji': '🛋️',
      'areas': ['canapé', 'fauteuil', 'table basse', 'étagère', 'sol', 'TV']
    },
    {
      'name': 'Cuisine',
      'icon': Icons.kitchen,
      'emoji': '🍳',
      'areas': [
        'comptoir',
        'table',
        'réfrigérateur',
        'tiroir',
        'évier',
        'placard'
      ]
    },
    {
      'name': 'Chambre',
      'icon': Icons.bed,
      'emoji': '🛏️',
      'areas': [
        'lit',
        'table de nuit',
        'étagère',
        'armoire',
        'bureau',
        'tiroir'
      ]
    },
    {
      'name': 'Salle de bain',
      'icon': Icons.bathtub,
      'emoji': '🚿',
      'areas': ['lavabo', 'étagère', 'baignoire', 'tiroir', 'coffre', 'WC']
    },
    {
      'name': 'Entrée',
      'icon': Icons.door_front_door,
      'emoji': '🚪',
      'areas': ['étagère', 'patère', 'cintre', 'table', 'sol', 'tiroir']
    },
    {
      'name': 'Bureau',
      'icon': Icons.computer,
      'emoji': '💻',
      'areas': [
        'bureau',
        'étagère',
        'tiroir',
        'imprimante',
        'fauteuil',
        'armoire'
      ]
    },
  ];

  List<String> _getHints() {
    final objectData = _objects.firstWhere(
      (obj) => obj['name'] == _selectedObject,
      orElse: () => {
        'places': ['étagère', 'table', 'tiroir']
      },
    );
    final roomData = _rooms.firstWhere(
      (room) => room['name'] == _selectedRoom,
      orElse: () => {
        'areas': ['table', 'étagère']
      },
    );

    final places = List<String>.from(
        objectData['places'] ?? ['étagère', 'table', 'tiroir']);
    final areas = List<String>.from(roomData['areas'] ?? ['table', 'étagère']);

    final random = Random();
    final shuffledPlaces = List<String>.from(places)..shuffle(random);
    final shuffledAreas = List<String>.from(areas)..shuffle(random);

    final hintPlaces = shuffledPlaces.take(3).toList();
    final hintAreas = shuffledAreas.take(2).toList();

    if (hintPlaces.length < 3 || hintAreas.length < 2) {
      return [
        'Cherchez dans le $_selectedRoom',
        'Vérifiez les endroits accessibles',
        'Cherchez sur les surfaces',
        'Regardez près des murs',
        'Vérifiez les tiroirs et placards',
      ];
    }

    return [
      'L\'objet se trouve probablement sur un(e) ${hintPlaces[0]} dans le $_selectedRoom',
      'Essayez de chercher du côté ${hintAreas[0]} ou ${hintAreas[1]}',
      'L\'objet pourrait être caché près d\'un(e) ${hintPlaces[1]} dans le $_selectedRoom',
      'Pensez à vérifier les ${hintPlaces[2]} - c\'est un endroit courant pour cet objet',
      'L\'objet est probablement accessible sans monter sur une chaise',
    ];
  }

  List<String> _getAiHint() {
    final hints = _getHints();
    if (_hintsUsed > 0 && _hintsUsed <= hints.length) {
      return [hints[_hintsUsed - 1]];
    }
    return ['Continuez à chercher méthodiquement dans la pièce'];
  }

  @override
  void dispose() {
    _preparationTimer?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _startPreparation() {
    if (_selectedObject.isEmpty || _selectedRoom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un objet et une pièce')),
      );
      return;
    }

    setState(() {
      _currentStep = 1;
      _preparationSeconds = 0;
    });

    _preparationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _preparationSeconds++;
      });
    });
  }

  void _startSearch() {
    _preparationTimer?.cancel();

    setState(() {
      _currentStep = 2;
      _searchSeconds = 0;
      _hintsUsed = 0;
    });

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _searchSeconds++;
      });
    });
  }

  void _showHint() {
    final hints = _getHints();
    if (_hintsUsed < hints.length) {
      setState(() {
        _hintsUsed++;
      });
    }
  }

  void _confirmFound() {
    setState(() {
      _objectFound = true;
      _currentStep = 3;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _photoPath = image.path;
        });
        _finishGame();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _finishGame() {
    _searchTimer?.cancel();

    setState(() {
      _currentStep = 4;
    });
  }

  void _restart() {
    setState(() {
      _currentStep = 0;
      _selectedObject = '';
      _selectedRoom = '';
      _preparationSeconds = 0;
      _searchSeconds = 0;
      _hintsUsed = 0;
      _photoPath = '';
      _objectFound = false;
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildSelectionScreen();
      case 1:
        return _buildPreparationScreen();
      case 2:
        return _buildSearchScreen();
      case 3:
        return _buildPhotoScreen();
      case 4:
        return _buildResultScreen();
      default:
        return _buildSelectionScreen();
    }
  }

  Widget _buildSelectionScreen() {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.hiddenObjectGame,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(7, 82, 96, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color.fromRGBO(7, 82, 96, 1), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.hiddenObjectDesc,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color.fromRGBO(7, 82, 96, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.selectObject,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _objects.length,
              itemBuilder: (context, index) {
                final obj = _objects[index];
                final isSelected = _selectedObject == obj['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedObject = isSelected ? '' : obj['name'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromRGBO(7, 82, 96, 1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromRGBO(7, 82, 96, 1)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          obj['emoji'],
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          obj['name'],
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              translation(context).selectRoom,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final room = _rooms[index];
                final isSelected = _selectedRoom == room['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRoom = isSelected ? '' : room['name'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromRGBO(7, 82, 96, 1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromRGBO(7, 82, 96, 1)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room['emoji'],
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room['name'],
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _startPreparation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  translation(context).startGame,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparationScreen() {
    final t = translation(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(7, 82, 96, 1),
              Color.fromRGBO(14, 149, 173, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.timer,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  _formatTime(_preparationSeconds),
                  style: GoogleFonts.poppins(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.preparationTime,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
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
                        '${t.objectLabel}: $_selectedObject',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${t.roomLabel}: $_selectedRoom',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t.goHide,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  t.readyBtn,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromRGBO(7, 82, 96, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t.readyBtn,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchScreen() {
    final t = translation(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(14, 149, 173, 1),
              Color.fromRGBO(7, 82, 96, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        _searchTimer?.cancel();
                        _restart();
                      },
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatTime(_searchSeconds),
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '${t.lookFor} $_selectedObject',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.inRoom} $_selectedRoom',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                if (_hintsUsed > 0) ...[
                  Builder(builder: (context) {
                    final hints = _getHints();
                    final tr = translation(context);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.yellow),
                              const SizedBox(width: 8),
                              Text(
                                '${tr.hintLabel} $_hintsUsed/${hints.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hints[_hintsUsed - 1],
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                const Spacer(),
                Builder(builder: (context) {
                  final hints = _getHints();
                  final tr = translation(context);
                  if (_hintsUsed < hints.length) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _showHint,
                            icon: const Icon(Icons.lightbulb_outline),
                            label: Text(tr.getHint),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: _confirmFound,
                    icon: const Icon(Icons.check_circle, size: 28),
                    label: Text(
                      t.foundBtn,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoScreen() {
    final t = translation(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.takePhoto,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _currentStep = 2;
            });
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 100,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
            const SizedBox(height: 32),
            Text(
              t.congrats,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromRGBO(7, 82, 96, 1),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              t.takePhotoToConfirm,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: Text(
                  t.photoConfirm,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _finishGame,
              child: Text(
                t.skipPhoto,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final t = translation(context);
    int totalSeconds = _preparationSeconds + _searchSeconds;

    String performance;
    String performanceEmoji;

    if (totalSeconds < 60) {
      performance = t.excellentPerf;
      performanceEmoji = '🌟';
    } else if (totalSeconds < 180) {
      performance = t.wellDonePerf;
      performanceEmoji = '👍';
    } else if (totalSeconds < 300) {
      performance = t.notBadPerf;
      performanceEmoji = '💪';
    } else {
      performance = t.toImprovePerf;
      performanceEmoji = '🎯';
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(7, 82, 96, 1),
              Color.fromRGBO(14, 149, 173, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text(
                  performanceEmoji,
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                Text(
                  performance,
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildResultRow(
                        icon: Icons.timer,
                        label: t.preparationLabel,
                        value: _formatTime(_preparationSeconds),
                      ),
                      const Divider(height: 24),
                      _buildResultRow(
                        icon: Icons.search,
                        label: t.searchLabel,
                        value: _formatTime(_searchSeconds),
                      ),
                      const Divider(height: 24),
                      _buildResultRow(
                        icon: Icons.access_time,
                        label: t.totalTime,
                        value: _formatTime(totalSeconds),
                        isBold: true,
                      ),
                      const Divider(height: 24),
                      _buildResultRow(
                        icon: Icons.lightbulb,
                        label: t.hintsUsed,
                        value: '$_hintsUsed / ${_getHints().length}',
                      ),
                      const Divider(height: 24),
                      _buildResultRow(
                        icon: Icons.inventory_2,
                        label: t.objectLabel,
                        value: _selectedObject,
                      ),
                      const Divider(height: 24),
                      _buildResultRow(
                        icon: Icons.room,
                        label: t.roomLabel,
                        value: _selectedRoom,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '${t.gameComplete}\n${t.goodForMemory}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromRGBO(7, 82, 96, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      t.playAgain,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    t.backToGames,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromRGBO(7, 82, 96, 1), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color.fromRGBO(7, 82, 96, 1) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
