import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/core/resources/app_fonts.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/services/connectivity_service.dart';
import 'package:huddle/core/services/journal_service.dart';
import 'package:huddle/core/themes/app_theme.dart';
import 'package:huddle/features/auth/models/user_model.dart';
import 'package:huddle/features/journal/data/journal_local_data_source.dart';
import 'package:huddle/features/journal/data/journal_repository.dart';
import 'package:huddle/features/journal/models/journal_entry_model.dart';
import 'package:huddle/features/journal/providers/journal_provider.dart';
import 'package:huddle/features/journal/screens/journal_screen.dart';
import 'package:huddle/features/journal/widgets/create_today_card.dart';
import 'package:huddle/features/journal/widgets/journal_day_tile.dart';
import 'package:huddle/features/settings/providers/profile_provider.dart';
import 'package:huddle/features/settings/services/profile_service.dart';
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

/// In-memory stand-in for the Hive-backed data source, so tests never touch a real
/// platform channel/box.
class _FakeJournalLocalDataSource extends JournalLocalDataSource {
  final Map<DateTime, JournalDraft> _drafts = {};

  @override
  Future<void> saveDraft(DateTime date, String content) async {
    _drafts[date] = JournalDraft(content: content, dirty: true, updatedAt: DateTime.now());
  }

  @override
  JournalDraft? getDraft(DateTime date) => _drafts[date];

  @override
  Future<void> markSynced(DateTime date) async {
    final draft = _drafts[date];
    if (draft == null) return;
    _drafts[date] = JournalDraft(content: draft.content, dirty: false, updatedAt: draft.updatedAt);
  }

  @override
  List<DateTime> dirtyDates() => _drafts.entries.where((e) => e.value.dirty).map((e) => e.key).toList();

  @override
  Future<void> clearAll() async => _drafts.clear();
}

class _FakeConnectivityService extends ConnectivityService {
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  Future<bool> get isConnected async => true;
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
    final journalService = _FakeJournalService([JournalEntryModel(id: '1', date: yesterday, content: 'Had a good day')]);
    final journalProvider = JournalProvider(
      journalService: journalService,
      repository: JournalRepository(local: _FakeJournalLocalDataSource(), remote: journalService),
      connectivityService: _FakeConnectivityService(),
      profileProvider: profileProvider,
    )..onInit();
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

    // Past the 800ms local-save debounce - the draft should be written to local storage.
    await tester.pump(const Duration(seconds: 2));
    expect(journalProvider.statusFor(today.atMidnight), JournalSyncStatus.savedLocally);

    // Past the 5s idle-sync timeout - the draft should now have synced to the server.
    await tester.pump(const Duration(seconds: 6));
    expect(journalProvider.statusFor(today.atMidnight), JournalSyncStatus.synced);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(JournalScreen), findsOneWidget, reason: 'back navigation should return to the list without crashing');
  });
}
