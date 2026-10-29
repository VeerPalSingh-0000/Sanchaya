import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  
  // Check initial state
  final results = await connectivity.checkConnectivity();
  yield results.any((result) => result != ConnectivityResult.none);
  
  // Listen to changes
  yield* connectivity.onConnectivityChanged.map((results) {
    return results.any((result) => result != ConnectivityResult.none);
  });
});
