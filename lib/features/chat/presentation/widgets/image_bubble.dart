import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/authorized_image.dart';
import '../../domain/message_model.dart';
import 'fullscreen_image_viewer.dart';

class ImageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOutgoing;

  const ImageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileId = message.attachment?.fileId;
    final localPath = message.localFilePath;

    final heroTag = 'image_${message.id}_${message.clientId ?? ''}';

    Widget imageContent;

    if (localPath != null && File(localPath).existsSync()) {
      imageContent = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        width: 240,
        height: 240,
      );
    } else if (fileId != null) {
      imageContent = AuthorizedImage(
        fileId: fileId,
        width: 240,
        height: 240,
        fit: BoxFit.cover,
      );
    } else {
      imageContent = Container(
        width: 240,
        height: 240,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported, size: 48),
      );
    }

    return Column(
      crossAxisAlignment:
          isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FullscreenImageViewer(
                  imageUrl: fileId != null ? AppConfig.getFileUrl(fileId) : null,
                  localFilePath: localPath,
                  heroTag: heroTag,
                ),
              ),
            );
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imageContent,
            ),
          ),
        ),
        if (message.text != null && message.text!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
            child: Text(
              message.text!,
              style: TextStyle(
                color: isOutgoing
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
      ],
    );
  }
}
