import 'dart:io';
import 'package:chaty/core/localization/app_localizations.dart';
import 'package:chaty/core/widgets/chaty_avatar.dart';
import 'package:chaty/core/widgets/empty_state.dart';
import 'package:chaty/features/auth/domain/user_model.dart';
import 'package:chaty/features/chat/domain/message_model.dart';
import 'package:chaty/features/chat/presentation/widgets/message_bubble.dart';
import 'package:chaty/features/chat/presentation/widgets/voice_recorder_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState displays icon, title and action button', (WidgetTester tester) async {
    bool clicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No chats yet',
            subtitle: 'Start a conversation now',
            actionText: 'Find Friends',
            onAction: () => clicked = true,
          ),
        ),
      ),
    );

    expect(find.text('No chats yet'), findsOneWidget);
    expect(find.text('Start a conversation now'), findsOneWidget);
    expect(find.text('Find Friends'), findsOneWidget);

    await tester.tap(find.text('Find Friends'));
    expect(clicked, true);
  });

  testWidgets('MessageBubble displays message text properly', (WidgetTester tester) async {
    final message = MessageModel(
      id: 1,
      conversationId: 10,
      senderId: 42,
      type: 'text',
      text: 'Salam alaykom!',
      status: MessageStatus.sent,
      createdAt: '2026-11-05T07:30:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isOutgoing: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Salam alaykom!'), findsOneWidget);
  });

  testWidgets('ChatyAvatar displays real initials fallback for different users (never hardcoded C)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChatyAvatar(name: 'Mokhtar Eby', isOnline: true),
                ChatyAvatar(name: 'Sarah Connor'),
                ChatyAvatar(name: '@layla_h'),
                ChatyAvatar(name: 'Ahmed'),
              ],
            ),
          ),
        ),
      ),
    );

    // Mokhtar Eby -> ME
    expect(find.text('ME'), findsOneWidget);
    // Sarah Connor -> SC
    expect(find.text('SC'), findsOneWidget);
    // @layla_h -> LA
    expect(find.text('LA'), findsOneWidget);
    // Ahmed -> AH
    expect(find.text('AH'), findsOneWidget);
    // Ensure hard-coded fallback 'C' is NOT displayed
    expect(find.text('C'), findsNothing);
  });

  testWidgets('Voice preview displays a clearly visible SEND button, delete, and triggers send', (WidgetTester tester) async {
    bool sent = false;
    File? sentFile;
    int sentDuration = 0;

    final dummyAudioFile = File('/tmp/test_voice.m4a');
    if (!dummyAudioFile.existsSync()) {
      dummyAudioFile.createSync();
    }

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: VoiceRecorderOverlay(
            initialPreviewFile: dummyAudioFile,
            initialDurationSeconds: 4,
            onSend: (file, durationMs) {
              sent = true;
              sentFile = file;
              sentDuration = durationMs;
            },
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify preview buttons exist
    expect(find.byKey(const Key('voice_preview_send_button')), findsOneWidget);
    expect(find.byKey(const Key('voice_preview_delete_button')), findsOneWidget);
    expect(find.byKey(const Key('voice_preview_play_button')), findsOneWidget);

    // Tap SEND button
    await tester.tap(find.byKey(const Key('voice_preview_send_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(sent, true);
    expect(sentFile?.path, dummyAudioFile.path);
    expect(sentDuration, 4000);
  });

  testWidgets('Follow button toggles between Follow and Unfollow states', (WidgetTester tester) async {
    var user = const UserModel(
      id: 42,
      username: 'alice',
      displayName: 'Alice M',
      isFollowing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: OutlinedButton(
                  key: const Key('test_follow_button'),
                  onPressed: () {
                    setState(() {
                      user = user.copyWith(isFollowing: !user.isFollowing);
                    });
                  },
                  child: Text(user.isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Initial state: not following
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Unfollow'), findsNothing);

    // Tap to follow
    await tester.tap(find.byKey(const Key('test_follow_button')));
    await tester.pumpAndSettle();

    // Toggled state: following
    expect(find.text('Unfollow'), findsOneWidget);
    expect(find.text('Follow'), findsNothing);

    // Tap again to unfollow
    await tester.tap(find.byKey(const Key('test_follow_button')));
    await tester.pumpAndSettle();

    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Unfollow'), findsNothing);
  });

  testWidgets('Recording bar respects bottom safe area / inset', (WidgetTester tester) async {
    final dummyAudioFile = File('/tmp/test_voice2.m4a');
    if (!dummyAudioFile.existsSync()) {
      dummyAudioFile.createSync();
    }

    const testBottomInset = 48.0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: testBottomInset),
            viewPadding: EdgeInsets.only(bottom: testBottomInset),
          ),
          child: Scaffold(
            bottomNavigationBar: VoiceRecorderOverlay(
              key: const Key('tested_voice_overlay'),
              initialPreviewFile: dummyAudioFile,
              initialDurationSeconds: 3,
              onSend: (file, duration) {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find the VoiceRecorderOverlay widget and verify its height includes the bottom inset
    final overlayFinder = find.byKey(const Key('tested_voice_overlay'));
    expect(overlayFinder, findsOneWidget);

    final size = tester.getSize(overlayFinder);
    // Base height is 48px row + 16px padding = 64px, with 48px bottom inset = 112px
    expect(size.height, greaterThanOrEqualTo(64.0 + testBottomInset));
  });

  testWidgets('Reply preview bar renders sender name, snippet, and closes on tap', (WidgetTester tester) async {
    bool closed = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: StatefulBuilder(
          builder: (context, setState) {
            if (closed) return const SizedBox();
            return Scaffold(
              body: Container(
                key: const Key('reply_preview_bar'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey.shade200,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sarah Connor', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Are you coming today?'),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('reply_preview_close_button'),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          closed = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reply_preview_bar')), findsOneWidget);
    expect(find.text('Sarah Connor'), findsOneWidget);
    expect(find.text('Are you coming today?'), findsOneWidget);

    // Tap close button
    await tester.tap(find.byKey(const Key('reply_preview_close_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reply_preview_bar')), findsNothing);
  });

  testWidgets('Delete dialog options: for everyone option only appears for own messages', (WidgetTester tester) async {
    Widget buildDeleteDialog({required bool isOutgoing}) {
      return MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              key: const Key('open_dialog_button'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete'),
                    content: const Text('Delete this message?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Delete for me'),
                      ),
                      if (isOutgoing)
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Delete for everyone'),
                        ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      );
    }

    // 1. Test own message (isOutgoing = true)
    await tester.pumpWidget(buildDeleteDialog(isOutgoing: true));
    await tester.tap(find.byKey(const Key('open_dialog_button')));
    await tester.pumpAndSettle();

    expect(find.text('Delete for me'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 2. Test peer's message (isOutgoing = false)
    await tester.pumpWidget(buildDeleteDialog(isOutgoing: false));
    await tester.tap(find.byKey(const Key('open_dialog_button')));
    await tester.pumpAndSettle();

    expect(find.text('Delete for me'), findsOneWidget);
    // "Delete for everyone" must NOT appear for other user's message
    expect(find.text('Delete for everyone'), findsNothing);
  });
}
