import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_category.dart';
import '../services/preferences_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  AppCategory? _selectedCategory;
  late AnimationController _controller;
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onCategorySelected(AppCategory category) async {
    setState(() {
      _selectedCategory = category;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _onContinue() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Save locally
      await PreferencesService.setAppCategory(_selectedCategory!);
      
      // Save to Firestore if user is logged in
      final user = _authService.currentUser;
      if (user != null) {
        await _databaseService.updateUserCategory(user.uid, _selectedCategory!);
        
        // Also update the victories for today based on the new category
        // This ensures the home screen shows the correct victories immediately
        // We only do this if today's victories haven't been "started" (modified) yet, 
        // or we just overwrite them since this is onboarding.
        // Given it's onboarding, let's overwrite to ensure they see their selected path.
        /* 
           Actually, we should be careful not to overwrite if they already have progress today.
           But since this is "Onboarding", it's likely their first time or they are resetting.
           Let's just clear the local "today_victories" so the next fetch gets the new defaults.
        */
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('today_victories'); 
      }

      // Fetch theme before navigation
      final currentTheme = await PreferencesService.getTheme();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              onThemeChanged: (theme) {}, // These callbacks might need to be passed from main or handled differently
              onLocaleChanged: (locale) {},
              currentTheme: currentTheme,
              currentLocale: null,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    "Où en êtes-vous dans votre cycle de sérénité ?",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3436),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Choisissez le parcours qui vous correspond le mieux.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF636E72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      final center = size / 2;
                      final radius = size / 2 * 0.9;
                      
                      // Helper to position widgets
                      Widget positionImage(double angleDeg, String assetPath, AppCategory category) {
                        // Angle in degrees from 3 o'clock
                        final angleRad = angleDeg * pi / 180;
                        // Distance from center (e.g. 60% of radius)
                        final dist = radius * 0.6;
                        
                        final dx = center + dist * cos(angleRad);
                        final dy = center + dist * sin(angleRad);
                        
                        final isSelected = _selectedCategory == category;
                        
                        return Positioned(
                          left: dx - 40, // 40 is half of image size (80)
                          top: dy - 40,
                          child: IgnorePointer(
                            child: AnimatedScale(
                              scale: isSelected ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Image.asset(
                                assetPath,
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTapUp: (details) {
                          _handleTap(details, constraints.maxWidth);
                        },
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxWidth),
                              painter: CategoryWheelPainter(
                                selectedCategory: _selectedCategory,
                                animationValue: _controller.value,
                              ),
                            ),
                            // Future Maman: Top (-90°)
                            positionImage(-90, AppCategory.futureMaman.assetPath, AppCategory.futureMaman),
                            // Nouvelle Maman: Bottom Right (30°)
                            positionImage(30, AppCategory.nouvelleMaman.assetPath, AppCategory.nouvelleMaman),
                            // Serenite: Bottom Left (150°)
                            positionImage(150, AppCategory.sereniteQuotidienne.assetPath, AppCategory.sereniteQuotidienne),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Selected Category Description - Fixed Height to prevent circle resizing
            SizedBox(
              height: 160,
              child: AnimatedOpacity(
                opacity: _selectedCategory != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column( // Center the content
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedCategory?.displayName ?? "",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedCategory?.description ?? "",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF636E72),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20), // Reduced spacing as we have fixed height

            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedCategory != null && !_isLoading ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3436),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Commencer",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(TapUpDetails details, double size) {
    final center = Offset(size / 2, size / 2);
    final touchPoint = details.localPosition;
    final dy = touchPoint.dy - center.dy;
    final dx = touchPoint.dx - center.dx;
    
    // Calculate angle in radians from positive X axis (Right)
    // Range: -pi to pi
    double angle = atan2(dy, dx);
    
    // Convert to degrees: -180 to 180
    double deg = angle * 180 / pi;
    
    // Normalize to 0-360 (counter-clockwise notation usually, but here atan2 is:
    // 0 = Right, 90 = Bottom, 180 = Left, -90 = Top)
    // Let's normalize to standard 0-360 clockwise from Right (since Y is down)
    if (deg < 0) {
      deg += 360;
    }
    
    // Now:
    // 0° = Right
    // 90° = Bottom
    // 180° = Left
    // 270° = Top
    
    AppCategory selected;
    
    // Define Segments matching the Painter
    
    // Nouvelle Maman: Right Segment
    // Painter: -30° (-pi/6) to 90° (pi/2)
    // -30° corresponds to 330°
    // Range: [330, 360] U [0, 90]
    if (deg >= 330 || deg < 90) {
      selected = AppCategory.nouvelleMaman;
    }
    // Serenite: Bottom-Left Segment
    // Painter: 90° (pi/2) to 210° (7pi/6)
    // Range: [90, 210]
    else if (deg >= 90 && deg < 210) {
      selected = AppCategory.sereniteQuotidienne;
    }
    // Future Maman: Top-Left Segment
    // Painter: -150° (-5pi/6) to -30° (-pi/6)
    // -150° corresponds to 210°
    // -30° corresponds to 330°
    // Range: [210, 330]
    else {
      selected = AppCategory.futureMaman;
    }
    
    _onCategorySelected(selected);
  }
}

class CategoryWheelPainter extends CustomPainter {
  final AppCategory? selectedCategory;
  final double animationValue;

  CategoryWheelPainter({
    required this.selectedCategory,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.9;
    
    // Draw 3 segments
    // Future Maman: Top (300° to 60°)
    // Nouvelle Maman: Right (60° to 180°)
    // Serenite: Left (180° to 300°)
    
    // Angles in radians (starting from 3 o'clock = 0)
    // Top is -90° (-pi/2)
    
    // Future Maman: -90 - 60 = -150° to -90 + 60 = -30°
    // Rad: -5pi/6 to -pi/6
    _drawSegment(
      canvas, center, radius, 
      -5 * pi / 6, 2 * pi / 3, 
      AppCategory.futureMaman,
    );
    
    // Nouvelle Maman: -30° to 90°
    // Rad: -pi/6 to pi/2
    _drawSegment(
      canvas, center, radius, 
      -pi / 6, 2 * pi / 3, 
      AppCategory.nouvelleMaman,
    );
    
    // Serenite: 90° to 210°
    // Rad: pi/2 to 7pi/6
    _drawSegment(
      canvas, center, radius, 
      pi / 2, 2 * pi / 3, 
      AppCategory.sereniteQuotidienne,
    );
    
    // Draw images/icons
    // We need to load images. Since CustomPainter is synchronous for painting, 
    // we usually pass ui.Image. But for simplicity in this iteration, 
    // let's draw text or simple shapes, or rely on a Stack in the widget for images.
    // Drawing images in CustomPainter requires pre-loading.
    // Better approach: Use the CustomPainter for background and a Stack for the icons.
  }

  void _drawSegment(
    Canvas canvas, 
    Offset center, 
    double radius, 
    double startAngle, 
    double sweepAngle, 
    AppCategory category
  ) {
    final isSelected = selectedCategory == category;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = category.color;

    if (isSelected) {
      // Highlight effect
      paint.color = Color.lerp(category.color, Colors.white, 0.3)!;
      // Maybe scale up slightly?
      // For now just color change
    }

    // Draw arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );
    
    // Draw border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 4;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CategoryWheelPainter oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
           oldDelegate.animationValue != animationValue;
  }
}
