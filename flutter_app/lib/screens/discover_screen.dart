import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/media.dart';
import '../providers/search_provider.dart';
import '../widgets/media_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/aesthetic_loader.dart';
import '../providers/watchlist_provider.dart';
import '../providers/auth_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  final bool isSearchMode;
  const DiscoverScreen({super.key, this.isSearchMode = false});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.isSearchMode) {
      Future.delayed(Duration(milliseconds: 100), () => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(widget.isSearchMode ? homeSearchQueryProvider : discoverSearchQueryProvider);
    final filter = ref.watch(widget.isSearchMode ? homeSearchFilterProvider : discoverSearchFilterProvider);
    final results = ref.watch(widget.isSearchMode ? homeSearchResultsProvider : discoverSearchResultsProvider);

    return Scaffold(
      appBar: ProfileAppBar(title: widget.isSearchMode ? 'Search' : 'Discover'),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),

            // ── Search bar ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (value) {
                  ref.read(widget.isSearchMode ? homeSearchQueryProvider.notifier : discoverSearchQueryProvider.notifier).updateQuery(value);
                },
                style: TextStyle(color: context.colors.textMain, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search movies, TV shows & anime...',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: context.colors.textSubtle, size: 22),
                  suffixIcon: query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            ref.read(widget.isSearchMode ? homeSearchQueryProvider.notifier : discoverSearchQueryProvider.notifier).updateQuery('');
                          },
                          child: Icon(Icons.close_rounded,
                              color: context.colors.textSubtle, size: 20),
                        )
                      : null,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 50.ms),

            SizedBox(height: 14),

            // ── Filter chips ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MediaFilter.values.map((f) {
                    final isSelected = filter == f;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(widget.isSearchMode ? homeSearchFilterProvider.notifier : discoverSearchFilterProvider.notifier).updateFilter(f);
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.primary.withValues(alpha: 0.2)
                                : context.colors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? context.colors.primary.withValues(alpha: 0.5)
                                  : context.colors.divider.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _filterLabel(f),
                            style: TextStyle(
                              color:
                                  isSelected ? context.colors.primary : context.colors.textMuted,
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

            if (query.startsWith('#genre:'))
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 16),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 16, color: context.colors.primary),
                    SizedBox(width: 8),
                    Text('Browsing: ', style: TextStyle(color: context.colors.textSubtle, fontSize: 13)),
                    Text(
                      _GenreChips.popularGenres[int.tryParse(query.split(':')[1])] ?? 'Unknown',
                      style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ).animate().fadeIn(duration: 200.ms),
              ),

            SizedBox(height: 16),

            // ── Results ──
            Expanded(
              child: query.isEmpty
                  ? _EmptySearchState(isSearchMode: widget.isSearchMode)
                  : results.when(
                      data: (result) {
                        if (result.results.isEmpty) {
                          return _NoResults(query: query);
                        }
                        return _ResultsGrid(
                          results: result.results,
                          isSearchMode: widget.isSearchMode,
                          hasNextPage: result.page < result.totalPages,
                        );
                      },
                      loading: () => const _LoadingGrid(),
                      error: (e, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: context.colors.error, size: 36),
                            SizedBox(height: 12),
                            Text(
                              'Something went wrong',
                              style: TextStyle(color: context.colors.textMuted),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                e.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.colors.error.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(MediaFilter f) {
    switch (f) {
      case MediaFilter.all:
        return 'All';
      case MediaFilter.movie:
        return 'Movies';
      case MediaFilter.series:
        return 'TV Shows';
      case MediaFilter.anime:
        return 'Anime';
    }
  }
}

// ────────────────────────────────────────────────────────────
// Empty state
// ────────────────────────────────────────────────────────────

class _EmptySearchState extends StatelessWidget {
  final bool isSearchMode;
  const _EmptySearchState({required this.isSearchMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_rounded,
              color: context.colors.primary,
              size: 36,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Discover something new',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Search for movies, TV shows & anime',
            style: TextStyle(
              color: context.colors.textSubtle,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 32),
          if (!isSearchMode) _GenreChips(isSearchMode: isSearchMode),
        ],
      ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: Offset(0.9, 0.9),
          end: Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}

class _GenreChips extends ConsumerWidget {
  final bool isSearchMode;
  const _GenreChips({required this.isSearchMode});

  static const Map<int, String> popularGenres = {
    28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy',
    80: 'Crime', 18: 'Drama', 14: 'Fantasy', 27: 'Horror',
    9648: 'Mystery', 10749: 'Romance', 878: 'Sci-Fi', 53: 'Thriller',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Browse by Genre',
            style: TextStyle(
              color: context.colors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 12,
            children: popularGenres.entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  final provider = isSearchMode ? homeSearchQueryProvider : discoverSearchQueryProvider;
                  ref.read(provider.notifier).updateQuery('#genre:${entry.key}');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: context.colors.textSubtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              color: context.colors.textSubtle, size: 48),
          SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different search term',
            style: TextStyle(color: context.colors.textSubtle, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Results grid
// ────────────────────────────────────────────────────────────

class _ResultsGrid extends ConsumerStatefulWidget {
  final List<Media> results;
  final bool isSearchMode;
  final bool hasNextPage;

  const _ResultsGrid({required this.results, required this.isSearchMode, required this.hasNextPage});

  @override
  ConsumerState<_ResultsGrid> createState() => _ResultsGridState();
}

class _ResultsGridState extends ConsumerState<_ResultsGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasNextPage) {
        final notifier = widget.isSearchMode 
            ? ref.read(homeSearchResultsProvider.notifier) 
            : ref.read(discoverSearchResultsProvider.notifier);
        notifier.fetchNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) return SizedBox.shrink();

    final firstItem = widget.results.first;
    final otherItems = widget.results.skip(1).toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _FeaturedCard(media: firstItem),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.46,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final media = otherItems[index];
                final year = media.releaseDate != null && media.releaseDate!.length >= 4
                    ? media.releaseDate!.substring(0, 4)
                    : null;

                String? badge;
                switch (media.type) {
                  case MediaType.movie:
                    badge = 'MOVIE';
                    break;
                  case MediaType.series:
                    badge = 'TV';
                    break;
                  case MediaType.anime:
                    badge = 'ANIME';
                    break;
                }

                return MediaCard(
                  title: media.title,
                  posterUrl: media.franchisePosterUrl ?? media.posterUrl,
                  rating: media.rating,
                  subtitle: year,
                  width: double.infinity,
                  height: 155, // Reduced slightly to ensure text fits
                  typeBadge: badge,
                  isAdded: ref.watch(watchlistProvider.notifier).isAdded(media),
                  onTap: () => context.push('/media/${media.id}'),
                  onAddWatchlist: () {
                    final user = ref.read(currentUserProvider);
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please sign in to use watchlist')),
                      );
                      return;
                    }
                    
                    ref.read(watchlistProvider.notifier).addMediaToWatchlist(media, WatchStatus.planToWatch);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${media.title} added to Plan to Watch',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: context.colors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ).animate().fadeIn(
                      duration: 300.ms,
                      delay: index > 12 ? Duration.zero : Duration(milliseconds: (20 * index).clamp(0, 150)),
                    );
              },
              childCount: otherItems.length,
            ),
          ),
        ),
        if (widget.hasNextPage)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: Center(
                child: AestheticLoader(size: 30),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: Center(
                child: Text(
                  'You\'ve reached the end!',
                  style: TextStyle(color: context.colors.textSubtle, fontSize: 13),
                ),
              ),
            ),
          )
      ],
    );
  }
}

class _FeaturedCard extends ConsumerWidget {
  final Media media;
  const _FeaturedCard({required this.media});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = media.releaseDate != null && media.releaseDate!.length >= 4 ? media.releaseDate!.substring(0, 4) : '';
    
    return GestureDetector(
      onTap: () => context.push('/media/${media.id}'),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(media.backdropUrl ?? media.posterUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              SizedBox(height: 8),
              Text(
                media.title, 
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  if (media.rating > 0) ...[
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(media.rating.toStringAsFixed(1), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(width: 12),
                  ],
                  if (year.isNotEmpty) Text(year, style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.46,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: 9,
      itemBuilder: (_, _) => ShimmerCard(
        width: double.infinity,
        height: 170,
      ),
    );
  }
}
