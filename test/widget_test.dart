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
}
