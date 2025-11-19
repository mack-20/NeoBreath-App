import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/database_service.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize wave animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Continuous loop

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_animationController);

    // IMPORTANT FUNCTIONALITY #1: Check for existing profiles
    // This determines where the user should go after splash
    _initializeApp();
  }

  // IMPORTANT FUNCTIONALITY #2: App Initialization
  // Checks database and routes user appropriately
  Future<void> _initializeApp() async {
    // Wait minimum time for splash screen (better UX)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final profileCount = await DatabaseService.instance.getProfileCount();
      
      Navigator.pushReplacementNamed(context, '/select_profile');
      
    } catch (e) {
      print('Error checking profiles: $e');
      // On error, default to select profile screen
      Navigator.pushReplacementNamed(context, '/select_profile');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8), // Match app theme
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                
                // Animated wave with ball
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WavePainter(
                          animationValue: _waveAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // App title
                Text(
                  'Monitoring Tiny Breaths with Care',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF48576B),
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Footer text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Apnea Monitor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the wave with ball
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Color(0xFFB5DEFF) // Light blue wave
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25.0
      ..strokeCap = StrokeCap.round;

    final ballPaint = Paint()
      ..color = Color(0xFFFF6B6B) // Coral pink ball
      ..style = PaintingStyle.fill;

    // Wave parameters
    final path = Path();
    final waveWidth = size.width;
    final waveHeight = size.height / 2;
    final amplitude = 40.0; // Height of wave peaks
    final frequency = 2.0; // Number of waves

    // Calculate ball position
    double ballX = 0;
    double ballY = 0;

    // Draw the wave
    path.moveTo(0, waveHeight);

    for (double i = 0; i <= waveWidth; i++) {
      final x = i;
      final y = waveHeight +
          amplitude *
              math.sin((i / waveWidth) * frequency * 2 * math.pi +
                  animationValue);

      path.lineTo(x, y);

      // Calculate ball position at the peak of the wave
      if (i / waveWidth >= 0.35 && i / waveWidth <= 0.36) {
        ballX = x;
        ballY = y;
      }
    }

    // Draw wave
    canvas.drawPath(path, wavePaint);

    // Draw ball on wave
    canvas.drawCircle(
      Offset(ballX, ballY),
      12.0, // Ball radius
      ballPaint,
    );

    // Add shadow to ball for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(
      Offset(ballX, ballY + 2),
      12.0,
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}