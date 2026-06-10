import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'core/services/notification_service.dart';
import 'app.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Framework-Fehler: im Debug-Modus normal präsentieren, in Release
      // zumindest loggen statt spurlos zu verschwinden.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint(
            'FlutterError: ${details.exceptionAsString()}\n${details.stack}');
      };

      // Fehler aus der Platform-/Engine-Schicht (z. B. Plugin-Isolates).
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformDispatcher error: $error\n$stack');
        return true;
      };

      await _initializeTimeZone();
      await NotificationService.instance.initialize();
      runApp(const ProviderScope(child: KailibrateApp()));
    },
    (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
    },
  );
}

/// Lädt die Zeitzonen-Datenbank und setzt tz.local auf die Gerätezeitzone.
/// Ohne setLocalLocation bliebe tz.local auf UTC – geplante Erinnerungen
/// würden dann zur falschen Uhrzeit feuern.
Future<void> _initializeTimeZone() async {
  tz_data.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (e) {
    debugPrint('Zeitzone konnte nicht ermittelt werden, nutze UTC: $e');
  }
}
