import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

class FullscreenImageViewer extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? localFilePath;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    this.imageUrl,
    this.localFilePath,
    this.heroTag,
  });

  @override
  ConsumerState<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends ConsumerState<FullscreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStorage = ref.watch(authStorageProvider);

    Widget imageWidget;
    if (widget.localFilePath != null && File(widget.localFilePath!).existsSync()) {
      imageWidget = Image.file(
        File(widget.localFilePath!),
        fit: BoxFit.contain,
      );
    } else if (widget.imageUrl != null) {
      imageWidget = FutureBuilder<String?>(
        future: authStorage.getToken(),
        builder: (context, snapshot) {
          final token = snapshot.data;
          final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

          return CachedNetworkImage(
            imageUrl: widget.imageUrl!,
            httpHeaders: headers,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white70, size: 64),
            ),
          );
        },
      );
    } else {
      imageWidget = const Center(
        child: Icon(Icons.broken_image, color: Colors.white70, size: 64),
      );
    }

    if (widget.heroTag != null) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: (d) => _doubleTapDetails = d,
            onDoubleTap: _handleDoubleTap,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                child: imageWidget,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
