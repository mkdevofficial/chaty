import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/message_model.dart';
import 'audio_bubble.dart';
import 'file_bubble.dart';
import 'image_bubble.dart';
import 'sticker_bubble.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOutgoing;
  final bool isArabic;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.isArabic = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormatter.formatMessageTime(message.createdAt, isArabic: isArabic);

    Widget messageContent;

    if (message.isText) {
      messageContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          message.text ?? '',
          style: TextStyle(
            fontSize: 15.5,
            color: isOutgoing
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      );
    } else if (message.isImage) {
      messageContent = ImageBubble(message: message, isOutgoing: isOutgoing);
    } else if (message.isAudio) {
      messageContent = AudioBubble(message: message, isOutgoing: isOutgoing);
    } else if (message.isFile) {
      messageContent = FileBubble(message: message, isOutgoing: isOutgoing);
    } else if (message.isSticker) {
      messageContent = StickerBubble(message: message, isOutgoing: isOutgoing);
    } else {
      messageContent = Text(message.text ?? '');
    }

    // Stickers are rendered with high-contrast translucent pill for timestamp
    if (message.isSticker) {
      return Align(
        alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            crossAxisAlignment:
                isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              messageContent,
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isOutgoing) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(theme, overrideColor: Colors.white70),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bubbleBg = isOutgoing
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
      bottomRight: Radius.circular(isOutgoing ? 4 : 18),
    );

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: message.isImage
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: bubbleRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            messageContent,
            const SizedBox(height: 2),
            _buildStatusRow(theme, timeStr),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(ThemeData theme, String timeStr) {
    final statusColor = isOutgoing
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.75)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 10.5,
            color: statusColor,
          ),
        ),
        if (isOutgoing) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(theme),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(ThemeData theme, {Color? overrideColor}) {
    final defaultColor = overrideColor ?? theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    switch (message.status) {
      case MessageStatus.pending:
        return Icon(
          Icons.access_time_rounded,
          size: 13,
          color: defaultColor,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: defaultColor,
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: overrideColor ?? theme.colorScheme.onPrimary.withValues(alpha: 0.8),
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF64B5F6),
        );
      case MessageStatus.failed:
        return InkWell(
          onTap: onRetry,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
            ],
          ),
        );
    }
  }
}
