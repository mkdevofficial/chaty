import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/widgets/chaty_avatar.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../profile/presentation/user_profile_screen.dart';
import '../../domain/conversation_model.dart';
import '../providers/chat_messages_provider.dart';
import '../providers/conversations_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../widgets/voice_recorder_overlay.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isRecording = false;
  bool _showJumpToBottom = false;
  Timer? _typingDebounce;
  final GlobalKey<VoiceRecorderOverlayState> _recorderKey =
      GlobalKey<VoiceRecorderOverlayState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // If scrolled near top -> load older messages
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .loadOlderMessages();
    }

    // Jump to bottom visibility
    if (_scrollController.position.pixels > 300) {
      if (!_showJumpToBottom) setState(() => _showJumpToBottom = true);
    } else {
      if (_showJumpToBottom) setState(() => _showJumpToBottom = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTextChanged(String val) {
    setState(() {});
    final notifier =
        ref.read(chatMessagesProvider(widget.conversation.id).notifier);

    _typingDebounce?.cancel();
    notifier.sendTyping(true);

    _typingDebounce = Timer(const Duration(seconds: 3), () {
      notifier.sendTyping(false);
    });
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatMessagesProvider(widget.conversation.id).notifier)
        .sendText(text);

    _textController.clear();
    setState(() {});
    _scrollToBottom();
  }

  void _sendSticker(String pack, String id) {
    ref
        .read(chatMessagesProvider(widget.conversation.id).notifier)
        .sendSticker(pack: pack, id: id);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final granted = await PermissionUtils.requestCameraPermission(context);
      if (!granted) return;
    } else {
      final granted = await PermissionUtils.requestPhotosPermission(context);
      if (!granted) return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        await ref
            .read(chatMessagesProvider(widget.conversation.id).notifier)
            .sendMedia(
              file: File(picked.path),
              type: 'image',
            );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final picked = await FilePicker.pickFiles();
      if (picked.isNotEmpty && picked.first.path != null) {
        await ref
            .read(chatMessagesProvider(widget.conversation.id).notifier)
            .sendMedia(
              file: File(picked.first.path!),
              type: 'file',
            );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send file: $e')),
        );
      }
    }
  }

  void _showAttachMenu() {
    final strings = AppLocalizations.of(context).strings;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttachOption(
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFFE91E63),
                label: strings.camera,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              _buildAttachOption(
                icon: Icons.photo_library_rounded,
                color: const Color(0xFF9C27B0),
                label: strings.gallery,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              _buildAttachOption(
                icon: Icons.insert_drive_file_rounded,
                color: const Color(0xFF2196F3),
                label: strings.document,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StickerPickerSheet(
        onStickerSelected: (pack, id) {
          Navigator.pop(context);
          _sendSticker(pack, id);
        },
      ),
    );
  }

  Decoration? _getWallpaperDecoration(String wallpaper, ThemeData theme) {
    if (wallpaper == 'warm') {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }
    return null;
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currentUserId = ref.watch(authProvider).user?.id ?? 0;
    final wallpaper = ref.watch(themeProvider).wallpaper;

    final chatState = ref.watch(chatMessagesProvider(widget.conversation.id));
    final convState = ref.watch(conversationsProvider);
    final activeConv = convState.conversations
        .where((c) => c.id == widget.conversation.id)
        .firstOrNull ?? widget.conversation;
    final otherUser = activeConv.peer;

    // Messages in reversed order for standard messaging ListView
    final messages = chatState.messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(user: otherUser),
              ),
            );
          },
          child: Row(
            children: [
              ChatyAvatar(
                name: otherUser.displayName,
                avatarFileId: otherUser.avatarFileId,
                isOnline: otherUser.online,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      chatState.isOtherUserTyping
                          ? strings.typing
                          : (otherUser.online
                              ? strings.online
                              : DateFormatter.formatLastSeen(
                                  otherUser.lastSeen,
                                  isArabic: isArabic,
                                )),
                      style: TextStyle(
                        fontSize: 12,
                        color: chatState.isOtherUserTyping
                            ? theme.colorScheme.primary
                            : (otherUser.online
                                ? const Color(0xFF00D856)
                                : theme.colorScheme.onSurfaceVariant),
                        fontWeight: chatState.isOtherUserTyping || otherUser.online
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: _getWallpaperDecoration(wallpaper, theme),
        child: Column(
          children: [
            // Messages List with Infinite Scroll Upward
            Expanded(
              child: chatState.isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length +
                          (chatState.isLoadingOlder ? 1 : 0) +
                          (chatState.isOtherUserTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Typing bubble at bottom (index 0 when reversed)
                        if (chatState.isOtherUserTyping && index == 0) {
                          return _buildTypingBubble(theme, strings);
                        }

                        final actualIndex =
                            chatState.isOtherUserTyping ? index - 1 : index;

                        if (chatState.isLoadingOlder &&
                            actualIndex == messages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }

                        final message = messages[actualIndex];
                        final isOutgoing = message.senderId == currentUserId;

                        // Day Separator logic
                        Widget? daySeparator;
                        if (actualIndex < messages.length - 1) {
                          final prevMessage = messages[actualIndex + 1];
                          final msgDate = DateTime.parse(message.createdAt).toLocal();
                          final prevDate =
                              DateTime.parse(prevMessage.createdAt).toLocal();

                          if (msgDate.day != prevDate.day ||
                              msgDate.month != prevDate.month ||
                              msgDate.year != prevDate.year) {
                            daySeparator = _buildDaySeparator(
                              DateFormatter.formatDaySeparator(
                                message.createdAt,
                                isArabic: isArabic,
                              ),
                              theme,
                            );
                          }
                        } else {
                          // First message at very top
                          daySeparator = _buildDaySeparator(
                            DateFormatter.formatDaySeparator(
                              message.createdAt,
                              isArabic: isArabic,
                            ),
                            theme,
                          );
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ?daySeparator,
                            MessageBubble(
                              message: message,
                              isOutgoing: isOutgoing,
                              isArabic: isArabic,
                              onRetry: () {
                                ref
                                    .read(chatMessagesProvider(
                                            widget.conversation.id)
                                        .notifier)
                                    .retryFailedMessage(message);
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Jump to bottom FAB
            if (_showJumpToBottom)
              Align(
                alignment: isArabic ? Alignment.bottomLeft : Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FloatingActionButton.small(
                    onPressed: _scrollToBottom,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
              ),

            // Composer Area
            _isRecording
                ? VoiceRecorderOverlay(
                    key: _recorderKey,
                    onSend: (file, durationMs) {
                      setState(() => _isRecording = false);
                      ref
                          .read(chatMessagesProvider(widget.conversation.id).notifier)
                          .sendMedia(
                            file: file,
                            type: 'audio',
                            durationMs: durationMs,
                          );
                      _scrollToBottom();
                    },
                    onCancel: () {
                      setState(() => _isRecording = false);
                    },
                  )
                : _buildComposer(theme, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(ThemeData theme, dynamic strings) {
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach Menu Button
            IconButton(
              icon: const Icon(Icons.attach_file_rounded),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: _showAttachMenu,
            ),

            // Stickers Picker Button
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: _showStickerPicker,
            ),

            // Text Input Field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    hintText: strings.typeMessage,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send Button OR Hold-to-Record Microphone
            hasText
                ? CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 20),
                      color: theme.colorScheme.onPrimary,
                      onPressed: _sendText,
                    ),
                  )
                : GestureDetector(
                    onTap: () async {
                      final granted =
                          await PermissionUtils.requestMicrophonePermission(context);
                      if (granted) {
                        setState(() => _isRecording = true);
                      }
                    },
                    onLongPressStart: (_) async {
                      final granted =
                          await PermissionUtils.requestMicrophonePermission(context);
                      if (granted) {
                        setState(() => _isRecording = true);
                      }
                    },
                    onLongPressEnd: (_) {
                      _recorderKey.currentState?.stopRecording();
                    },
                    onLongPressMoveUpdate: (details) {
                      _recorderKey.currentState?.onDragUpdate(details);
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.mic_rounded,
                        size: 22,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble(ThemeData theme, dynamic strings) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              strings.typing,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySeparator(String text, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
