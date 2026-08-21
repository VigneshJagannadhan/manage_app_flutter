# Testing Roadmap for manage_app

## Context

Goal: learn how to write and use unit, widget, and integration tests in this
Flutter app, starting small and eventually reaching high coverage. Right now
testing is barely started: 2 widget test files
([task_filter_sheet_test.dart](../test/task_filter_sheet_test.dart),
[journal_screen_test.dart](../test/journal_screen_test.dart)), zero unit
tests, no `test/helpers`, and no mocking library. Good news: the app's
layering (services in `lib/core/services/` -> providers in
`lib/features/*/providers/` -> widgets) is clean and constructor-injected, so
it's genuinely testable - the muscle just hasn't been built yet. CI already
runs `flutter test` on every PR, so anything added is enforced immediately,
which is a good forcing function while learning.

Decision made: adopt **mocktail** as the mocking library (no `build_runner`
code-gen needed, current standard for Provider-based apps).

## Why this order (unit -> widget -> integration, not where the repo already is)

The two existing tests jump straight to full-app widget tests (pumping the
entire provider tree via a hand-rolled `_pumpHome`). That's the *hardest*
type to write and debug first - lots of moving parts, slow, brittle. For
learning, it's better to start at the simplest, fastest, most isolated layer
and build up. Pure logic first, then a single provider in isolation, then a
single widget in isolation, and only then full-screen/integration flows.

## Phase 0 - Infra (do this once, first)

1. Add `mocktail` to `dev_dependencies` in `pubspec.yaml` (`fvm flutter pub add --dev mocktail` - always use `fvm flutter`, not the global `flutter`, in this repo).
2. Create `test/helpers/` with:
   - `mocks.dart` - `class MockTaskService extends Mock implements TaskService {}` style declarations, one per service, added as you need them (don't pre-write all of them).
   - `pump_app.dart` - a small reusable `pumpApp(tester, {required Widget child, List<ChangeNotifierProvider> providers})` helper wrapping `MaterialApp(theme: AppThemes.lightTheme(...), home: child)` in a `MultiProvider`. This replaces the inline `_pumpHome`-style duplication in the two existing files over time - don't refactor those two files yet, just stop the pattern from spreading.

## Phase 1 - Pure unit tests (no mocks, no widgets)

Best possible starting point: zero setup, instant feedback, teaches core
`test`/`expect` mechanics before any Flutter-specific concepts.

- `lib/core/enums/task_enums.dart` -> `test/core/enums/task_enums_test.dart`
  - `TaskPriorityApi.apiValue` / `fromApiValue` round-trip for every enum value.
  - `fromApiValue` throws `ArgumentError` on an unknown string - assert with `expect(() => ..., throwsArgumentError)`.
  - Same for `TaskStatusApi`.
- `lib/features/task/models/task_model.dart` -> `test/features/task/models/task_model_test.dart`
  - `fromJson`: full payload, and edge cases - missing `status` (should default to `open`), null `dueDate`.
  - `toJson`: confirms server-key mapping (`priority`/`status` use `.apiValue`, not the enum), and that `id`/`createdBy` are never serialized.
  - `copyWith`: only `status` changes, everything else is preserved by reference/value.

Run with `fvm flutter test test/core/enums/task_enums_test.dart` to see one file at a time while learning.

## Phase 2 - Provider unit tests (first real use of mocktail)

This is where mocking gets learned: verifying a provider's behavior without a
real network call.

- `lib/features/task/providers/task_provider.dart` -> `test/features/task/providers/task_provider_test.dart`
  - Mock `TaskService` and `GroupProvider` (mocktail: `when(() => mockService.listTasks(...)).thenAnswer((_) async => [...])`).
  - `loadTasks()`: sets `isLoading` true then false, populates `tasks`, sets `errorMessage` on a thrown `TaskServiceException`.
  - Client-side filtering logic (`_matchesClientFilters`/`_matchesDateFilter` are private, so test them indirectly through the public `tasks` getter after calling `setPriorityFilter`/`setDateFilter`): this is the highest-value target in the whole feature since it's real, branchy business logic with zero Flutter dependency.
  - Sorting: `setSortOption(TaskSortOption.priority)` vs `dueDate`, confirm order, confirm tasks with null `dueDate` sort last.
  - `createTask`/`updateTask`/`deleteTask`: confirm they call the mock with expected args and update `tasks` correctly, including the "result doesn't match current status filter, so it's dropped" branch.

## Phase 3 - Isolated widget tests

Now bring in `pumpWidget`, but only for one widget at a time - not the whole
app tree.

- `lib/features/shared/widgets/app_card.dart` -> `test/features/shared/widgets/app_card_test.dart`
  - Renders `child`. Tapping calls `onTap`. Also worth confirming: when both `onTap` and `cardTap: true` are set, `AppCard` wraps content in two nested `InkWell`s (`app_card.dart:38` and `:41`) - write a test that taps and asserts `onTap` fires exactly once, since nested `InkWell`s are a common source of double-fire/gesture-conflict bugs.
- `lib/features/task/widgets/task_tile.dart` -> `test/features/task/widgets/task_tile_test.dart`
  - Wrap in `MaterialApp(home: Material(child: TaskTile(task: ...)))` - no providers needed, it's a dumb display widget.
  - Null-field fallbacks: no `title` -> shows `AppStrings.untitledTask`; no `description` -> `AppStrings.noDescriptionProvided`.
  - `groupName` shown only when non-null.
  - Due-date chip shown only when `dueDate != null`.
  - Tapping calls `onTap`.
  - Note while you're in this file: `onEdit` is accepted as a prop but never used in `build()` (`task_tile.dart:28`) - not a testing task, but worth a follow-up cleanup ticket, since a test asserting "onEdit fires" would currently fail.

## Phase 4 - Consolidate existing widget tests

Once `test/helpers/pump_app.dart` exists and mocktail is comfortable, go back
and refactor `task_filter_sheet_test.dart` and `journal_screen_test.dart` to
use the shared helper and mocktail mocks instead of the hand-rolled fake
subclasses. This is a good exercise in recognizing duplication once the
pattern has been seen twice.

## Phase 5 - Integration tests

Add the `integration_test/` package and directory (doesn't exist yet). Start
with exactly one end-to-end flow through a real (or `integration_test`-mocked)
app: e.g. sign in -> land on home -> open a task -> mark complete. Keep this
to 1-2 flows initially - integration tests are slow and expensive, so they
should cover critical paths only, not be a substitute for the unit/widget
layers below.

## Phase 6 - Scale out feature by feature

Repeat Phases 1-3 for the next feature (`expense`, then `journal`, `group`,
`auth`, ...), always in the same order: enums/models -> provider -> widgets.
Track progress with `fvm flutter test --coverage` + `genhtml coverage/lcov.info -o coverage/html`
to see which files still have zero coverage, rather than chasing a global
percentage blindly.

## Verification

- Run one file at a time while learning: `fvm flutter test test/path/to/file_test.dart`.
- Run everything (same as CI): `fvm flutter test`.
- Coverage: `fvm flutter test --coverage`, then inspect `coverage/lcov.info` (or render HTML via `genhtml` if installed).
