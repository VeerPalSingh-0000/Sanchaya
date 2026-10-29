import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../config/theme_extension.dart';

/// Action button placed in the top media details action row alongside Watchlist and Reaction
class NotesActionButton extends ConsumerWidget {
  final WatchlistItem item;

  const NotesActionButton({super.key, required this.item});

  void _showNotesSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: item.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: context.colors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.sticky_note_2_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Notes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textMain,
                                    ),
                                  ),
                                  Text(
                                    'Only visible to you',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: context.colors.textSubtle,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        maxLines: 5,
                        minLines: 3,
                        autofocus: true,
                        style: TextStyle(color: context.colors.textMain, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Write your thoughts, opinions, or reminders...',
                          hintStyle: TextStyle(
                            color: context.colors.textSubtle.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (item.notes != null && item.notes!.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(ctx);
                                final allItems = ref.read(watchlistProvider).value ?? [];
                                final franchiseItems = item.franchiseId != null
                                    ? allItems.where((i) => i.franchiseId == item.franchiseId).toList()
                                    : [item];
                                for (final i in franchiseItems) {
                                  await ref.read(watchlistProvider.notifier).addOrUpdate(
                                    i.copyWith(notes: null),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                              label: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: context.colors.textSubtle, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              final text = controller.text.trim();
                              Navigator.pop(ctx);
                              final allItems = ref.read(watchlistProvider).value ?? [];
                              final franchiseItems = item.franchiseId != null
                                  ? allItems.where((i) => i.franchiseId == item.franchiseId).toList()
                                  : [item];
                              for (final i in franchiseItems) {
                                await ref.read(watchlistProvider.notifier).addOrUpdate(
                                  i.copyWith(notes: text.isEmpty ? null : text),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text(
                              'Save Note',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotes = item.notes != null && item.notes!.trim().isNotEmpty;
    final isWide = MediaQuery.of(context).size.width > 480;

    return Material(
      color: hasNotes
          ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
          : context.colors.surfaceLight.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _showNotesSheet(context, ref),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: (hasNotes && isWide) ? 14 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasNotes
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
              width: hasNotes ? 1.5 : 1.0,
            ),
            boxShadow: hasNotes
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasNotes ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
                color: hasNotes ? const Color(0xFFF59E0B) : context.colors.textMain,
                size: 22,
              ),
              if (hasNotes && isWide) ...[
                const SizedBox(width: 6),
                const Text(
                  'Notes',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Detailed note display section below the overview
class NotesWidget extends ConsumerStatefulWidget {
  final WatchlistItem item;

  const NotesWidget({super.key, required this.item});

  @override
  ConsumerState<NotesWidget> createState() => _NotesWidgetState();
}

class _NotesWidgetState extends ConsumerState<NotesWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.notes);
  }

  @override
  void didUpdateWidget(covariant NotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.notes != widget.item.notes && !_isEditing) {
      _controller.text = widget.item.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final text = _controller.text.trim();
      final allItems = ref.read(watchlistProvider).value ?? [];
      final franchiseItems = widget.item.franchiseId != null
          ? allItems.where((i) => i.franchiseId == widget.item.franchiseId).toList()
          : [widget.item];

      for (final i in franchiseItems) {
        await ref.read(watchlistProvider.notifier).addOrUpdate(
          i.copyWith(notes: text.isEmpty ? null : text),
        );
      }

      setState(() {
        _isEditing = false;
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      final hasNotes = widget.item.notes != null && widget.item.notes!.trim().isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_rounded,
                    size: 20,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textMain,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: Icon(Icons.edit_rounded, size: 16, color: context.colors.primary),
                label: Text(
                  hasNotes ? 'Edit' : 'Add',
                  style: TextStyle(color: context.colors.primary, fontSize: 14),
                ),
              ),
            ],
          ),
          if (hasNotes) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
              ),
              child: Text(
                widget.item.notes!,
                style: TextStyle(
                  color: context.colors.textMain.withValues(alpha: 0.9),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.sticky_note_2_rounded,
              size: 20,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            Text(
              'Edit Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 5,
          minLines: 3,
          style: TextStyle(color: context.colors.textMain, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Write your review or thoughts here...',
            hintStyle: TextStyle(color: context.colors.textSubtle.withValues(alpha: 0.5)),
            filled: true,
            fillColor: context.colors.surfaceLight,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.colors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _controller.text = widget.item.notes ?? '';
                  _isEditing = false;
                });
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: context.colors.textSubtle),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
