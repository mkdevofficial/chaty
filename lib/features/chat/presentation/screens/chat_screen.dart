import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/widgets/chaty_avatar.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../profile/presentation/user_profile_screen.dart';
import '../../domain/conversation_model.dart';
import '../../domain/message_model.dart';
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
  MessageModel? _replyingToMessage;
  int? _highlightedMessageId;
  Timer? _highlightTimer;

  final GlobalKey<VoiceRecorderOverlayState> _recorderKey =
      GlobalKey<VoiceRecorderOverlayState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Track active conversation and mark as read immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeConversationIdProvider.notifier).state = widget.conversation.id;
      ref.read(chatMessagesProvider(widget.conversation.id).notifier).fetchLatest();
      ref.read(conversationsProvider.notifier).markAsRead(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    // Clear active conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeConversationIdProvider.notifier).state = null;
    });
    _highlightTimer?.cancel();
    _typingDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
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

  MessageReplyTo? _buildCurrentReplyTo() {
    if (_replyingToMessage == null) return null;
    final msg = _replyingToMessage!;
    return MessageReplyTo(
      id: msg.id,
      senderId: msg.senderId,
      type: msg.type,
      text: msg.text != null
          ? (msg.text!.length > 120 ? msg.text!.substring(0, 120) : msg.text)
          : null,
      deleted: msg.deleted,
    );
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final replyTo = _buildCurrentReplyTo();
    final replyToId = _replyingToMessage?.id;

    ref.read(chatMessagesProvider(widget.conversation.id).notifier).sendText(
          text,
          replyToId: replyToId,
          replyTo: replyTo,
        );

    _textController.clear();
    setState(() {
      _replyingToMessage = null;
    });
    _scrollToBottom();
  }

  void _sendSticker(String pack, String id) {
    final replyTo = _buildCurrentReplyTo();
    final replyToId = _replyingToMessage?.id;

    ref.read(chatMessagesProvider(widget.conversation.id).notifier).sendSticker(
          pack: pack,
          id: id,
          replyToId: replyToId,
          replyTo: replyTo,
        );

    setState(() {
      _replyingToMessage = null;
    });
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
        final replyTo = _buildCurrentReplyTo();
        final replyToId = _replyingToMessage?.id;

        setState(() {
          _replyingToMessage = null;
        });

        await ref
            .read(chatMessagesProvider(widget.conversation.id).notifier)
            .sendMedia(
              file: File(picked.path),
              type: 'image',
              replyToId: replyToId,
              replyTo: replyTo,
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
        final replyTo = _buildCurrentReplyTo();
        final replyToId = _replyingToMessage?.id;

        setState(() {
          _replyingToMessage = null;
        });

        await ref
            .read(chatMessagesProvider(widget.conversation.id).notifier)
            .sendMedia(
              file: File(picked.first.path!),
              type: 'file',
              replyToId: replyToId,
              replyTo: replyTo,
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

  Widget _buildReplyPreviewBar(ThemeData theme, ChatyStrings strings, bool isArabic, UserModel peer) {
    if (_replyingToMessage == null) return const SizedBox.shrink();
    final msg = _replyingToMessage!;
    final currentUserId = ref.read(authProvider).user?.id ?? 0;
    final isMe = msg.senderId == currentUserId;
    final senderName = isMe ? strings.you : peer.displayName;

    String snippet = '';
    IconData? icon;
    if (msg.deleted) {
      snippet = strings.thisMessageWasDeleted;
      icon = Icons.block_flipped;
    } else if (msg.isText) {
      snippet = msg.text ?? '';
    } else if (msg.isImage) {
      snippet = strings.photo;
      icon = Icons.image_rounded;
    } else if (msg.isAudio) {
      snippet = strings.voiceMessage;
      icon = Icons.mic_rounded;
    } else if (msg.isFile) {
      snippet = msg.attachment?.name ?? strings.file;
      icon = Icons.insert_drive_file_rounded;
    } else if (msg.isSticker) {
      snippet = strings.sticker;
      icon = Icons.emoji_emotions_outlined;
    }

    return Container(
      key: const Key('reply_preview_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(
          left: isArabic
              ? BorderSide.none
              : BorderSide(color: theme.colorScheme.primary, width: 4),
          right: isArabic
              ? BorderSide(color: theme.colorScheme.primary, width: 4)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('reply_preview_close_button'),
            icon: const Icon(Icons.close_rounded, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              setState(() => _replyingToMessage = null);
            },
          ),
        ],
      ),
    );
  }

  void _showMessageActions(
    MessageModel message,
    bool isOutgoing,
    ThemeData theme,
    ChatyStrings strings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: Text(strings.reply),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _replyingToMessage = message;
                  });
                },
              ),
              if (message.isText && message.text != null && !message.deleted)
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(strings.copy),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: message.text!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.copiedToClipboard)),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text(strings.delete, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteDialog(message, isOutgoing, strings);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    MessageModel message,
    bool isOutgoing,
    ChatyStrings strings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(chatMessagesProvider(widget.conversation.id).notifier)
                  .deleteMessage(message.id, 'me');
            },
            child: Text(strings.deleteForMe),
          ),
          if (isOutgoing)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx);
                ref
                    .read(chatMessagesProvider(widget.conversation.id).notifier)
                    .deleteMessage(message.id, 'everyone');
              },
              child: Text(
                strings.deleteForEveryone,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _onQuotedMessageTap(
    int targetMessageId,
    ChatyStrings strings,
    List<MessageModel> messages,
  ) async {
    bool exists = messages.any((m) => m.id == targetMessageId);
    if (!exists) {
      final found = await ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .loadOlderUntilFound(targetMessageId);
      if (!found) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.originalMessageNotFound)),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    final currentMessages =
        ref.read(chatMessagesProvider(widget.conversation.id)).messages;
    final reversedList = currentMessages.reversed.toList();
    final index = reversedList.indexWhere((m) => m.id == targetMessageId);
    if (index != -1 && _scrollController.hasClients) {
      final targetOffset =
          (index * 72.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _highlightedMessageId = targetMessageId);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _highlightedMessageId = null);
        }
      });
    }
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
                            Dismissible(
                              key: ValueKey('msg_${message.id}_${message.clientId ?? ''}'),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                setState(() {
                                  _replyingToMessage = message;
                                });
                                return false;
                              },
                              background: Container(
                                alignment: isArabic
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Icon(Icons.reply_rounded,
                                    color: theme.colorScheme.primary),
                              ),
                              secondaryBackground: Container(
                                alignment: isArabic
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Icon(Icons.reply_rounded,
                                    color: theme.colorScheme.primary),
                              ),
                              child: GestureDetector(
                                onLongPress: () => _showMessageActions(
                                  message,
                                  isOutgoing,
                                  theme,
                                  strings,
                                ),
                                child: MessageBubble(
                                  message: message,
                                  isOutgoing: isOutgoing,
                                  isArabic: isArabic,
                                  peerName: otherUser.displayName,
                                  currentUserId: currentUserId,
                                  isHighlighted:
                                      _highlightedMessageId == message.id,
                                  onQuotedMessageTap: (targetId) =>
                                      _onQuotedMessageTap(
                                    targetId,
                                    strings,
                                    messages,
                                  ),
                                  onRetry: () {
                                    ref
                                        .read(chatMessagesProvider(
                                                widget.conversation.id)
                                            .notifier)
                                        .retryFailedMessage(message);
                                  },
                                ),
                              ),
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
                      final replyTo = _buildCurrentReplyTo();
                      final replyToId = _replyingToMessage?.id;
                      setState(() {
                        _isRecording = false;
                        _replyingToMessage = null;
                      });
                      ref
                          .read(chatMessagesProvider(widget.conversation.id).notifier)
                          .sendMedia(
                            file: file,
                            type: 'audio',
                            durationMs: durationMs,
                            replyToId: replyToId,
                            replyTo: replyTo,
                          );
                      _scrollToBottom();
                    },
                    onCancel: () {
                      setState(() => _isRecording = false);
                    },
                  )
                : _buildComposer(theme, strings, otherUser),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(ThemeData theme, ChatyStrings strings, UserModel peer) {
    final hasText = _textController.text.trim().isNotEmpty;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToMessage != null)
              _buildReplyPreviewBar(theme, strings, isArabic, peer),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
