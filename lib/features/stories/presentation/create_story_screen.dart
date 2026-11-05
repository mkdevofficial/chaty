import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/permissions.dart';
import 'stories_provider.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isPublishing = false;

  final List<String> _bgColors = [
    '#1E88E5', // Blue
    '#00897B', // Teal
    '#6A1B9A', // Deep Purple
    '#D81B60', // Pink
    '#E65100', // Orange
    '#2E7D32', // Dark Green
    '#263238', // Dark Charcoal
  ];
  late String _selectedBgColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedBgColor = _bgColors[0];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (_) {}
  }

  Future<void> _publishStory() async {
    if (_isPublishing) return;
    setState(() {
      _isPublishing = true;
    });

    final notifier = ref.read(storiesProvider.notifier);
    bool success = false;

    if (_tabController.index == 0) {
      // Photo story
      if (_selectedImage != null) {
        success = await notifier.createImageStory(
          imageFile: _selectedImage!,
          caption: _captionController.text.trim(),
        );
      }
    } else {
      // Text story
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        success = await notifier.createTextStory(
          text: text,
          bgColor: _selectedBgColor,
        );
      }
    }

    if (mounted) {
      setState(() {
        _isPublishing = false;
      });
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish story')),
        );
      }
    }
  }

  Color _parseHex(String hexString) {
    final hex = hexString.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.createStory),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(icon: const Icon(Icons.image), text: strings.photoStory),
            Tab(icon: const Icon(Icons.text_fields), text: strings.textStory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Photo Story Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: IconButton.filled(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt),
                                    label: Text(strings.camera),
                                  ),
                                  const SizedBox(width: 14),
                                  FilledButton.tonalIcon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library),
                                    label: Text(strings.gallery),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                if (_selectedImage != null)
                  TextField(
                    controller: _captionController,
                    decoration: InputDecoration(
                      hintText: strings.storyCaptionPlaceholder,
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedImage != null && !_isPublishing
                        ? _publishStory
                        : null,
                    child: _isPublishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(strings.shareStory),
                  ),
                ),
              ],
            ),
          ),

          // 2. Text Story Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _parseHex(_selectedBgColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: strings.storyTextPlaceholder,
                        hintStyle: const TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Background Color Selector
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _bgColors.length,
                    itemBuilder: (context, index) {
                      final hex = _bgColors[index];
                      final isSelected = hex == _selectedBgColor;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBgColor = hex;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: _parseHex(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !_isPublishing ? _publishStory : null,
                    child: _isPublishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(strings.shareStory),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
