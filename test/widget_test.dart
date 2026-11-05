import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:school_online_voting/app.dart';
import 'package:school_online_voting/core/services/app_repository.dart';

void main() {
  testWidgets('student can sign into the demo dashboard', (tester) async {
    final repository = AppRepository(firebaseConfigured: false);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: repository, child: const VotingApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('School Online Voting'), findsOneWidget);
    await tester.tap(find.text('GET STARTED'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '2024-1887');
    await tester.enterText(find.byType(TextFormField).at(1), 'demo1234');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOG IN'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Student Council Elections'), findsWidgets);
    repository.dispose();
  });
}
