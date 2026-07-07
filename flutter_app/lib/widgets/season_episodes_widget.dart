import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/media.dart';

class SeasonEpisodesWidget extends StatefulWidget {
  final Media media;

  const SeasonEpisodesWidget({super.key, required this.media});

  @override
  State<SeasonEpisodesWidget> createState() => _SeasonEpisodesWidgetState();
}

class _SeasonEpisodesWidgetState extends State<SeasonEpisodesWidget> {
  Season? _selectedSeason;

  @override
  void initState() {
    super.initState();
    if (widget.media.seasons != null && widget.media.seasons!.isNotEmpty) {
      _selectedSeason = widget.media.seasons!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.seasons == null || widget.media.seasons!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Episodes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            if (widget.media.seasons!.length > 1) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Season>(
                      isExpanded: true,
                      value: _selectedSeason,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSubtle),
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: AppTheme.textMain, fontSize: 14),
                      onChanged: (Season? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedSeason = newValue;
                          });
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
        const SizedBox(height: 16),
        if (_selectedSeason != null && _selectedSeason!.episodes != null && _selectedSeason!.episodes!.isNotEmpty)
          ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _selectedSeason!.episodes!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final episode = _selectedSeason!.episodes![index];
              return _EpisodeTile(episode: episode);
            },
          )
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No episodes found for this season.',
                style: TextStyle(color: AppTheme.textSubtle),
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
        color: AppTheme.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
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
                      placeholder: (_, _) => Container(color: AppTheme.surfaceLight),
                      errorWidget: (_, _, _) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: AppTheme.textSubtle, size: 24),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.surfaceLight,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_rounded, color: AppTheme.textSubtle, size: 24),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
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
                        style: const TextStyle(
                          color: AppTheme.textMain,
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
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            episode.rating!.toStringAsFixed(1),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                if (episode.airDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    episode.airDate!,
                    style: const TextStyle(color: AppTheme.textSubtle, fontSize: 11),
                  ),
                ],
                if (episode.overview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    episode.overview,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.3),
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
