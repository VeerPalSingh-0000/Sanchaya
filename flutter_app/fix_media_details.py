import re

with open('lib/screens/media_details_screen.dart', 'r') as f:
    content = f.read()

# 1. Replace the MediaDetailsScreen class up to CustomScrollView
new_screen = """class MediaDetailsScreen extends ConsumerWidget {
  final String mediaId;
  final Media? initialMedia;

  const MediaDetailsScreen({super.key, required this.mediaId, this.initialMedia});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialMedia != null) {
      return _MediaDetailsScaffold(baseMedia: initialMedia!, mediaId: mediaId);
    }

    final mediaAsync = ref.watch(mediaDetailsProvider(mediaId));
    
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Builder(
        builder: (context) {
          if (mediaAsync.isLoading) {
            return Center(
              child: AestheticLoader(size: 60),
            );
          }
          final media = mediaAsync.value;
          if (media == null) {
            return _buildError(context, ref, 'Media not found.');
          }
          return _MediaDetailsScaffold(baseMedia: media, mediaId: mediaId);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
"""

content = re.sub(r'class MediaDetailsScreen extends ConsumerWidget \{.*?Widget _buildError\(BuildContext context, WidgetRef ref, String message\) \{', new_screen, content, flags=re.DOTALL)

# 2. Extract _MediaDetailsScaffold
# We need to find the `_buildError` end and insert `_MediaDetailsScaffold` before `_CollapsibleOverview`.
# First, let's fix the inner parts of the CustomScrollView that used `media` and `baseMedia`.
# Actually, I'll just write the entire _MediaDetailsScaffold manually to avoid regex nightmares.

# Let's extract the CustomScrollView from the original file first.
custom_scroll_view_match = re.search(r'(return CustomScrollView\(.*?\]\s*,\s*\);\s*},)', content, flags=re.DOTALL)
if custom_scroll_view_match:
    scroll_view_code = custom_scroll_view_match.group(1)
    # Remove the `},` at the end
    scroll_view_code = re.sub(r'\};\s*\},$', '}', scroll_view_code)
    scroll_view_code = scroll_view_code.rstrip(',\n }') + ';'
    
    # We need to replace all `baseMedia.` and `media.` with `baseMedia.` inside the static parts
    # And create a Consumer for the dynamic parts.
    
    # Remove the duplicated Overview block.
    # The duplicate is:
    duplicate_overview_pattern = r'SizedBox\(height: 24\),\s*// Overview\s*Text\(\s*\'Overview\',\s*style: TextStyle\(.*?_CollapsibleOverview\(.*?\.animate\(\)\.fadeIn\(delay: 400\.ms\),'
    # Replace the FIRST occurrence, keep the second, or just remove one.
    scroll_view_code = re.sub(duplicate_overview_pattern, '', scroll_view_code, count=1, flags=re.DOTALL)

    # Wrap the dynamic parts in a Consumer
    dynamic_parts_pattern = r'(// Overview.*?)(?=^\s*\]\s*,\s*^\s*\)\s*,\s*^\s*\)\s*,)'
    dynamic_parts_match = re.search(r'(SizedBox\(height: 24\),\s*// Overview.*?)(?=^\s*\]\s*,\s*^\s*\)\s*,\s*^\s*\)\s*,)', scroll_view_code, flags=re.DOTALL | re.MULTILINE)
    
    if dynamic_parts_match:
        dynamic_parts = dynamic_parts_match.group(1)
        # Inside dynamic_parts, change `media.` to `fullMedia.`
        dynamic_parts = dynamic_parts.replace('media.', 'fullMedia.')
        
        consumer_wrapper = """Consumer(
                        builder: (context, ref, child) {
                          final mediaAsync = ref.watch(mediaDetailsProvider(mediaId));
                          final fullMedia = mediaAsync.value ?? baseMedia;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              """ + dynamic_parts + """
                            ],
                          ).animate().fadeIn();
                        },
                      ),"""
        scroll_view_code = scroll_view_code.replace(dynamic_parts_match.group(1), consumer_wrapper)

    # Now make sure the rest uses `baseMedia.`
    scroll_view_code = scroll_view_code.replace('media.', 'baseMedia.')

    scaffold_class = f"""
class _MediaDetailsScaffold extends StatelessWidget {{
  final Media baseMedia;
  final String mediaId;

  const _MediaDetailsScaffold({{required this.baseMedia, required this.mediaId}});

  @override
  Widget build(BuildContext context) {{
    final coverUrl = baseMedia.backdropUrl ?? baseMedia.posterUrl;
    {scroll_view_code}
  }}
}}
"""
    # Insert before _CollapsibleOverview
    content = re.sub(r'class _CollapsibleOverview', scaffold_class + '\nclass _CollapsibleOverview', content)

    # Remove the old CustomScrollView from where it was
    # Wait, the new `MediaDetailsScreen` `build` method already doesn't have the CustomScrollView.
    # It just returns `_MediaDetailsScaffold(baseMedia: media, mediaId: mediaId);` and the `_buildError` comes right after.
    # So we should delete the old CustomScrollView from `content`.
    content = re.sub(r'          final coverUrl =.*?\]\s*,\s*\);\s*\},', '', content, flags=re.DOTALL)

with open('lib/screens/media_details_screen.dart', 'w') as f:
    f.write(content)

