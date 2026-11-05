import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/storage/preferences_storage.dart';

class StickerItem {
  final String pack;
  final String id;
  final String assetPath;

  const StickerItem({
    required this.pack,
    required this.id,
    required this.assetPath,
  });
}

class StickerPack {
  final String id;
  final String titleAr;
  final String titleEn;
  final String iconStickerId;
  final List<StickerItem> stickers;

  const StickerPack({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.iconStickerId,
    required this.stickers,
  });

  String title(bool isArabic) => isArabic ? titleAr : titleEn;
}

class StickerManager {
  static const List<String> emojiIds = [
    'happy',
    'laugh',
    'love',
    'cool',
    'wink',
    'crying',
    'fire',
    'party',
    'star',
    'shock',
    'clap',
    'heart',
  ];

  static const List<String> catIds = [
    'cat_happy',
    'cat_sleepy',
    'cat_love',
    'cat_play',
    'cat_grumpy',
    'cat_paws',
    'cat_box',
    'cat_ninja',
    'cat_hug',
    'cat_curious',
    'cat_dance',
    'cat_yarn',
  ];

  static const List<String> gestureIds = [
    'thumbs_up',
    'peace',
    'fist_bump',
    'wave',
    'high_five',
    'ok_sign',
    'rock_on',
    'folded_hands',
    'pointing',
    'muscle',
    'handshake',
    'salute',
  ];

  static final List<StickerPack> packs = [
    StickerPack(
      id: 'emojis',
      titleAr: 'رموز تعبيرية',
      titleEn: 'Emojis',
      iconStickerId: 'happy',
      stickers: emojiIds
          .map(
            (id) => StickerItem(
              pack: 'emojis',
              id: id,
              assetPath: 'assets/stickers/emojis/$id.svg',
            ),
          )
          .toList(),
    ),
    StickerPack(
      id: 'cats',
      titleAr: 'قطط ظريفة',
      titleEn: 'Cats',
      iconStickerId: 'cat_happy',
      stickers: catIds
          .map(
            (id) => StickerItem(
              pack: 'cats',
              id: id,
              assetPath: 'assets/stickers/cats/$id.svg',
            ),
          )
          .toList(),
    ),
    StickerPack(
      id: 'gestures',
      titleAr: 'إيماءات اليد',
      titleEn: 'Gestures',
      iconStickerId: 'thumbs_up',
      stickers: gestureIds
          .map(
            (id) => StickerItem(
              pack: 'gestures',
              id: id,
              assetPath: 'assets/stickers/gestures/$id.svg',
            ),
          )
          .toList(),
    ),
  ];

  static String getAssetPath(String pack, String id) {
    return 'assets/stickers/$pack/$id.svg';
  }

  static Widget buildStickerWidget(
    String pack,
    String id, {
    double size = 120,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      getAssetPath(pack, id),
      width: size,
      height: size,
      fit: fit,
      placeholderBuilder: (context) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  static List<StickerItem> getRecentStickers(PreferencesStorage prefs) {
    final recentData = prefs.getRecentStickers();
    final List<StickerItem> result = [];
    for (final item in recentData) {
      final pack = item['pack'] ?? '';
      final id = item['id'] ?? '';
      if (pack.isNotEmpty && id.isNotEmpty) {
        result.add(
          StickerItem(
            pack: pack,
            id: id,
            assetPath: getAssetPath(pack, id),
          ),
        );
      }
    }
    return result;
  }
}
