import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/theme_extension.dart';
import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/optimized_network_image.dart';

class WatchHistoryScreen extends ConsumerWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(
          'Watch History',
          style: TextStyle(
            color: context.colors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textMain),
          onPressed: () => context.pop(),
        ),
      ),
      body: watchlistAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No history found.',
                style: TextStyle(color: context.colors.textSubtle),
              ),
            );
          }

          // Filter for COMPLETED items or items with progress, then sort by updatedAt desc
          final historyItems = items.where((item) => item.status == 'COMPLETED' || (item.progress != null && item.progress! > 0)).toList();
          
          historyItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          if (historyItems.isEmpty) {
            return Center(
              child: Text(
                'No watched items yet.',
                style: TextStyle(color: context.colors.textSubtle),
              ),
            );
          }

          // Group by date (e.g. Today, Yesterday, or MM/dd/yyyy)
          final Map<String, List<WatchlistItem>> grouped = {};
          final now = DateTime.now();
          final todayStr = DateFormat('yyyy-MM-dd').format(now);
          final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

          for (final item in historyItems) {
            final dateStr = DateFormat('yyyy-MM-dd').format(item.updatedAt.toLocal());
            String groupKey = dateStr;
            if (dateStr == todayStr) {
              groupKey = 'Today';
            } else if (dateStr == yesterdayStr) {
              groupKey = 'Yesterday';
            } else {
              groupKey = DateFormat('MMMM d, yyyy').format(item.updatedAt.toLocal());
            }

            grouped.putIfAbsent(groupKey, () => []).add(item);
          }

          final groupKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupKeys.length,
            itemBuilder: (context, index) {
              final key = groupKeys[index];
              final list = grouped[key]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          key,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: context.colors.divider,
                          width: 2,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 20, bottom: 16),
                    child: Column(
                      children: list.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              context.push('/details/${item.externalId}');
                            },
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 50,
                                    height: 75,
                                    child: item.posterUrl.isNotEmpty
                                        ? OptimizedNetworkImage(
                                            imageUrl: item.posterUrl,
                                            memCacheHeight: 150,
                                          )
                                        : Container(color: context.colors.surfaceLight),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          color: context.colors.textMain,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.status == 'COMPLETED' 
                                            ? 'Completed' 
                                            : 'Watched Ep ${item.progress}',
                                        style: TextStyle(
                                          color: context.colors.textSubtle,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat('jm').format(item.updatedAt.toLocal()),
                                  style: TextStyle(
                                    color: context.colors.textSubtle,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Error loading history: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
