import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyQuoteCard extends StatelessWidget {
  final String quote;

  const DailyQuoteCard({
    super.key,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          // Main Card Content
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Quote Text
                Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                // Decorative Divider
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                // Label
                Text(
                  "PENSÉE DU JOUR",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Decorative Quote Icon (Top Left)
          Positioned(
            top: 0,
            left: 24,
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
