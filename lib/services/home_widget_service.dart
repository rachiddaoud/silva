import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:home_widget/home_widget.dart' as hw;

class HomeWidgetService {
  static const String appGroupId = 'group.com.rachid.silva.widgets';
  
  // Widget Names (must match iOS WidgetConfiguration)
  static const String quoteWidgetName = 'QuoteWidget';
  static const String treeWidgetName = 'TreeWidget';

  // Key names for UserDefaults/SharedPreferences
  static const String keyQuoteText = 'quote_text';
  static const String keyTreeImage = 'tree_image';
  static const String keyTreeImageData = 'tree_image_data'; // Base64 encoded for iOS

  /// Update the quote text in the widget
  static Future<void> updateQuote(String quote) async {
    try {
      // iOS workaround: Save directly to App Group via platform channel
      if (Platform.isIOS) {
        try {
          const platform = MethodChannel('com.rachid.silva/widget');
          await platform.invokeMethod('saveToAppGroup', {
            'key': keyQuoteText,
            'value': quote,
          });
          debugPrint('✅ [HomeWidget] Quote saved via platform channel to App Group');
        } catch (e) {
          debugPrint('⚠️ [HomeWidget] Platform channel failed: $e');
        }
      }
      
      // Also save via home_widget package (for Android and as fallback)
      // Save data - home_widget handles App Group automatically
      await hw.HomeWidget.saveWidgetData<String>(keyQuoteText, quote);
      
      debugPrint('✅ [HomeWidget] Quote saved: "${quote.substring(0, quote.length.clamp(0, 30))}..."');
      
      // VERIFY: Try to read it back immediately
      final readBack = await hw.HomeWidget.getWidgetData<String>(keyQuoteText);
      if (readBack != null) {
        debugPrint('✅ [HomeWidget] Quote verified - can read back: "${readBack.substring(0, readBack.length.clamp(0, 30))}..."');
      } else {
        debugPrint('❌ [HomeWidget] ERROR: Cannot read back saved quote!');
      }
      
      // Update Native Widgets
      await hw.HomeWidget.updateWidget(
        iOSName: quoteWidgetName,
        androidName: 'QuoteWidgetProvider',
      );
      debugPrint('✅ [HomeWidget] Quote widget updated');
    } catch (e) {
      debugPrint('❌ [HomeWidget] Error updating quote: $e');
    }
  }

  /// Render and update the tree image from a Flutter widget key
  static Future<void> updateTreeFromKey(GlobalKey key) async {
    try {
      // Wait to ensure images are loaded
      await Future.delayed(const Duration(milliseconds: 500));
      
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
      
      // Capture the image from the RepaintBoundary with high quality
      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('❌ [HomeWidget] Failed to convert image to byte data');
        return;
      }
      
      final pngBytes = byteData.buffer.asUint8List();
      
      // Save differently for iOS and Android
      if (Platform.isIOS) {
        // iOS: Save as base64 string which can be stored in UserDefaults
        final base64Image = base64Encode(pngBytes);
        await hw.HomeWidget.saveWidgetData<String>(keyTreeImageData, base64Image);
        debugPrint('✅ [HomeWidget] Tree image data saved (iOS) - ${pngBytes.length} bytes');
      } else {
        // Android: Save to file
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/tree_snapshot.png');
        await file.writeAsBytes(pngBytes);
        await hw.HomeWidget.saveWidgetData<String>(keyTreeImage, file.path);
        debugPrint('✅ [HomeWidget] Tree image saved (Android): ${file.path}');
      }
      
      // Update the widget
      await hw.HomeWidget.updateWidget(
        iOSName: treeWidgetName,
        androidName: 'TreeWidgetProvider',
      );
      debugPrint('✅ [HomeWidget] Tree widget update triggered');
    } catch (e) {
      debugPrint('❌ [HomeWidget] Error updating tree: $e');
    }
  }
}
