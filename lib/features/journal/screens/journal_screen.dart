import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/date_time_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/core/services/navigation_service.dart';
import 'package:manage_app/features/journal/models/journal_entry_model.dart';
import 'package:manage_app/features/journal/providers/journal_provider.dart';
import 'package:manage_app/features/journal/screens/journal_entry_screen.dart';
import 'package:manage_app/features/journal/widgets/create_today_card.dart';
import 'package:manage_app/features/journal/widgets/journal_day_tile.dart';
import 'package:manage_app/features/shared/widgets/app_button.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/shared/widgets/screen_appbar.dart';
import 'package:manage_app/features/shared/widgets/settings_avatar_button.dart';
import 'package:manage_app/features/shared/widgets/text/body_text.dart';
import 'package:provider/provider.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _loadMoreThreshold = 200.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - _loadMoreThreshold) return;
    context.read<JournalProvider>().loadMore();
  }

  Future<void> _openEntry(DateTime date, JournalEntryModel? entry) {
    return navigationService.push(context, JournalEntryScreen(date: date, entry: entry));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: ScreenAppBar(
        title: AppStrings.journalTab,
        showBackButton: false,
        actions: const [SettingsAvatarButton()],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final provider = context.watch<JournalProvider>();

    if (provider.isLoading && provider.days.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (provider.errorMessage != null && provider.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BodyText.medium(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton.secondary(label: AppStrings.retry, onPressed: provider.loadInitial),
            ],
          ),
        ),
      );
    }

    final days = provider.days;
    return RefreshIndicator(
      onRefresh: provider.loadInitial,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: days.length + 1,
        itemBuilder: (context, index) {
          if (index == days.length) {
            return _JournalListFooter(hasMore: provider.hasMore, isLoadingMore: provider.isLoadingMore);
          }
          final slot = days[index];
          final isEmptyToday = slot.date.isToday && slot.entry == null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: isEmptyToday
                ? CreateTodayCard(onTap: () => _openEntry(slot.date, null))
                : JournalDayTile(slot: slot, onTap: () => _openEntry(slot.date, slot.entry)),
          );
        },
      ),
    );
  }
}

class _JournalListFooter extends StatelessWidget {
  const _JournalListFooter({required this.hasMore, required this.isLoadingMore});

  final bool hasMore;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator.adaptive()));
    }
    if (!hasMore) {
      final colorScheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: BodyText.small(AppStrings.beginningOfJournal, color: colorScheme.outline)),
      );
    }
    return const SizedBox.shrink();
  }
}
