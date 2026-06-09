import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import '../../services/chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

class _ChatTheme {
  // Light base surfaces (matches AppColors.surface/background style)
  static const bgDeep = Color(0xFFF7F8FA);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgCard = Color(0xFFF1F5F9);
  static const bgGlass = Color(0x0A000000);

  // Accent system (aligned with ThemeData accent/primary)
  static const sand = Color(0xFF3B82F6); // primary blue
  static const sandLight = Color(0xFF93C5FD); // soft blue tint
  static const ember = Color(0xFF6366F1); // indigo accent
  static const emberGlow = Color(0x1A6366F1);

  static const teal = Color(0xFF10B981); // success green
  static const tealDim = Color(0x1A10B981);

  // Text system (light UI)
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  // Bubbles
  static const userBubble = Color(0xFF3B82F6);
  static const aiBubble = Color(0xFFFFFFFF);

  // Borders (Material 3 soft borders)
  static const borderSubtle = Color(0xFFE2E8F0);

  // Gradients (soft + modern, not aggressive)
  static const gradientSand = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientUser = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientHero = LinearGradient(
    colors: [Color(0xFFF7F8FA), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _inputFocus = false;
  bool _showScrollBtn = false;

  // Animations
  late AnimationController _headerGlowCtrl;
  late AnimationController _sendPulseCtrl;
  late Animation<double> _headerGlow;
  late Animation<double> _sendPulse;

  // Suggestions with icons
  final List<_Suggestion> _suggestions = const [
    _Suggestion("Mes événements", Iconsax.calendar_1, _ChatTheme.sand),
    _Suggestion("Mes inscriptions", Iconsax.ticket, _ChatTheme.teal),
    _Suggestion("Événements populaires", Iconsax.trend_up, _ChatTheme.ember),
    _Suggestion("Rechercher", Iconsax.search_normal, _ChatTheme.sandLight),
    _Suggestion("Nouveautés", Iconsax.star_1, _ChatTheme.teal),
    _Suggestion("Mes favoris", Iconsax.heart, _ChatTheme.ember),
  ];

  @override
  void initState() {
    super.initState();

    // Header ambient glow
    _headerGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _headerGlow = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _headerGlowCtrl, curve: Curves.easeInOut),
    );

    // Send button pulse
    _sendPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sendPulse = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _sendPulseCtrl, curve: Curves.easeInOut));

    // Input focus listener
    _focusNode.addListener(() {
      setState(() => _inputFocus = _focusNode.hasFocus);
    });

    // Scroll listener for FAB
    _scrollController.addListener(() {
      final atBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 80;
      if (!atBottom != _showScrollBtn) {
        setState(() => _showScrollBtn = !atBottom);
      }
    });

    // Welcome message — delayed for entrance animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: "welcome",
            text:
                "Bonjour 👋  Je suis **Tunixplore**, votre assistant personnel.\n\nJe peux vous aider à trouver des événements, gérer vos inscriptions et bien plus encore. Que puis-je faire pour vous ?",
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _headerGlowCtrl.dispose();
    _sendPulseCtrl.dispose();
    super.dispose();
  }

  // ─── SEND ───────────────────────────────────────────────────────────────────
  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.clear();

    setState(() {
      _messages.add(_userMessage(text));
      _isTyping = true;
    });
    _scrollToBottom();

    final response = await ChatService.reply(text);
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          text: response.text,
          isUser: false,
          time: DateTime.now(),
          type: response.type,
          data: {"items": response.items},
        ),
      );
      _isTyping = false;
    });
    _scrollToBottom();
  }

  ChatMessage _userMessage(String text) => ChatMessage(
    id: DateTime.now().toString(),
    text: text,
    isUser: true,
    time: DateTime.now(),
  );

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _ChatTheme.bgDeep,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Ambient background texture
            const _AmbientBackground(),

            Column(
              children: [
                // Space behind the translucent appbar
                const SizedBox(height: kToolbarHeight + 56),

                // Suggestion chips
                _buildSuggestionBar(),

                // Message list
                Expanded(child: _buildMessageList()),

                // Input bar
                _InputBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  isFocused: _inputFocus,
                  sendPulse: _sendPulse,
                  onSend: _send,
                ),
              ],
            ),

            // Scroll-to-bottom FAB
            if (_showScrollBtn)
              Positioned(
                right: 16,
                bottom: 90,
                child: _ScrollToBottomBtn(onTap: _scrollToBottom),
              ),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 4),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedBuilder(
            animation: _headerGlow,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                color: _ChatTheme.bgSurface.withOpacity(0.85),
                border: Border(
                  bottom: BorderSide(
                    color: _ChatTheme.sand.withOpacity(
                      _headerGlow.value * 0.25,
                    ),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _ChatTheme.textSecondary,
                        ),
                        onPressed: () => context.pop(),
                      ),

                      // Avatar + status
                      _AvatarWithStatus(glowValue: _headerGlow.value),
                      const SizedBox(width: 12),

                      // Title block
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Assistant Tunixplore",
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _ChatTheme.textPrimary,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _ChatTheme.teal.withOpacity(
                                      0.6 + _headerGlow.value * 0.4,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _ChatTheme.teal.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isTyping
                                      ? "en train d'écrire..."
                                      : "En ligne",
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _ChatTheme.textSecondary,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      IconButton(
                        icon: const Icon(
                          Iconsax.search_normal,
                          size: 20,
                          color: _ChatTheme.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Iconsax.more,
                          size: 20,
                          color: _ChatTheme.textSecondary,
                        ),
                        onPressed: () => _showOptionsSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── SUGGESTIONS ────────────────────────────────────────────────────────────
  Widget _buildSuggestionBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _SuggestionChip(
          suggestion: _suggestions[i],
          index: i,
          onTap: () => _send(_suggestions[i].label),
        ),
      ),
    );
  }

  // ─── MESSAGE LIST ───────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return const _TypingBubble();
        }

        final msg = _messages[index];
        final isFirst = index == 0 || _messages[index - 1].isUser != msg.isUser;
        final isLast =
            index == _messages.length - 1 ||
            (index + 1 < _messages.length &&
                _messages[index + 1].isUser != msg.isUser);

        return _EntranceAnimation(
          index: index,
          child: _MessageBubble(message: msg, isFirst: isFirst, isLast: isLast),
        );
      },
    );
  }

  // ─── OPTIONS SHEET ──────────────────────────────────────────────────────────
  void _showOptionsSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionsSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Base light gradient (Material 3 style surface feel)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F8FA), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Soft blue glow (top-left, very subtle)
          Positioned(
            top: -100,
            left: -80,
            child: _GlowOrb(
              size: 300,
              color: _ChatTheme.sand.withOpacity(0.08),
            ),
          ),

          // Soft indigo accent glow (bottom-right)
          Positioned(
            bottom: -60,
            right: -100,
            child: _GlowOrb(
              size: 260,
              color: _ChatTheme.ember.withOpacity(0.06),
            ),
          ),

          // Very subtle dot grid (light mode version)
          Positioned.fill(child: _DotGrid()),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotGridPainter());
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF21262D).withOpacity(0.5)
      ..strokeCap = StrokeCap.round;
    const gap = 28.0;
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR WITH ANIMATED STATUS RING
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarWithStatus extends StatelessWidget {
  final double glowValue;
  const _AvatarWithStatus({required this.glowValue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(glowValue * 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(6), // keeps logo nicely centered
              child: Image.asset(
                'lib/assets/logo_tunixplore_lq.jpg', // 👈 replace with your logo path
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _ChatTheme.teal,
              shape: BoxShape.circle,
              border: Border.all(color: _ChatTheme.bgDeep, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUGGESTION CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _Suggestion {
  final String label;
  final IconData icon;
  final Color color;
  const _Suggestion(this.label, this.icon, this.color);
}

class _SuggestionChip extends StatefulWidget {
  final _Suggestion suggestion;
  final int index;
  final VoidCallback onTap;
  const _SuggestionChip({
    required this.suggestion,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.suggestion.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.suggestion.color.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.suggestion.icon,
                size: 13,
                color: widget.suggestion.color,
              ),
              const SizedBox(width: 6),
              Text(
                widget.suggestion.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: widget.suggestion.color,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRANCE ANIMATION WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _EntranceAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  const _EntranceAnimation({required this.child, required this.index});

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLE ROUTER
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirst;
  final bool isLast;

  const _MessageBubble({
    required this.message,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _UserBubble(message: message, isLast: isLast);
    }

    switch (message.type) {
      case "event":
        return _EventCard(
          text: message.text,
          items: message.data?["items"] ?? [],
          isFirst: isFirst,
        );
      case "list":
        return _ListCard(
          text: message.text,
          items: message.data?["items"] ?? [],
          isFirst: isFirst,
        );
      default:
        return _AIBubble(message: message, isFirst: isFirst, isLast: isLast);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;
  const _UserBubble({required this.message, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 56, bottom: isLast ? 14 : 3, top: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: _ChatTheme.gradientUser,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6FA8).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: _ChatTheme.textPrimary,
                fontSize: 14.5,
                height: 1.45,
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (isLast) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.time),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _ChatTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 13,
                  color: _ChatTheme.teal,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// AI TEXT BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _AIBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirst;
  final bool isLast;
  const _AIBubble({
    required this.message,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 56, bottom: isLast ? 14 : 3, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isLast) ...[
            _MiniAvatar(),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 38),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _ChatTheme.bgCard,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: _ChatTheme.borderSubtle,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _ParsedText(text: message.text),
                ),
                if (isLast) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.time),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: _ChatTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ─── Simple bold-markdown parser ─────────────────────────────────────────────
class _ParsedText extends StatelessWidget {
  final String text;
  const _ParsedText({required this.text});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _ChatTheme.sandLight,
          ),
        ),
      );
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _ChatTheme.textPrimary,
          fontSize: 14.5,
          height: 1.55,
          letterSpacing: 0.1,
        ),
        children: spans,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI AVATAR FOR AI MESSAGES
// ─────────────────────────────────────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'lib/assets/logo_tunixplore_lq.jpg', // 👈 replace with your real asset path
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPING BUBBLE — animated three-dot bouncer
// ─────────────────────────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _bounces;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true, period: const Duration(milliseconds: 900)),
    );

    _bounces = List.generate(3, (i) {
      return Tween<double>(
        begin: 0,
        end: -6,
      ).animate(CurvedAnimation(parent: _ctrls[i], curve: Curves.easeInOut));
    });

    // Stagger the dots
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) _ctrls[1].repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _ctrls[2].repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 80, bottom: 12, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MiniAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _ChatTheme.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _ChatTheme.borderSubtle, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _bounces[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _bounces[i].value),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0
                            ? _ChatTheme.sand
                            : i == 1
                            ? _ChatTheme.ember
                            : _ChatTheme.teal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT CARD — rich cards with shimmer image loading
// ─────────────────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final String text;
  final List items;
  final bool isFirst;
  const _EventCard({
    required this.text,
    required this.items,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 14, top: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _ChatTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _ChatTheme.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: _ParsedText(text: text),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Horizontally scrollable event cards
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 38),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _EventTile(item: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatefulWidget {
  final dynamic item;
  const _EventTile({required this.item});

  @override
  State<_EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<_EventTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevation = Tween<double>(
      begin: 0,
      end: -4,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.item;
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) {
        _hoverCtrl.reverse();
        HapticFeedback.selectionClick();
        context.push("/event/${e["id"]}");
      },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _elevation,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _elevation.value),
          child: child,
        ),
        child: Container(
          width: 195,
          decoration: BoxDecoration(
            color: _ChatTheme.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _ChatTheme.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with gradient overlay
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      e["image"] ?? "",
                      height: 115,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _ShimmerBox(width: 195, height: 115);
                      },
                    ),
                    // Bottom gradient fade
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xCC1C2333), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Price badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_ChatTheme.sand, _ChatTheme.ember],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${e["price"] ?? "—"} DT",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _ChatTheme.bgDeep,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e["title"] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: _ChatTheme.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.calendar_1,
                          size: 11,
                          color: _ChatTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e["date"] ?? "",
                            style: const TextStyle(
                              fontSize: 11,
                              color: _ChatTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _GradientButton(
                      label: "Voir l'événement",
                      onTap: () => context.push("/event/${e["id"]}"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 115,
      color: _ChatTheme.bgSurface,
      child: const Center(
        child: Icon(Iconsax.image, size: 28, color: _ChatTheme.textMuted),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final String text;
  final List items;
  final bool isFirst;
  const _ListCard({
    required this.text,
    required this.items,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 14, top: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _ChatTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _ChatTheme.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: _ParsedText(text: text),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            margin: const EdgeInsets.only(left: 38),
            decoration: BoxDecoration(
              color: _ChatTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ChatTheme.borderSubtle, width: 1),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == items.length - 1;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push("/event/${item["eventId"]}");
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                color: _ChatTheme.borderSubtle,
                                width: 1,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item["image"] != null
                              ? Image.network(
                                  item["image"],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _SmallPlaceholder(),
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return _ShimmerBox(width: 48, height: 48);
                                  },
                                )
                              : _SmallPlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["title"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: _ChatTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item["subtitle"] ?? "",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _ChatTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _ChatTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: _ChatTheme.bgSurface,
      child: const Center(
        child: Icon(Iconsax.image, size: 18, color: _ChatTheme.textMuted),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER BOX
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + _shimmer.value * 2, 0),
            end: Alignment(1 + _shimmer.value * 2, 0),
            colors: const [
              Color(0xFF1C2333),
              Color(0xFF2A3346),
              Color(0xFF1C2333),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          gradient: _ChatTheme.gradientSand,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _ChatTheme.bgDeep,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCROLL-TO-BOTTOM FAB
// ─────────────────────────────────────────────────────────────────────────────

class _ScrollToBottomBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollToBottomBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _ChatTheme.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: _ChatTheme.borderSubtle),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12),
          ],
        ),
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _ChatTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final Animation<double> sendPulse;
  final Function(String) onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.sendPulse,
    required this.onSend,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: _ChatTheme.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isFocused
                ? _ChatTheme.sand.withOpacity(0.45)
                : _ChatTheme.borderSubtle,
            width: widget.isFocused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isFocused
                  ? _ChatTheme.sand.withOpacity(0.08)
                  : Colors.transparent,
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment icon
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: const Icon(
                  Iconsax.attach_circle,
                  size: 22,
                  color: _ChatTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Text field
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: _ChatTheme.textPrimary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  hintText: "Écrivez un message…",
                  hintStyle: const TextStyle(
                    color: _ChatTheme.textMuted,
                    fontSize: 14.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                ),
                onSubmitted: (t) {
                  if (t.trim().isNotEmpty) widget.onSend(t);
                },
              ),
            ),
            const SizedBox(width: 6),

            // Send / mic button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _hasText
                  ? _SendButton(
                      key: const ValueKey('send'),
                      pulse: widget.sendPulse,
                      onTap: () => widget.onSend(widget.controller.text),
                    )
                  : _MicButton(key: const ValueKey('mic')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final Animation<double> pulse;
  final VoidCallback onTap;
  const _SendButton({super.key, required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pulse,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: _ChatTheme.gradientSand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _ChatTheme.sand.withOpacity(0.35),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Iconsax.send_1, size: 18, color: _ChatTheme.bgDeep),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _ChatTheme.tealDim,
          shape: BoxShape.circle,
          border: Border.all(color: _ChatTheme.teal.withOpacity(0.3), width: 1),
        ),
        child: const Icon(Iconsax.microphone, size: 18, color: _ChatTheme.teal),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPTIONS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _OptionsSheet extends StatelessWidget {
  final _options = const [
    (Iconsax.brush_1, "Effacer la conversation", _ChatTheme.ember),
    (Iconsax.export, "Exporter le chat", _ChatTheme.sand),
    (Iconsax.info_circle, "À propos d'Xplore", _ChatTheme.teal),
    (Iconsax.setting_2, "Paramètres", _ChatTheme.textSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ChatTheme.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ChatTheme.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _ChatTheme.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ..._options.map(
            (opt) => _OptionTile(
              icon: opt.$1,
              label: opt.$2,
              color: opt.$3,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: _ChatTheme.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _ChatTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
