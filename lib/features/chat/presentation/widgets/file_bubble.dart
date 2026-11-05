import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/conversations_provider.dart';
import '../../domain/message_model.dart';

class FileBubble extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isOutgoing;

  const FileBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  @override
  ConsumerState<FileBubble> createState() => _FileBubbleState();
}

class _FileBubbleState extends ConsumerState<FileBubble> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _downloadedPath;

  @override
  void initState() {
    super.initState();
    _checkIfExists();
  }

  Future<void> _checkIfExists() async {
    if (widget.message.localFilePath != null &&
        File(widget.message.localFilePath!).existsSync()) {
      setState(() {
        _downloadedPath = widget.message.localFilePath;
      });
      return;
    }

    final name = widget.message.attachment?.name;
    if (name != null) {
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/$name');
      if (localFile.existsSync()) {
        setState(() {
          _downloadedPath = localFile.path;
        });
      }
    }
  }

  Future<void> _handleDownloadOrOpen() async {
    if (_downloadedPath != null && File(_downloadedPath!).existsSync()) {
      await OpenFilex.open(_downloadedPath!);
      return;
    }

    final fileId = widget.message.attachment?.fileId;
    final fileName = widget.message.attachment?.name ?? 'file_${widget.message.id}';
    if (fileId == null) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';

      final repo = ref.read(chatRepositoryProvider);
      final downloaded = await repo.downloadFile(
        fileId,
        savePath,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadedPath = downloaded.path;
        });
        await OpenFilex.open(downloaded.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String? name) {
    if (name == null) return Icons.insert_drive_file;
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
      case 'tar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = widget.message.attachment?.name ?? 'Document';
    final fileSize = _formatFileSize(widget.message.attachment?.size);

    final textColor = widget.isOutgoing
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final subTextColor = widget.isOutgoing
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
        : theme.colorScheme.onSurfaceVariant;

    final iconColor = widget.isOutgoing
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return InkWell(
      onTap: _handleDownloadOrOpen,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isOutgoing
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFileIcon(fileName),
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isDownloading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  strokeWidth: 2.5,
                  color: iconColor,
                ),
              )
            else
              Icon(
                _downloadedPath != null ? Icons.folder_open : Icons.download,
                size: 24,
                color: iconColor,
              ),
          ],
        ),
      ),
    );
  }
}
