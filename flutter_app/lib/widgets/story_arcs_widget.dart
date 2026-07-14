import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/media.dart';
import '../providers/anime_episodes_provider.dart';
import 'aesthetic_loader.dart';

class StoryArcsWidget extends ConsumerStatefulWidget {
  final Media media;

  const StoryArcsWidget({super.key, required this.media});

  @override
  ConsumerState<StoryArcsWidget> createState() => _StoryArcsWidgetState();
}

class _ArcGroup {
  final String groupName;
  final List<Episode> episodes;

  _ArcGroup(this.groupName, this.episodes);
}

class _StoryArcsWidgetState extends ConsumerState<StoryArcsWidget> {
  int? _openArcIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.media.type != MediaType.anime || widget.media.malId == null || widget.media.malId! <= 0) {
      return SizedBox.shrink();
    }

    final episodesAsync = ref.watch(animeEpisodesProvider(widget.media.malId!));

    return episodesAsync.when(
      data: (episodes) {
        if (episodes.isEmpty) return SizedBox.shrink();

        List<_ArcGroup> groupedEpisodes = [];
        String currentGroupName = '';
        List<Episode> currentGroup = [];

        for (var ep in episodes) {
          final groupName = ep.sagaName ?? ep.arcName ?? 'Unknown Arc';
          if (groupName != currentGroupName) {
            if (currentGroup.isNotEmpty) {
              groupedEpisodes.add(_ArcGroup(currentGroupName, currentGroup));
            }
            currentGroupName = groupName;
            currentGroup = [ep];
          } else {
            currentGroup.add(ep);
          }
        }
        if (currentGroup.isNotEmpty) {
          groupedEpisodes.add(_ArcGroup(currentGroupName, currentGroup));
        }

        if (groupedEpisodes.length == 1) {
          final group = groupedEpisodes[0];
          final isOpen = _openArcIndex == 0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _openArcIndex = isOpen ? null : 0;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.play_circle_filled_rounded, color: context.colors.primary, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'EPISODES',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: context.colors.textMain,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                '${group.episodes.length} EP',
                                style: TextStyle(
                                  color: context.colors.textSubtle,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: context.colors.textSubtle,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: isOpen
                      ? Container(
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.all(8),
                            itemCount: group.episodes.length,
                            separatorBuilder: (_, _) => SizedBox(height: 4),
                            itemBuilder: (context, epIdx) {
                              final ep = group.episodes[epIdx];
                              return GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Playing ${ep.name.isNotEmpty ? ep.name : "Episode ${ep.number}"}'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: context.colors.background.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          ep.number.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            color: context.colors.textMuted.withValues(alpha: 0.5),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ep.name.isNotEmpty ? ep.name : 'Episode ${ep.number}',
                                          style: TextStyle(
                                            color: context.colors.textMain,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.map_rounded, color: context.colors.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'STORY ARCS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: context.colors.textMain,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              SizedBox(height: 24),

              // Vertical Timeline
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: groupedEpisodes.length,
                itemBuilder: (context, index) {
                  final group = groupedEpisodes[index];
                  final isOpen = _openArcIndex == index;
                  final isLast = index == groupedEpisodes.length - 1;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Arc Content with Border (Timeline Line)
                      Container(
                        margin: EdgeInsets.only(left: 20),
                        padding: EdgeInsets.only(left: 24, bottom: 24, right: 8),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  left: BorderSide(
                                    width: 2,
                                    color: context.colors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _openArcIndex = isOpen ? null : index;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isOpen ? context.colors.surfaceLight.withValues(alpha: 0.5) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: isOpen ? Border.all(color: context.colors.primary.withValues(alpha: 0.3)) : Border.all(color: Colors.transparent),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ARC ${(index + 1).toString().padLeft(2, '0')}',
                                                style: TextStyle(
                                                  color: context.colors.primary.withValues(alpha: 0.8),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                group.groupName,
                                                style: TextStyle(
                                                  color: isOpen ? context.colors.primary : context.colors.textMain,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                          ),
                                          child: Text(
                                            '${group.episodes.length} EP',
                                            style: TextStyle(
                                              color: context.colors.textSubtle,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Dropdown Episodes
                                AnimatedSize(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  alignment: Alignment.topCenter,
                                  child: isOpen
                                      ? Container(
                                          margin: EdgeInsets.only(top: 8, left: 16),
                                          decoration: BoxDecoration(
                                            color: context.colors.surfaceLight,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                          ),
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            physics: NeverScrollableScrollPhysics(),
                                            padding: EdgeInsets.all(8),
                                            itemCount: group.episodes.length,
                                            separatorBuilder: (_, _) => SizedBox(height: 4),
                                            itemBuilder: (context, epIdx) {
                                            final ep = group.episodes[epIdx];
                                            final showArcHeader = ep.sagaName != null && ep.arcName != null && (epIdx == 0 || group.episodes[epIdx - 1].arcName != ep.arcName);

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (showArcHeader)
                                                  Padding(
                                                    padding: EdgeInsets.only(left: 8, top: 8, bottom: 4),
                                                    child: Text(
                                                      ep.arcName!.toUpperCase(),
                                                      style: TextStyle(
                                                        color: context.colors.primary.withValues(alpha: 0.8),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                GestureDetector(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Playing ${ep.name.isNotEmpty ? ep.name : "Episode ${ep.number}"}'),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  },
                                                  behavior: HitTestBehavior.opaque,
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: context.colors.background.withValues(alpha: 0.5),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 24,
                                                        child: Text(
                                                          ep.number.toString().padLeft(2, '0'),
                                                          style: TextStyle(
                                                            color: context.colors.textMuted.withValues(alpha: 0.5),
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          ep.name.isNotEmpty ? ep.name : 'Episode ${ep.number}',
                                                          style: TextStyle(
                                                            color: context.colors.textMain,
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      if (ep.isFiller == true)
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.redAccent.withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                                                          ),
                                                          child: Text('FILLER', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                                        )
                                                      else if (ep.isRecap == true)
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orangeAccent.withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                                                          ),
                                                          child: Text('RECAP', style: TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                                        )
                                                      else
                                                        Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blueAccent.withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                                                          ),
                                                          child: Text('CANON', style: TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              ],
                                            );
                                          },
                                        ),
                                      )
                                      : SizedBox.shrink(),
                                ),
                          ],
                        ),
                      ),

                      // Timeline Node (Circle)
                      Positioned(
                        left: isOpen ? 10 : 12,
                        top: 16,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _openArcIndex = isOpen ? null : index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: isOpen ? 20 : 16,
                            height: isOpen ? 20 : 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOpen ? context.colors.primary : context.colors.surfaceLight,
                              border: Border.all(
                                color: context.colors.primary,
                                width: isOpen ? 4 : 2,
                              ),
                              boxShadow: isOpen
                                  ? [BoxShadow(color: context.colors.primary.withValues(alpha: 0.6), blurRadius: 10)]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
                },
              ),
            ],
          ),
        );
      },
      loading: () => Center(child: Padding(padding: EdgeInsets.all(32), child: AestheticLoader(size: 40))),
      error: (_, _) => SizedBox.shrink(),
    );
  }
}

