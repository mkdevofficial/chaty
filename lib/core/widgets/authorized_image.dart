import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../providers/core_providers.dart';

class AuthorizedImage extends ConsumerStatefulWidget {
  final int fileId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const AuthorizedImage({
    super.key,
    required this.fileId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  ConsumerState<AuthorizedImage> createState() => _AuthorizedImageState();
}

class _AuthorizedImageState extends ConsumerState<AuthorizedImage> {
  int _retryKey = 0;

  void _retry() {
    setState(() {
      _retryKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authStorage = ref.watch(authStorageProvider);
    final theme = Theme.of(context);
    final url = AppConfig.getFileUrl(widget.fileId);

    return FutureBuilder<String?>(
      key: ValueKey('auth_image_${widget.fileId}_$_retryKey'),
      future: authStorage.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder(theme);
        }

        final token = snapshot.data;
        if (token == null || token.isEmpty) {
          return _buildErrorWidget(theme, 'Authentication required');
        }

        final headers = {'Authorization': 'Bearer $token'};

        Widget imageWidget = CachedNetworkImage(
          key: ValueKey('cni_${widget.fileId}_$_retryKey'),
          imageUrl: url,
          httpHeaders: headers,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: (context, url) => _buildPlaceholder(theme),
          errorWidget: (context, url, error) => _buildErrorWidget(theme, 'Failed to load image'),
        );

        if (widget.borderRadius != null) {
          imageWidget = ClipRRect(
            borderRadius: widget.borderRadius!,
            child: imageWidget,
          );
        }

        return imageWidget;
      },
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message) {
    if (widget.errorWidget != null) return widget.errorWidget!;

    return InkWell(
      onTap: _retry,
      borderRadius: widget.borderRadius,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
