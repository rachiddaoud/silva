import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.rachid.silva.widgets';
  
  // Widget Names (must match iOS WidgetConfiguration)
  static const String quoteWidgetName = 'QuoteWidget';
  static const String treeWidgetName = 'TreeWidget';

  // Key names for UserDefaults/SharedPreferences
  static const String keyQuoteText = 'quote_text';
  static const String keyTreeImage = 'tree_image'; // This is the filename suffix usually

  /// Update the quote text in the widget
  static Future<void> updateQuote(String quote) async {
    try {
      // Save data
      await HomeWidget.saveWidgetData<String>(keyQuoteText, quote);
      
      // Update Native Widgets
      await HomeWidget.updateWidget(
        iOSName: quoteWidgetName,
        androidName: 'QuoteWidgetProvider',
      );
      debugPrint('✅ [HomeWidget] Quote Updated: "${quote.substring(0, 10)}..."');
    } catch (e) {
      debugPrint('❌ [HomeWidget] Error updating quote: $e');
    }
  }

  /// Render and update the tree image from a Flutter widget key
  static Future<void> updateTreeFromKey(GlobalKey key) async {
    try {
      // Get the RenderRepaintBoundary from the key's context
      final context = key.currentContext;
      if (context == null) {
        debugPrint('❌ [HomeWidget] Widget context not found for key');
        return;
      }
      
      final renderObject = context.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        debugPrint('❌ [HomeWidget] RenderRepaintBoundary not found');
        return;
      }
      
      // Capture the image from the RepaintBoundary
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('❌ [HomeWidget] Failed to convert image to byte data');
        return;
      }
      
      final pngBytes = byteData.buffer.asUint8List();
      
      // Save the image to a location accessible by the widget
      // For iOS: Save to App Group container via platform channel
      // For Android: Save to app's files directory
      String imagePath;
      
      if (Platform.isIOS) {
        // iOS: Use platform channel to save to App Group container
        const platform = MethodChannel('com.rachid.silva/widget_image');
        try {
          final filename = await platform.invokeMethod<String>(
            'saveImageToAppGroup',
            {
              'imageData': pngBytes,
              'filename': 'tree_snapshot.png',
            },
          );
          imagePath = filename ?? 'tree_snapshot.png';
          debugPrint('✅ [HomeWidget] Tree image saved to App Group (iOS): $imagePath');
        } catch (e) {
          debugPrint('❌ [HomeWidget] Error saving to App Group: $e');
          // Fallback: save to app support directory (won't be accessible by widget)
          final appSupportDir = await getApplicationSupportDirectory();
          final file = File('${appSupportDir.path}/tree_snapshot.png');
          await file.writeAsBytes(pngBytes);
          imagePath = 'tree_snapshot.png';
          debugPrint('⚠️ [HomeWidget] Fallback: saved to app support: ${file.path}');
        }
      } else {
        // Android: Save to app files directory
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/tree_snapshot.png');
        await file.writeAsBytes(pngBytes);
        imagePath = file.path; // Full path for Android
        debugPrint('✅ [HomeWidget] Tree image saved (Android): ${file.path}');
      }
      
      // Save the path/filename to UserDefaults/SharedPreferences
      await HomeWidget.saveWidgetData<String>(keyTreeImage, imagePath);

      // Update the widget
      await HomeWidget.updateWidget(
        iOSName: treeWidgetName,
        androidName: 'TreeWidgetProvider',
      );
      debugPrint('✅ [HomeWidget] Tree Updated from snapshot');
    } catch (e) {
      debugPrint('❌ [HomeWidget] Error updating tree: $e');
    }
  }
}
