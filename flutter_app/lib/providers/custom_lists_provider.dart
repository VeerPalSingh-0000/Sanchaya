import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

final customListsProvider = AsyncNotifierProvider<CustomListsNotifier, List<Map<String, dynamic>>>(() {
  return CustomListsNotifier();
});

class CustomListsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    
    final supabase = ref.read(supabaseServiceProvider);
    return await supabase.getCustomLists(user.id);
  }

  Future<void> createList(String name, String? description) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.createCustomList(user.id, name, description);
    ref.invalidateSelf();
  }

  Future<void> deleteList(String listId) async {
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.deleteCustomList(listId);
    ref.invalidateSelf();
  }
}

final customListItemsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, listId) async {
  final supabase = ref.read(supabaseServiceProvider);
  return await supabase.getCustomListItems(listId);
});
