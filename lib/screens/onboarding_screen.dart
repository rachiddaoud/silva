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

            // Selected Category Description
            AnimatedOpacity(
              opacity: _selectedCategory != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
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

            const SizedBox(height: 40),

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
    
    // Calculate angle in radians, adding pi/2 to rotate 0 to top
    // atan2 returns angle from -pi to pi
    // We want 0 at top (12 o'clock)
    
    // Standard atan2: 0 is Right (3 o'clock), positive clockwise
    // Let's adjust so 0 is Top (-pi/2 in standard)
    
    double angle = atan2(dy, dx);
    // angle is now -pi to pi relative to 3 o'clock
    
    // Normalize to 0-2pi
    if (angle < 0) {
      angle += 2 * pi;
    }
    
    // Now angle is 0 to 2pi starting at 3 o'clock going clockwise
    
    // Segments:
    // We want 3 segments.
    // Let's say:
    // 1. Top-Right to Top-Left (Future Maman)
    // 2. Top-Left to Bottom (Nouvelle Maman)
    // 3. Bottom to Top-Right (Sérénité)
    
    // Or simpler:
    // 0 to 120 degrees (0 to 2pi/3)
    // 120 to 240 degrees (2pi/3 to 4pi/3)
    // 240 to 360 degrees (4pi/3 to 2pi)
    
    // But we need to rotate the whole thing so the split is nice.
    // Let's put "Future Maman" at the top.
    // So -30 to 90 degrees? Or -60 to 60?
    // 3 segments = 120 degrees each.
    // Segment 1: -90 (top) - 60 to -90 + 60 => -150 to -30 ?
    
    // Let's stick to the visual description: "Un grand cercle divisé en trois segments égaux"
    // Usually one segment is top, one bottom-right, one bottom-left.
    // Or one top-right, one top-left, one bottom.
    
    // Let's do:
    // Segment 1 (Future Maman): Top (-150° to -30°) -> 210° to 330° in standard?
    // No, let's just use simple ranges on the 0-2pi scale (starting at 3 o'clock).
    
    // Segment 1: 330° (-30°) to 90° (Top-Right + Bottom-Right?) No.
    
    // Let's define the segments relative to 12 o'clock (Top).
    // Top is -pi/2.
    // Segment 1: -pi/2 - pi/3 to -pi/2 + pi/3 (Top centered) -> Future Maman
    // Segment 2: -pi/2 + pi/3 to -pi/2 + pi (Right/Bottom) -> Nouvelle Maman
    // Segment 3: -pi/2 + pi to -pi/2 - pi/3 (Left/Bottom) -> Sérénité
    
    // Let's convert touch angle to be relative to Top (0)
    double angleFromTop = angle + pi / 2;
    if (angleFromTop < 0) angleFromTop += 2 * pi;
    if (angleFromTop > 2 * pi) angleFromTop -= 2 * pi;
    
    // Now 0 is Top, increasing clockwise.
    // Segment 1 (Future Maman): 300° to 60° (or 5pi/3 to pi/3) -> Let's center it at Top.
    // Wait, 3 segments. 360 / 3 = 120.
    // Top Center: 300° to 60°. (Crossing 0).
    // Right Bottom: 60° to 180°.
    // Left Bottom: 180° to 300°.
    
    AppCategory selected;
    if (angleFromTop >= 0 && angleFromTop < 2 * pi / 3) {
      // 0 to 120 -> Right side
      selected = AppCategory.nouvelleMaman; // Let's put Nouvelle Maman here
    } else if (angleFromTop >= 2 * pi / 3 && angleFromTop < 4 * pi / 3) {
      // 120 to 240 -> Bottom
      selected = AppCategory.sereniteQuotidienne;
    } else {
      // 240 to 360 -> Top Left?
      selected = AppCategory.futureMaman;
    }
    
    // Let's rotate it so Future Maman is Top.
    // Top segment: 300° to 60°.
    // Right segment: 60° to 180°.
    // Left segment: 180° to 300°.
    
    double deg = angleFromTop * 180 / pi;
    
    if (deg >= 300 || deg < 60) {
      selected = AppCategory.futureMaman;
    } else if (deg >= 60 && deg < 180) {
      selected = AppCategory.nouvelleMaman;
    } else {
      selected = AppCategory.sereniteQuotidienne;
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
