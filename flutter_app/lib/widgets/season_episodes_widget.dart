import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media.dart';
import '../providers/service_providers.dart';

class SeasonEpisodesWidget extends ConsumerStatefulWidget {
  final Media media;

  const SeasonEpisodesWidget({super.key, required this.media});

  @override
  ConsumerState<SeasonEpisodesWidget> createState() => _SeasonEpisodesWidgetState();
}

class _SeasonEpisodesWidgetState extends ConsumerState<SeasonEpisodesWidget> {
  Season? _selectedSeason;
  bool _isLoading = false;
  final Map<int, List<Episode>> _fetchedEpisodesCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.media.seasons != null && widget.media.seasons!.isNotEmpty) {
      _selectedSeason = widget.media.seasons!.first;
      if (_selectedSeason!.episodes != null && _selectedSeason!.episodes!.isNotEmpty) {
        _fetchedEpisodesCache[_selectedSeason!.number] = _selectedSeason!.episodes!;
      }
    }
  }

  List<Episode>? get _currentEpisodes {
    if (_selectedSeason == null) return null;
    if (_selectedSeason!.episodes != null && _selectedSeason!.episodes!.isNotEmpty) {
      return _selectedSeason!.episodes;
    }
    return _fetchedEpisodesCache[_selectedSeason!.number];
  }

  Future<void> _fetchEpisodesIfNeed(Season season) async {
    if (season.episodes != null && season.episodes!.isNotEmpty) return;
    if (_fetchedEpisodesCache.containsKey(season.number)) return;

    setState(() => _isLoading = true);
    try {
      final tmdb = ref.read(tmdbServiceProvider);
      final detailedSeason = await tmdb.getTVSeasonDetails(widget.media.externalId, season.number);
      if (detailedSeason != null && detailedSeason.episodes != null) {
        _fetchedEpisodesCache[season.number] = detailedSeason.episodes!;
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to load season episodes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.seasons == null || widget.media.seasons!.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Episodes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textMain,
              ),
            ),
            if (widget.media.seasons!.length > 1) ...[
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 16),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Season>(
                      isExpanded: true,
                      value: _selectedSeason,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textSubtle),
                      dropdownColor: context.colors.surface,
                      style: TextStyle(color: context.colors.textMain, fontSize: 14),
                      onChanged: (Season? newValue) {
                        if (newValue != null && newValue.number != _selectedSeason?.number) {
                          setState(() {
                            _selectedSeason = newValue;
                          });
                          _fetchEpisodesIfNeed(newValue);
                        }
                      },
                      items: widget.media.seasons!.map<DropdownMenuItem<Season>>((Season season) {
                        return DropdownMenuItem<Season>(
                          value: season,
                          child: Text(
                            season.name.isNotEmpty ? season.name : 'Season ${season.number}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 16),
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: context.colors.primary),
            ),
          )
        else if (_currentEpisodes != null && _currentEpisodes!.isNotEmpty)
          ListView.separated(
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _currentEpisodes!.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final episode = _currentEpisodes![index];
              return _EpisodeTile(episode: episode);
            },
          )
        else
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No episodes found for this season.',
                style: TextStyle(color: context.colors.textSubtle),
              ),
            ),
          ),
      ],
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;

  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Still image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 100,
              height: 60,
              child: episode.stillUrl != null && episode.stillUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: episode.stillUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(color: context.colors.surfaceLight),
                      errorWidget: (_, _, _) => Container(
                        color: context.colors.surfaceLight,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, color: context.colors.textSubtle, size: 24),
                        ),
                      ),
                    )
                  : Container(
                      color: context.colors.surfaceLight,
                      child: Center(
                        child: Icon(Icons.image_not_supported_rounded, color: context.colors.textSubtle, size: 24),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12),
          // Episode info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${episode.number}. ${episode.name}',
                        style: TextStyle(
                          color: context.colors.textMain,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (episode.rating != null && episode.rating! > 0)
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          SizedBox(width: 2),
                          Text(
                            episode.rating!.toStringAsFixed(1),
                            style: TextStyle(color: context.colors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                if (episode.airDate != null) ...[
                  SizedBox(height: 4),
                  Text(
                    episode.airDate!,
                    style: TextStyle(color: context.colors.textSubtle, fontSize: 11),
                  ),
                ],
                if (episode.overview.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(
                    episode.overview,
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
