import 'package:chaty/features/stickers/sticker_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StickerManager Tests', () {
    test('contains at least 3 packs with 12+ stickers each', () {
      expect(StickerManager.packs.length, greaterThanOrEqualTo(3));

      for (final pack in StickerManager.packs) {
        expect(pack.stickers.length, greaterThanOrEqualTo(12));
        expect(pack.id.isNotEmpty, true);
        expect(pack.titleAr.isNotEmpty, true);
        expect(pack.titleEn.isNotEmpty, true);
      }
    });

    test('generates valid asset paths for all stickers', () {
      for (final pack in StickerManager.packs) {
        for (final sticker in pack.stickers) {
          expect(sticker.pack, pack.id);
          expect(sticker.assetPath, 'assets/stickers/${pack.id}/${sticker.id}.svg');
        }
      }
    });
  });
}
