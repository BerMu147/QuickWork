// Widget tests for the per-job conversation screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickwork_desktop/core/api/api_client.dart';
import 'package:quickwork_desktop/features/auth/data/auth_repository.dart';
import 'package:quickwork_desktop/features/auth/models/login_response.dart';
import 'package:quickwork_desktop/features/auth/models/user_model.dart';
import 'package:quickwork_desktop/features/auth/providers/auth_provider.dart';
import 'package:quickwork_desktop/features/jobs/data/message_repository.dart';
import 'package:quickwork_desktop/features/jobs/models/message_model.dart';
import 'package:quickwork_desktop/features/jobs/providers/message_provider.dart';
import 'package:quickwork_desktop/features/jobs/screens/conversation_screen.dart';

class _FakeAuthRepo extends AuthRepository {
  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final user = UserModel(
      id: 5,
      firstName: 'Berin',
      lastName: 'M',
      email: 'berin@test.com',
      username: 'berinm',
      genderId: 1,
      genderName: 'Male',
      cityId: 1,
      cityName: 'Sarajevo',
      phoneNumber: '061000000',
      roles: const [],
    );
    return LoginResponse(token: 'fake.token', user: user);
  }
}

class _FakeMsgRepo extends MessageRepository {
  _FakeMsgRepo(this._initial);

  final List<MessageModel> _initial;
  final List<String> _sent = [];

  List<String> get sent => _sent;

  @override
  Future<List<MessageModel>> fetchThread({
    required int jobPostingId,
    required int senderUserId,
    required int receiverUserId,
  }) async {
    return _initial;
  }

  @override
  Future<MessageModel> sendMessage({
    required int jobPostingId,
    required int senderUserId,
    required int receiverUserId,
    required String content,
  }) async {
    _sent.add(content);
    return MessageModel(
      id: 100,
      jobPostingId: jobPostingId,
      jobPostingTitle: 'Fix the roof',
      senderUserId: senderUserId,
      senderUserName: 'Me',
      receiverUserId: receiverUserId,
      receiverUserName: 'Owner',
      content: content,
      sentAt: DateTime.now(),
      isRead: true,
    );
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.init();
  });

  Future<void> pumpConversation(WidgetTester tester, _FakeMsgRepo repo) async {
    final auth = AuthProvider(repository: _FakeAuthRepo());
    await auth.login(username: 'berinm', password: 'test');
    final msg = MessageProvider(repository: repo);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<MessageProvider>.value(value: msg),
      ],
      child: const MaterialApp(
        home: ConversationScreen(
          jobPostingId: 1,
          jobTitle: 'Fix the roof',
          otherUserId: 7,
          otherUserName: 'Owner',
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('Conversation shows the thread and can send a message',
      (tester) async {
    final repo = _FakeMsgRepo([
      MessageModel.fromJson(const {
        'id': 1,
        'jobPostingId': 1,
        'jobPostingTitle': 'Fix the roof',
        'senderUserId': 7,
        'senderUserName': 'Owner',
        'receiverUserId': 5,
        'receiverUserName': 'Berin M',
        'content': 'Hi, are you available Friday?',
        'sentAt': '2024-01-01T10:00:00Z',
        'isRead': false,
      }),
    ]);
    await pumpConversation(tester, repo);

    // Incoming message from the other party is displayed.
    expect(find.text('Hi, are you available Friday?'), findsOneWidget);

    // Type and send a reply.
    await tester.enterText(find.byType(TextField), 'Yes I am!');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(repo.sent, contains('Yes I am!'));
    expect(find.text('Yes I am!'), findsOneWidget);
  });
}
