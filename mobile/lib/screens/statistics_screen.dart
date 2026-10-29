import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme_extension.dart';
import '../providers/watchlist_provider.dart';
import '../models/watchlist_item.dart';
import '../models/media.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.colors.textMain),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Your Statistics',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Content
            Expanded(
              child: watchlistAsync.when(
                data: (watchlist) {
                  if (watchlist.isEmpty) {
                    return Center(
                      child: Text('Add some items to your watchlist to see your stats!'),
                    );
                  }

                  return _StatisticsContent(watchlist: watchlist);
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  final List<WatchlistItem> watchlist;
  const _StatisticsContent({required this.watchlist});

  @override
  Widget build(BuildContext context) {
    final totalCompleted = watchlist.where((i) => i.status == WatchStatus.completed).length;
    final totalWatching = watchlist.where((i) => i.status == WatchStatus.watching).length;
    final totalPlanToWatch = watchlist.where((i) => i.status == WatchStatus.planToWatch).length;

    final movies = watchlist.where((i) => i.mediaType == MediaType.movie).length;
    final series = watchlist.where((i) => i.mediaType == MediaType.series).length;
    final anime = watchlist.where((i) => i.mediaType == MediaType.anime).length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total items metric
          _MetricCard(
            title: 'Total Entries',
            value: watchlist.length.toString(),
            icon: Icons.movie_filter_rounded,
            color: context.colors.primary,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          
          SizedBox(height: 24),
          
          Text(
            'By Status',
            style: TextStyle(
              color: context.colors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _StatBox(title: 'Completed', value: totalCompleted.toString(), color: Colors.green)),
              SizedBox(width: 12),
              Expanded(child: _StatBox(title: 'Watching', value: totalWatching.toString(), color: Colors.blue)),
              SizedBox(width: 12),
              Expanded(child: _StatBox(title: 'Plan to Watch', value: totalPlanToWatch.toString(), color: Colors.orange)),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

          SizedBox(height: 32),
          
          Text(
            'By Type',
            style: TextStyle(
              color: context.colors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _StatBox(title: 'Movies', value: movies.toString(), color: Colors.purple)),
              SizedBox(width: 12),
              Expanded(child: _StatBox(title: 'TV Shows', value: series.toString(), color: Colors.pink)),
              SizedBox(width: 12),
              Expanded(child: _StatBox(title: 'Anime', value: anime.toString(), color: Colors.teal)),
            ],
          ).animate().fadeIn(duration: 300.ms, delay: 250.ms),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: context.colors.textSubtle, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: context.colors.textMain,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
