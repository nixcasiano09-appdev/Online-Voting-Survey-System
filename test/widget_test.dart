import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:school_online_voting/app.dart';
import 'package:school_online_voting/core/services/app_repository.dart';

void main() {
  testWidgets('login role selection does not grant admin access', (
    tester,
  ) async {
    final repository = AppRepository(firebaseConfigured: false);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: repository, child: const VotingApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('School Online Voting'), findsOneWidget);
    await tester.tap(find.text('GET STARTED'));
    await tester.pumpAndSettle();

    expect(
      find.text('Welcome to School Online Voting and Survey System'),
      findsOneWidget,
    );
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);

    await tester.tap(find.text('Admin'));
    await tester.enterText(find.byType(TextFormField).at(0), '2024-1887');
    await tester.enterText(find.byType(TextFormField).at(1), 'demo1234');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'LOG IN'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOG IN'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Selected role does not match'), findsOneWidget);
    expect(find.text('Welcome back,'), findsNothing);

    await tester.tap(find.text('Student'));
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'LOG IN'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOG IN'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Student Council Elections'), findsWidgets);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Welcome to School Online Voting and Survey System'),
      findsOneWidget,
    );
    repository.dispose();
  });
}
