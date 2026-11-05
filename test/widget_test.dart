import 'package:chaty/core/localization/app_localizations.dart';
import 'package:chaty/core/widgets/chaty_avatar.dart';
import 'package:chaty/core/widgets/empty_state.dart';
import 'package:chaty/features/chat/domain/message_model.dart';
import 'package:chaty/features/chat/presentation/widgets/message_bubble.dart';
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

  testWidgets('ChatyAvatar displays initials and online badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ChatyAvatar(
              name: 'Mokhtar',
              isOnline: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('MO'), findsOneWidget);
  });
}
