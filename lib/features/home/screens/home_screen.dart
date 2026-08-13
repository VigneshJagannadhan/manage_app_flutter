import 'package:flutter/material.dart';
import 'package:manage_app/core/extensions/build_context_theme_extensions.dart';
import 'package:manage_app/core/resources/app_strings.dart';
import 'package:manage_app/features/expense/screens/expense_dashboard_screen.dart';
import 'package:manage_app/features/journal/screens/journal_screen.dart';
import 'package:manage_app/features/reminders/screens/reminders_screen.dart';
import 'package:manage_app/features/shared/widgets/app_scaffold.dart';
import 'package:manage_app/features/task/screens/task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    TaskListScreen(),
    ExpenseDashboardScreen(),
    RemindersScreen(),
    JournalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return AppScaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: theme.horizontalMargin ?? 16),
        child: Material(
          elevation: theme.elevationLarge ?? 6,
          borderRadius: BorderRadius.circular(theme.appBorderRadius ?? 12),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: AppStrings.tasksTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: AppStrings.expensesTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications),
                label: AppStrings.remindersTab,
              ),
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: AppStrings.journalTab,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
