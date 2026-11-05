import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
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
  final String peerName;
  final int currentUserId;
  final bool isHighlighted;
  final VoidCallback? onRetry;
  final void Function(int messageId)? onQuotedMessageTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.isArabic = true,
    this.peerName = 'User',
    this.currentUserId = 0,
    this.isHighlighted = false,
    this.onRetry,
    this.onQuotedMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context).strings;
    final timeStr = DateFormatter.formatMessageTime(message.createdAt, isArabic: isArabic);

    // 1. Tombstone bubble for deleted messages
    if (message.deleted) {
      return Align(
        alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
                : (isOutgoing
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_flipped,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  strings.thisMessageWasDeleted,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
              if (message.replyTo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildQuotedBlock(context, message.replyTo!, theme, strings),
                ),
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

    final bubbleBg = isHighlighted
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.85)
        : (isOutgoing
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest);

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
          border: isHighlighted
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
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
            // Quoted message block
            if (message.replyTo != null)
              _buildQuotedBlock(context, message.replyTo!, theme, strings),
            messageContent,
            const SizedBox(height: 2),
            _buildStatusRow(theme, timeStr),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedBlock(
    BuildContext context,
    MessageReplyTo replyTo,
    ThemeData theme,
    ChatyStrings strings,
  ) {
    final isMe = replyTo.senderId == currentUserId;
    final senderName = isMe ? strings.you : peerName;

    String snippet = '';
    IconData? icon;
    if (replyTo.deleted) {
      snippet = strings.thisMessageWasDeleted;
      icon = Icons.block_flipped;
    } else if (replyTo.type == 'text') {
      snippet = replyTo.text ?? '';
    } else if (replyTo.type == 'image') {
      snippet = strings.photo;
      icon = Icons.image_rounded;
    } else if (replyTo.type == 'audio') {
      snippet = strings.voiceMessage;
      icon = Icons.mic_rounded;
    } else if (replyTo.type == 'file') {
      snippet = strings.file;
      icon = Icons.insert_drive_file_rounded;
    } else if (replyTo.type == 'sticker') {
      snippet = strings.sticker;
      icon = Icons.emoji_emotions_outlined;
    }

    return InkWell(
      onTap: () => onQuotedMessageTap?.call(replyTo.id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isOutgoing
              ? Colors.black.withValues(alpha: 0.15)
              : theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: isArabic
                ? BorderSide.none
                : BorderSide(color: isOutgoing ? Colors.white70 : theme.colorScheme.primary, width: 3),
            right: isArabic
                ? BorderSide(color: isOutgoing ? Colors.white70 : theme.colorScheme.primary, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isOutgoing ? Colors.white : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 13,
                    color: isOutgoing
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: replyTo.deleted ? FontStyle.italic : FontStyle.normal,
                      color: isOutgoing
                          ? Colors.white.withValues(alpha: 0.9)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
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
