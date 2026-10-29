import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_providers.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return supabaseService.authStateChanges;
});

class GuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setGuest(bool value) {
    state = value;
  }
}

final isGuestProvider = NotifierProvider<GuestNotifier, bool>(GuestNotifier.new);

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? ref.watch(supabaseServiceProvider).getCurrentUser();
});

class AuthNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> signInWithGoogle() async {
    final supabaseService = ref.read(supabaseServiceProvider);
    await supabaseService.signInWithGoogle();
  }

  Future<void> signOut() async {
    final supabaseService = ref.read(supabaseServiceProvider);
    await supabaseService.signOut();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, void>(AuthNotifier.new);
