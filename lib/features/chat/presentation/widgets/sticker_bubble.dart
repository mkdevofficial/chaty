import 'package:flutter/material.dart';
import '../../../stickers/sticker_manager.dart';
import '../../domain/message_model.dart';

class StickerBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOutgoing;

  const StickerBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    final pack = message.sticker?.pack ?? 'emojis';
    final id = message.sticker?.id ?? 'happy';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: StickerManager.buildStickerWidget(
        pack,
        id,
        size: 130,
      ),
    );
  }
}
