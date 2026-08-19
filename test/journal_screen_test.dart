import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_app/core/resources/app_fonts.dart';
import 'package:manage_app/core/services/journal_service.dart';
import 'package:manage_app/core/themes/app_theme.dart';
import 'package:manage_app/features/auth/models/user_model.dart';
import 'package:manage_app/features/journal/models/journal_entry_model.dart';
import 'package:manage_app/features/journal/providers/journal_provider.dart';
import 'package:manage_app/features/journal/screens/journal_screen.dart';
import 'package:manage_app/features/journal/widgets/create_today_card.dart';
import 'package:manage_app/features/journal/widgets/journal_day_tile.dart';
import 'package:manage_app/features/settings/providers/profile_provider.dart';
import 'package:manage_app/features/settings/services/profile_service.dart';
import 'package:provider/provider.dart';

class _FakeJournalService extends JournalService {
  final List<JournalEntryModel> entries;
  _FakeJournalService(this.entries);

  @override
  Future<List<JournalEntryModel>> listEntries({required DateTime from, required DateTime to}) async {
    return entries.where((e) => !e.date.isBefore(from) && !e.date.isAfter(to)).toList();
  }

  @override
  Future<JournalEntryModel> upsertEntry({required DateTime date, required String content}) async {
    return JournalEntryModel(id: 'x', date: date, content: content);
  }
}

class _FakeProfileService extends ProfileService {
  final DateTime createdAt;
  _FakeProfileService(this.createdAt);

  @override
  Future<UserModel> getProfile() async {
    return UserModel(id: 'u1', name: 'Test User', email: 't@example.com', createdAt: createdAt);
  }
}

Widget _wrap(Widget child, {required JournalProvider journalProvider}) {
  return MultiProvider(
    providers: [ChangeNotifierProvider.value(value: journalProvider)],
    child: MaterialApp(theme: AppThemes.lightTheme(font: AppFontOption.defaultOption), home: child),
  );
}

void main() {
  testWidgets('journal list shows create-today card when today has no entry, and past entries/missing days', (tester) async {
    final today = DateTime.now();
    final threeDaysAgo = DateTime(today.year, today.month, today.day - 3);
    final profileProvider = ProfileProvider(profileService: _FakeProfileService(threeDaysAgo));
    await profileProvider.loadProfile();

    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final journalProvider = JournalProvider(
      journalService: _FakeJournalService([JournalEntryModel(id: '1', date: yesterday, content: 'Had a good day')]),
      profileProvider: profileProvider,
    );
    await journalProvider.loadInitial();

    await tester.pumpWidget(_wrap(const JournalScreen(), journalProvider: journalProvider));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CreateTodayCard), findsOneWidget, reason: 'today has no entry yet');
    expect(find.text('Had a good day'), findsOneWidget, reason: "yesterday's entry preview should render");
    expect(find.byType(JournalDayTile), findsWidgets, reason: 'missing days (e.g. 2 and 3 days ago) should render as tiles too');

    await tester.tap(find.byType(CreateTodayCard));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget, reason: 'entry editor should show one fully editable textfield');

    await tester.enterText(textField, "What a day! It's going great.");
    await tester.pump();
    expect(find.text("What a day! It's going great."), findsOneWidget);

    // Simulate the debounced autosave firing before back-navigation, then go back.
    await tester.pump(const Duration(seconds: 2));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(JournalScreen), findsOneWidget, reason: 'back navigation should return to the list without crashing');
  });
}
