import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../config/theme_extension.dart';

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
      final updatedItem = widget.item.copyWith(
        notes: _controller.text.isEmpty ? null : _controller.text,
      );
      await ref.read(watchlistProvider.notifier).addOrUpdate(updatedItem);
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
      final hasNotes = widget.item.notes != null && widget.item.notes!.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMain,
                ),
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
          if (hasNotes)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
              ),
              child: Text(
                widget.item.notes!,
                style: TextStyle(
                  color: context.colors.textSubtle,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textMain,
          ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.divider.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
