import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../stickers/sticker_manager.dart';

class StickerPickerSheet extends ConsumerStatefulWidget {
  final void Function(String pack, String id) onStickerSelected;

  const StickerPickerSheet({
    super.key,
    required this.onStickerSelected,
  });

  @override
  ConsumerState<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends ConsumerState<StickerPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 4 tabs: Recent + 3 Packs
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _selectSticker(String pack, String id) {
    final prefs = ref.read(preferencesStorageProvider);
    prefs.addRecentSticker(pack, id);
    widget.onStickerSelected(pack, id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context).strings;
    final prefs = ref.watch(preferencesStorageProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final recentList = StickerManager.getRecentStickers(prefs);

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.access_time_rounded, size: 20),
                text: strings.recent,
              ),
              ...StickerManager.packs.map(
                (pack) => Tab(
                  icon: SizedBox(
                    width: 22,
                    height: 22,
                    child: StickerManager.buildStickerWidget(
                      pack.id,
                      pack.iconStickerId,
                      size: 22,
                    ),
                  ),
                  text: pack.title(isArabic),
                ),
              ),
            ],
          ),

          const Divider(height: 1),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Recent Tab
                recentList.isEmpty
                    ? Center(
                        child: Text(
                          strings.noRecentStickers,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: recentList.length,
                        itemBuilder: (context, index) {
                          final item = recentList[index];
                          return InkWell(
                            onTap: () => _selectSticker(item.pack, item.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: StickerManager.buildStickerWidget(
                                item.pack,
                                item.id,
                              ),
                            ),
                          );
                        },
                      ),

                // 2. Pack 1 (Emojis)
                _buildPackGrid(StickerManager.packs[0]),

                // 3. Pack 2 (Cats)
                _buildPackGrid(StickerManager.packs[1]),

                // 4. Pack 3 (Gestures)
                _buildPackGrid(StickerManager.packs[2]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackGrid(StickerPack pack) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: pack.stickers.length,
      itemBuilder: (context, index) {
        final sticker = pack.stickers[index];
        return InkWell(
          onTap: () => _selectSticker(sticker.pack, sticker.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: StickerManager.buildStickerWidget(
              sticker.pack,
              sticker.id,
            ),
          ),
        );
      },
    );
  }
}
