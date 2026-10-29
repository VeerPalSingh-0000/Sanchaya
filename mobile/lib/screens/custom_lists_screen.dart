import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme_extension.dart';
import '../providers/custom_lists_provider.dart';

class CustomListsScreen extends ConsumerWidget {
  const CustomListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customListsAsync = ref.watch(customListsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(
          'My Custom Lists',
          style: TextStyle(
            color: context.colors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textMain),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: context.colors.primary),
            onPressed: () => _showCreateListDialog(context, ref),
          ),
        ],
      ),
      body: customListsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.format_list_bulleted_add, size: 64, color: context.colors.textSubtle),
                  const SizedBox(height: 16),
                  Text(
                    'No custom lists yet',
                    style: TextStyle(color: context.colors.textMain, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create lists like "Weekend Binge" or "Favorites"',
                    style: TextStyle(color: context.colors.textSubtle),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showCreateListDialog(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create a List'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Card(
                color: context.colors.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    list['name'],
                    style: TextStyle(
                      color: context.colors.textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: list['description'] != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            list['description'],
                            style: TextStyle(color: context.colors.textSubtle),
                          ),
                        )
                      : null,
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.7)),
                    onPressed: () {
                      _showDeleteConfirmation(context, ref, list['id'], list['name']);
                    },
                  ),
                  onTap: () {
                    // Navigate to custom list detail if implemented, 
                    // or just show a snackbar for now.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped ${list['name']}')),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.surface,
          title: Text('Create Custom List', style: TextStyle(color: context.colors.textMain)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: context.colors.textMain),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: context.colors.textSubtle),
                  filled: true,
                  fillColor: context.colors.background,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: context.colors.textMain),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: context.colors.textSubtle),
                  filled: true,
                  fillColor: context.colors.background,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSubtle)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(customListsProvider.notifier).createList(name, descController.text.trim());
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String listId, String listName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.colors.surface,
          title: Text('Delete List?', style: TextStyle(color: context.colors.textMain)),
          content: Text('Are you sure you want to delete "$listName"?', style: TextStyle(color: context.colors.textSubtle)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSubtle)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(customListsProvider.notifier).deleteList(listId);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
