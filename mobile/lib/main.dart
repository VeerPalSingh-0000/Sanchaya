import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';
import 'config/constants.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'checkNewEpisodes') {
      try {
        await dotenv.load(fileName: ".env");
        // In a real scenario, we would instantiate AnilistService or TMDBService here,
        // fetch the watchlist from local cache or Supabase, check for new episodes,
        // and trigger notifications.
        // For demonstration of Phase 6:
        await NotificationService().init();
        await NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'New Episode Alert!',
          body: 'A new episode of a show you are tracking is out!',
        );
      } catch (e) {
        debugPrint('Background task error: $e');
      }
    }
    return Future.value(true);
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  
  // Initialize Workmanager for background tasks
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode, // shows notification when task runs in debug
  );
  
  // Schedule a periodic task for checking episodes (e.g. every 12 hours)
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    Workmanager().registerPeriodicTask(
      "episodes-check", 
      "checkNewEpisodes", 
      frequency: const Duration(hours: 12),
    );
  }

  // Initialize Supabase — wrapped in a timeout so the app starts even
  // when the network is unreachable (DNS failure, offline, etc.).
  // The underlying Future continues in the background even after timeout,
  // so Supabase.instance will eventually become available.
  try {
    await Supabase.initialize(
      url: Constants.supabaseUrl,
      publishableKey: Constants.supabaseAnonKey,
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('[Supabase] Initialization failed or timed out: $e — '
        'app will start without auth; auth recovers when connectivity returns.');
  }

  // Initialize Google Sign In (only on supported platforms)
  if (kIsWeb || 
      defaultTargetPlatform == TargetPlatform.android || 
      defaultTargetPlatform == TargetPlatform.iOS || 
      defaultTargetPlatform == TargetPlatform.macOS) {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: Constants.googleWebClientId,
        serverClientId: kIsWeb ? null : Constants.googleWebClientId,
      );
    } catch (e) {
      debugPrint('GoogleSignIn initialization failed: $e');
    }
  }

  // Initialize Cache
  final cacheService = CacheService();
  await cacheService.init();

  runApp(
    ProviderScope(
      overrides: [
        // We can override providers with pre-initialized instances if needed,
        // but our cache service is already a singleton in practice or we can just inject it.
      ],
      child: const SanchayaApp(),
    ),
  );
}
