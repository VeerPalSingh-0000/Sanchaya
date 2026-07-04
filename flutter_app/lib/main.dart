import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'config/constants.dart';
import 'services/cache_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    publishableKey: Constants.supabaseAnonKey,
  );

  // Initialize Google Sign In
  await GoogleSignIn.instance.initialize(
    clientId: Constants.googleWebClientId,
    serverClientId: kIsWeb ? null : Constants.googleWebClientId,
  );

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
