import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'redeem_page.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> with TickerProviderStateMixin {
  // --- STATE VARIABLES ---
  int _currentPoints = 150;
  int _spinTickets = 2;
  bool _isKicking = false;
  String _kickResult = ''; // 'goal', 'post', 'saved', 'miss'

  // Ball position
  double _ballX = 0;
  double _ballY = 0;
  double _ballScale = 1.0;

  // Animation Controllers
  late AnimationController _ballController;
  late AnimationController _pulseController;
  late AnimationController _keeperController;

  // Animations
  late Animation<double> _ballAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _keeperAnimation;

  // Keeper position (-1 = left, 0 = center, 1 = right)
  double _keeperX = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startIdleAnimations();
  }

  void _initializeAnimations() {
    // Ball kick animation
    _ballController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _ballAnimation = CurvedAnimation(
      parent: _ballController,
      curve: Curves.easeOut,
    );

    // Pulse animation for ball
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Keeper dive animation
    _keeperController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _keeperAnimation = CurvedAnimation(
      parent: _keeperController,
      curve: Curves.easeOut,
    );
  }

  void _startIdleAnimations() {
    if (_spinTickets > 0 && !_isKicking) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopIdleAnimations() {
    _pulseController.stop();
    _pulseController.value = 0.5;
  }

  @override
  void dispose() {
    _ballController.dispose();
    _pulseController.dispose();
    _keeperController.dispose();
    super.dispose();
  }

  // --- PENALTY KICK LOGIC ---
  void _playGacha() async {
    if (_spinTickets <= 0) {
      _showNoTicketsDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    _stopIdleAnimations();

    setState(() {
      _spinTickets -= 1;
      _isKicking = true;
      _kickResult = '';
    });

    // Generate result first
    final reward = _generateReward();
    final result = reward['result'] as String;

    // Determine ball target based on result
    double targetX = 0;
    double targetY = -1; // Always go up
    double targetScale = 0.4;

    // Keeper dive direction (random, but affects save chance)
    final keeperDive = [-1.0, 0.0, 1.0][Random().nextInt(3)];

    switch (result) {
      case 'goal':
        // Ball goes to corner where keeper doesn't dive
        targetX = keeperDive == 1 ? -0.7 : (keeperDive == -1 ? 0.7 : [-0.5, 0.5][Random().nextInt(2)]);
        break;
      case 'post':
        // Ball hits the post
        targetX = [-1.0, 1.0][Random().nextInt(2)];
        break;
      case 'saved':
        // Ball goes to where keeper dives
        targetX = keeperDive;
        break;
      case 'miss':
        // Ball goes way outside
        targetX = [-1.5, 1.5][Random().nextInt(2)];
        targetY = -1.2;
        break;
    }

    setState(() {
      _keeperX = keeperDive;
    });

    // Animate ball
    _ballController.addListener(() {
      setState(() {
        _ballX = targetX * _ballAnimation.value;
        _ballY = targetY * _ballAnimation.value;
        _ballScale = 1.0 - (0.6 * _ballAnimation.value);
      });
    });

    // Start animations
    _ballController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _keeperController.forward();

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _kickResult = result;
    });

    // Show result
    await Future.delayed(const Duration(milliseconds: 500));

    // Reset
    _ballController.reset();
    _keeperController.reset();

    setState(() {
      _currentPoints += reward['points'] as int;
      _ballX = 0;
      _ballY = 0;
      _ballScale = 1.0;
      _keeperX = 0;
      _isKicking = false;
      _kickResult = '';
    });

    if (_spinTickets > 0) {
      _startIdleAnimations();
    }

    if (mounted) {
      _showRewardDialog(reward);
    }
  }

  Map<String, dynamic> _generateReward() {
    final random = Random();
    int chance = random.nextInt(100);

    if (chance < 5) {
      // GOAL! - Legendary
      return {
        'points': 1000,
        'title': 'GOOOL! 🎉',
        'subtitle': 'Tendangan sempurna!',
        'color': const Color(0xFFFFD700),
        'icon': Icons.sports_soccer,
        'result': 'goal',
      };
    } else if (chance < 15) {
      // Hit the post - Epic
      return {
        'points': 500,
        'title': 'KENA TIANG!',
        'subtitle': 'Hampir masuk!',
        'color': const Color(0xFF9C27B0),
        'icon': Icons.sports_soccer,
        'result': 'post',
      };
    } else if (chance < 40) {
      // Saved by keeper - Rare
      return {
        'points': 100,
        'title': 'DITEPIS!',
        'subtitle': 'Kiper berhasil menangkap',
        'color': const Color(0xFF2196F3),
        'icon': Icons.sports_soccer,
        'result': 'saved',
      };
    } else {
      // Miss - Common
      return {
        'points': 10,
        'title': 'MELESET!',
        'subtitle': 'Bola keluar gawang',
        'color': const Color(0xFF78909C),
        'icon': Icons.sports_soccer,
        'result': 'miss',
      };
    }
  }

  void _showNoTicketsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.confirmation_number_outlined,
                  size: 48,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tiket Habis!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Booking lapangan untuk mendapatkan tiket gacha gratis!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Mengerti",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardDialog(Map<String, dynamic> reward) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GachaRewardDialog(reward: reward),
    );
  }

  void _goToRedeemPage() async {
    final remainingPoints = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RedeemPage(currentPoints: _currentPoints),
      ),
    );
    if (remainingPoints != null) {
      setState(() {
        _currentPoints = remainingPoints;
      });
    }
  }

  void _simulateBooking() {
    setState(() {
      _spinTickets += 1;
    });

    if (_spinTickets == 1) {
      _startIdleAnimations();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Booking berhasil! +1 Tiket Gacha"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      const Color(0xFF1e3a5f).withOpacity(0.3),
                      const Color(0xFF0f172a),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            Column(
              children: [
                // Top Bar
                _buildTopBar(),

                // Main Area
                Expanded(
                  child: Center(
                    child: _buildPenaltyArea(),
                  ),
                ),

                // Bottom info
                _buildBottomInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 22),
          ),
          const Spacer(),
          // Points badge
          GestureDetector(
            onTap: _goToRedeemPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _formatPoints(_currentPoints),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildPenaltyArea() {
    return GestureDetector(
      onTap: (_isKicking || _spinTickets <= 0) ? null : _playGacha,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Ticket indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _spinTickets > 0
                    ? const Color(0xFF00D4AA).withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _spinTickets > 0
                      ? const Color(0xFF00D4AA).withOpacity(0.4)
                      : Colors.red.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.confirmation_number_rounded,
                    color: _spinTickets > 0 ? const Color(0xFF00D4AA) : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _spinTickets > 0 ? "$_spinTickets Tiket" : "Tiket Habis",
                    style: TextStyle(
                      color: _spinTickets > 0 ? const Color(0xFF00D4AA) : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Penalty Field
            AspectRatio(
              aspectRatio: 1.1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Field texture lines
                    ...List.generate(8, (i) => Positioned(
                      left: 0,
                      right: 0,
                      top: i * 40.0 + 20,
                      child: Container(
                        height: 2,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    )),

                    // Penalty box
                    Positioned(
                      bottom: 30,
                      child: Container(
                        width: 220,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                      ),
                    ),

                    // Goal frame
                    Positioned(
                      top: 30,
                      child: Container(
                        width: 200,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: CustomPaint(painter: NetPainter()),
                        ),
                      ),
                    ),

                    // Goalkeeper
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(_keeperX * 60, 0),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade400, Colors.orange.shade700],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                        ),
                      ),
                    ),

                    // Ball
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Positioned(
                          bottom: _isKicking ? null : 50,
                          top: _isKicking ? (100 + (_ballY * -80)) : null,
                          child: Transform.translate(
                            offset: Offset(_ballX * 80, 0),
                            child: Transform.scale(
                              scale: _isKicking ? _ballScale : _pulseAnimation.value,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                    if (_spinTickets > 0 && !_isKicking)
                                      BoxShadow(
                                        color: const Color(0xFF00D4AA).withOpacity(0.6),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                  ],
                                ),
                                child: const Icon(Icons.sports_soccer, color: Colors.black87, size: 34),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Result overlay
                    if (_kickResult.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getResultEmoji(),
                                  style: const TextStyle(fontSize: 60),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getResultText(),
                                  style: TextStyle(
                                    color: _getResultColor(),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: _getResultColor().withOpacity(0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tap instruction
            Text(
              _isKicking
                  ? "Menendang..."
                  : _spinTickets > 0
                      ? "TAP UNTUK TENDANG"
                      : "Booking lapangan untuk dapat tiket",
              style: TextStyle(
                color: _spinTickets > 0 ? Colors.white : Colors.white54,
                fontSize: _spinTickets > 0 ? 18 : 14,
                fontWeight: FontWeight.bold,
                letterSpacing: _spinTickets > 0 ? 2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getResultEmoji() {
    switch (_kickResult) {
      case 'goal': return '🎉';
      case 'post': return '😮';
      case 'saved': return '🧤';
      case 'miss': return '😅';
      default: return '';
    }
  }

  Color _getResultColor() {
    switch (_kickResult) {
      case 'goal':
        return const Color(0xFFFFD700);
      case 'post':
        return const Color(0xFF9C27B0);
      case 'saved':
        return const Color(0xFF2196F3);
      case 'miss':
        return const Color(0xFF78909C);
      default:
        return Colors.grey;
    }
  }

  String _getResultText() {
    switch (_kickResult) {
      case 'goal':
        return 'GOOOL!';
      case 'post':
        return 'KENA TIANG!';
      case 'saved':
        return 'DITEPIS!';
      case 'miss':
        return 'MELESET!';
      default:
        return '';
    }
  }

  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Info button
          GestureDetector(
            onTap: _showPrizesSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🏆", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    "Lihat Hadiah",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Dev button
          GestureDetector(
            onTap: _simulateBooking,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white.withOpacity(0.4), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Tiket",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
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

  void _showPrizesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1e293b),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Hadiah Tendangan",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Prizes list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _prizes.length,
                itemBuilder: (context, index) {
                  final prize = _prizes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (prize['color'] as Color).withOpacity(0.15),
                          (prize['colorEnd'] as Color).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (prize['color'] as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(prize['emoji'] as String, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prize['label'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                prize['desc'] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: prize['color'] as Color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "+${prize['points']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _prizes = [
    {
      'label': 'GOAL',
      'emoji': '🏆',
      'points': '1000',
      'color': const Color(0xFFFFD700),
      'colorEnd': const Color(0xFFFFA500),
      'desc': 'Bola masuk ke gawang! Tendangan sempurna yang tidak bisa ditangkap kiper.',
    },
    {
      'label': 'Kena Tiang',
      'emoji': '😮',
      'points': '500',
      'color': const Color(0xFF9C27B0),
      'colorEnd': const Color(0xFF7B1FA2),
      'desc': 'Bola menghantam tiang gawang! Hampir masuk, sangat dekat dengan goal.',
    },
    {
      'label': 'Ditepis',
      'emoji': '🧤',
      'points': '100',
      'color': const Color(0xFF2196F3),
      'colorEnd': const Color(0xFF1976D2),
      'desc': 'Kiper berhasil menebak arah dan menepis bola. Sayang sekali!',
    },
    {
      'label': 'Meleset',
      'emoji': '😅',
      'points': '10',
      'color': const Color(0xFF78909C),
      'colorEnd': const Color(0xFF546E7A),
      'desc': 'Bola meleset keluar gawang. Tetap semangat, coba lagi!',
    },
  ];

}

// ==========================================
// GACHA REWARD DIALOG - Premium Design
// ==========================================
class GachaRewardDialog extends StatefulWidget {
  final Map<String, dynamic> reward;

  const GachaRewardDialog({super.key, required this.reward});

  @override
  State<GachaRewardDialog> createState() => _GachaRewardDialogState();
}

class _GachaRewardDialogState extends State<GachaRewardDialog> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final List<ConfettiParticle> _confetti = [];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Generate confetti for legendary/epic rewards
    if (widget.reward['result'] == 'goal' || widget.reward['result'] == 'post') {
      _generateConfetti();
    }

    _scaleController.forward();
    _pulseController.repeat(reverse: true);
    _confettiController.repeat();
  }

  void _generateConfetti() {
    final random = Random();
    for (int i = 0; i < 30; i++) {
      _confetti.add(ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * -0.5,
        speed: 0.5 + random.nextDouble() * 1.5,
        size: 4 + random.nextDouble() * 6,
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFFF6B6B),
          const Color(0xFF4ECDC4),
          const Color(0xFF45B7D1),
          const Color(0xFFFF9F43),
          const Color(0xFF0047FF),
        ][random.nextInt(6)],
        rotation: random.nextDouble() * 3.14,
      ));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Color _getGradientStart() {
    switch (widget.reward['result']) {
      case 'goal':
        return const Color(0xFFFFD700);
      case 'post':
        return const Color(0xFF9C27B0);
      case 'saved':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF78909C);
    }
  }

  Color _getGradientEnd() {
    switch (widget.reward['result']) {
      case 'goal':
        return const Color(0xFFFFA500);
      case 'post':
        return const Color(0xFF7B1FA2);
      case 'saved':
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFF546E7A);
    }
  }

  String _getEmoji() {
    switch (widget.reward['result']) {
      case 'goal':
        return '🏆';
      case 'post':
        return '😮';
      case 'saved':
        return '🧤';
      default:
        return '😅';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLegendary = widget.reward['result'] == 'goal';
    final isEpic = widget.reward['result'] == 'post';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Confetti layer
            if (isLegendary || isEpic)
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: CustomPaint(
                      painter: ConfettiPainter(
                        particles: _confetti,
                        progress: _confettiController.value,
                      ),
                    ),
                  );
                },
              ),

            // Main card
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _getGradientStart().withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top gradient section with result
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_getGradientStart(), _getGradientEnd()],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Emoji with pulse
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getEmoji(),
                                      style: const TextStyle(fontSize: 42),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Title
                          Text(
                            widget.reward['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            widget.reward['subtitle'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom white section with points
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Points badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getGradientStart().withOpacity(0.1),
                                  _getGradientEnd().withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: _getGradientStart().withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars_rounded,
                                  color: _getGradientStart(),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "+${widget.reward['points']}",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: _getGradientStart(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "pts",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _getGradientEnd(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Claim Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getGradientStart(),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Klaim Hadiah",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Decorative stars for legendary
            if (isLegendary) ...[
              Positioned(
                top: -15,
                left: 20,
                child: _buildStar(20, const Color(0xFFFFD700)),
              ),
              Positioned(
                top: 10,
                right: 15,
                child: _buildStar(16, const Color(0xFFFFA500)),
              ),
              Positioned(
                bottom: 60,
                left: 10,
                child: _buildStar(14, const Color(0xFFFFD700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStar(double size, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: color,
          ),
        );
      },
    );
  }
}

// Confetti particle data
class ConfettiParticle {
  double x;
  double y;
  final double speed;
  final double size;
  final Color color;
  final double rotation;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
  });
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      final y = (particle.y + progress * particle.speed * 2) % 1.5 - 0.3;
      final x = particle.x + sin(progress * 3.14 * 2 + particle.rotation) * 0.05;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(progress * 3.14 * 2 + particle.rotation);

      // Draw rectangle confetti
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

// ==========================================
// NET PAINTER FOR GOAL
// ==========================================
class NetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Vertical lines
    const spacing = 12.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
