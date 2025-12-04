import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';

class DailyQuoteCard extends StatefulWidget {
  final String quote;

  const DailyQuoteCard({
    super.key,
    required this.quote,
  });

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _shareImage() async {
    try {
      // Find the render boundary
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture image
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/quote.png').create();
      await file.writeAsBytes(pngBytes);

      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Une pensée pour toi ✨ #Silva',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Hidden Shareable Card (with branding) - Positioned off-screen
          Transform.translate(
            offset: const Offset(-10000, -10000),
            child: RepaintBoundary(
              key: _globalKey,
              child: _QuoteContent(
                quote: widget.quote,
                showBranding: true,
              ),
            ),
          ),

          // Visible Card (without branding)
          _QuoteContent(
            quote: widget.quote,
            showBranding: false,
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

          // Share Button (Top Right)
          Positioned(
            top: 0,
            right: 24,
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: GestureDetector(
                onTap: _shareImage,
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
                    Icons.share_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteContent extends StatelessWidget {
  final String quote;
  final bool showBranding;

  const _QuoteContent({
    required this.quote,
    required this.showBranding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: theme.cardColor, // Opaque color for better image capture
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
        mainAxisSize: MainAxisSize.min,
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
            AppLocalizations.of(context)!.thoughtOfTheDay,
            style: GoogleFonts.inter(
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          if (showBranding) ...[
            const SizedBox(height: 8),
            // Branding
            Text(
              "Silva",
              style: GoogleFonts.greatVibes(
                fontSize: 16,
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
