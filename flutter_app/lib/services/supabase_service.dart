import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../models/watchlist_item.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      return;
    }

    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  // Get or Create Prisma User ID to sync with web app
  Future<String> getOrCreatePrismaUserId(User user) async {
    final email = user.email;
    if (email == null) throw 'User has no email';
    
    final response = await _supabase
        .from('User')
        .select('id')
        .eq('email', email)
        .maybeSingle();
        
    if (response != null) {
      return response['id'] as String;
    }
    
    // Create new user in Prisma User table to sync auth
    final newId = 'c${user.id.replaceAll("-", "").substring(0, 24)}';
    await _supabase.from('User').insert({
      'id': newId,
      'email': email,
      'name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'User',
      'image': user.userMetadata?['avatar_url'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return newId;
  }

  // Watchlist CRUD operations
  Future<List<WatchlistItem>> getWatchlist(String userId) async {
    final response = await _supabase
        .from('WatchlistItem')
        .select()
        .eq('userId', userId)
        .order('updatedAt', ascending: false);

    return (response as List<dynamic>)
        .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToWatchlist(String userId, WatchlistItem item) async {
    final data = item.toJson();
    data['userId'] = userId;
    
    // In Supabase, usually we shouldn't pass id if it's auto-generated UUID,
    // but Prisma uses cuid/uuid. We'll let Supabase handle upsert via constraints 
    // or just insert if it's a new item.
    
    await _supabase.from('WatchlistItem').upsert(
      data,
      onConflict: 'userId, mediaId, mediaType', // Assuming a unique constraint exists
    );
  }

  Future<void> updateWatchlistItem(String id, Map<String, dynamic> fields) async {
    fields['updatedAt'] = DateTime.now().toIso8601String();
    await _supabase.from('WatchlistItem').update(fields).eq('id', id);
  }

  Future<void> removeFromWatchlist(String userId, String externalId, String mediaType) async {
    await _supabase
        .from('WatchlistItem')
        .delete()
        .eq('userId', userId)
        .eq('mediaId', externalId)
        .eq('mediaType', mediaType);
  }
}
