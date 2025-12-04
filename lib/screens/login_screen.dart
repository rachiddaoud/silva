import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    // Track login attempt
    await AnalyticsService.instance.logEvent(
      name: AnalyticsEvents.loginAttempt,
      parameters: {AnalyticsParams.provider: 'google'},
    );

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && userCredential.user != null) {
        final user = userCredential.user!;
        if (user.displayName != null) {
          await PreferencesService.setUserName(user.displayName!);
        }
        await PreferencesService.setOnboardingComplete(true);
        
        // Track successful login
        await AnalyticsService.instance.logEvent(
          name: AnalyticsEvents.loginSuccess,
          parameters: {AnalyticsParams.provider: 'google'},
        );
        
        // Check if category is selected
        // We check local prefs first, then Firestore if needed (but for now let's rely on local or assume new login needs check)
        // Actually, if we just logged in, we might not have the category locally.
        // Let's check Firestore via DatabaseService
        final DatabaseService db = DatabaseService();
        final category = await db.getUserCategory(user.uid);
        
        if (category != null) {
          await PreferencesService.setAppCategory(category);
        }

        if (mounted) {
          // If category is found, go to Home via onLoginSuccess callback (which usually reloads main)
          // If not found, we should probably navigate to Onboarding manually or let main handle it?
          // The current onLoginSuccess callback in main just sets _isOnboardingComplete = true.
          // We need to change main.dart to handle the routing.
          // But here, we can just call the callback and let main decide?
          // Or we can modify the callback to accept a "needsOnboarding" flag?
          
          // Let's modify the callback signature or just handle it in main.
          // For now, let's call the callback. Main will rebuild.
          // We need to update Main to check for category.
          widget.onLoginSuccess();
        }
      }
    } catch (e) {
      // Track login failure
      await AnalyticsService.instance.logEvent(
        name: AnalyticsEvents.loginFailure,
        parameters: {
          AnalyticsParams.provider: 'google',
          AnalyticsParams.errorCode: e.toString(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
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

  void _handleAppleSignIn() {
    // Track login attempt for Apple (even though not implemented yet)
    AnalyticsService.instance.logEvent(
      name: AnalyticsEvents.loginAttempt,
      parameters: {AnalyticsParams.provider: 'apple'},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.appleSignInComingSoon),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Welcome Text
                Text(
                  AppLocalizations.of(context)!.welcomeTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.welcomeSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF636E72),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Main Image
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Image.asset(
                    'assets/doodles/login.jpg',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_rounded,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Buttons
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Google Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.login),
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.continueWithGoogle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F2F6),
                        foregroundColor: const Color(0xFF2D3436),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Apple Button (Placeholder)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleAppleSignIn,
                      icon: const Icon(Icons.apple, size: 28, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.continueWithApple,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.termsOfService,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB2BEC3),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

