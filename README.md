# TaskEasy (`manage_app`)

A Flutter app for managing tasks, splitting group expenses, keeping a daily
journal, and (soon) reminders — built around shared "groups" of people who
collaborate on tasks and expenses together.

This document is a deep technical reference: architecture, how every feature
is actually implemented, the performance/reliability decisions behind the
code, and known gaps. It's written to let a reader (human or agent) go from
zero to a working mental model of the entire codebase without having to read
every file first — though file paths and line-level detail are called out
throughout so you can jump straight to source.

- **Version:** `0.10.0+15` (see `pubspec.yaml`)
- **SDK:** Dart `^3.12.2`, Flutter (pinned via `fvm`, see [Development](#development))
- **State management:** `provider` (`ChangeNotifier`-based), no Bloc/Riverpod/GetX
- **Networking:** `dio`, with a hand-rolled sealed-class `Result` layer
- **Persistence:** `flutter_secure_storage` (tokens/user), `shared_preferences` (UI prefs), no local database — the app is fully server-backed with no offline cache
- **Backend:** a REST API at `https://manage-app-api.onrender.com/api` (hardcoded, see [Known Issues](#known-issues--technical-debt))

---

## Table of contents

1. [Architecture at a glance](#architecture-at-a-glance)
2. [Project structure](#project-structure)
3. [App bootstrap sequence](#app-bootstrap-sequence)
4. [Core infrastructure](#core-infrastructure)
   - [Networking layer](#networking-layer)
   - [Auth token lifecycle](#auth-token-lifecycle)
   - [State management pattern](#state-management-pattern)
   - [Navigation](#navigation)
5. [Design system](#design-system)
6. [Feature deep dives](#feature-deep-dives)
   - [Auth](#feature-auth)
   - [Task](#feature-task)
   - [Expense](#feature-expense)
   - [Group](#feature-group)
   - [Journal](#feature-journal)
   - [Settings](#feature-settings)
   - [Home & Reminders](#feature-home--reminders)
7. [Performance & reliability engineering](#performance--reliability-engineering)
8. [Testing](#testing)
9. [Known issues / technical debt](#known-issues--technical-debt)
10. [Development](#development)

---

## Architecture at a glance

```
                          ┌─────────────────────────────┐
                          │           main.dart          │
                          │  runApp(ManageApp)            │
                          └───────────────┬──────────────┘
                                          │
                          ┌───────────────▼──────────────┐
                          │  AppProviders (MultiProvider) │
                          │  hand-wired dependency graph  │
                          └───────────────┬──────────────┘
                                          │
                     ┌────────────────────┼────────────────────┐
                     │                    │                    │
             ┌───────▼──────┐    ┌────────▼───────┐   ┌────────▼────────┐
             │ SplashScreen  │    │  Feature screens │   │ ScreenAppBar /  │
             │ auto-login +  │    │  (Consumer/watch) │   │ shared widgets  │
             │ data preload  │    └────────┬───────┘   └─────────────────┘
             └───────┬──────┘             │
                     │             ┌───────▼────────┐
                     │             │ Feature Provider │  (ChangeNotifier,
                     │             │ extends BaseProvider) extends BaseProvider)
                     │             └───────┬────────┘
                     │                     │
                     │             ┌───────▼────────┐
                     │             │ Feature Service  │  (Task/Expense/Group/…)
                     │             └───────┬────────┘
                     │                     │
                     │             ┌───────▼────────┐
                     └────────────►│  ApiServices     │  → ApiResult<T> (sealed)
                                   │  (Dio wrapper)   │
                                   └───────┬────────┘
                                           │
                                   ┌───────▼────────┐
                                   │  ApiClient (Dio) │
                                   │  + AuthInterceptor│ (silent token refresh,
                                   └──────────────────┘  single-flight, retry-once)
```

**Layering, strictly enforced by convention (not by folder-import lint rules):**

`Screens/Widgets` → read/mutate → `Provider (ChangeNotifier)` → call → `Service` → call → `ApiServices`/`ApiClient` (Dio) → HTTP.

Every provider is constructor-injected with its service (and sometimes other
providers), which is what makes the provider layer unit-testable with fakes/
mocktail mocks without touching the network (see [Testing](#testing)).

---

## Project structure

```
lib/
├── main.dart                     # App entry point, MaterialApp, session-expiry listener
├── core/                         # Cross-feature infrastructure — no feature imports this "up"
│   ├── constants/                # app_constants.dart (app version const), app_urls.dart (all REST paths)
│   ├── enums/                    # task_enums.dart, expense_enums.dart, group_enums.dart
│   ├── extensions/                # BuildContext.appTheme, double.toCurrencyString(), DateTime helpers, String.toTitleCase()
│   ├── providers/                # AppProviders (DI wiring), GlobalDataProvider (cross-feature load/reset)
│   ├── resources/                # app_assets.dart, app_fonts.dart, app_strings.dart (ALL user-facing text)
│   ├── services/                 # ApiClient, ApiServices, ApiResult, AuthInterceptor, TokenStorageService,
│   │                              # NavigationService, SessionExpiredNotifier, and one service per feature's
│   │                              # backend surface (auth/task/expense/group/journal)
│   └── themes/                    # AppThemes (ThemeData factories), AppTheme (ThemeExtension), design tokens
├── features/
│   ├── auth/                     # sign-in, sign-up, splash/auto-login
│   ├── task/                     # task CRUD, filtering, sorting
│   ├── expense/                  # group expense splitting, dashboard, charts
│   ├── group/                    # shared "group" container, invite codes, membership
│   ├── journal/                  # daily journal with autosave
│   ├── settings/                 # profile, password, theme/font, health-check debug tool
│   ├── home/                     # bottom-nav shell composing the 4 main tabs
│   ├── reminders/                # placeholder ("coming soon") — no logic yet
│   └── shared/                   # BaseProvider + the entire shared widget/design-system library
test/                             # 2 widget tests today (see Testing)
docs/
├── UNIT_TESTING_GUIDE.md         # step-by-step guide to writing unit/provider tests + mocktail
└── TESTING_ROADMAP.md            # phased plan for growing test coverage from ~0
.agent/                           # project coding/theme/git-flow/jira standards (see repo CLAUDE.md)
```

Each feature directory follows the same internal shape: `models/`,
`providers/`, `screens/`, `widgets/`, `validators/` (where relevant),
`services/` (only for settings, which has feature-local services distinct
from `core/services/`).

---

## App bootstrap sequence

`main.dart` is intentionally thin — there's no async work before `runApp()`
(no `WidgetsFlutterBinding.ensureInitialized()`, no preloaded secure-storage
read). All async initialization happens **after** the widget tree is mounted:

1. **`runApp(const ManageApp())`** — `ManageApp` is a `StatefulWidget`. In
   `initState()` it subscribes to the global `sessionExpiredNotifier`
   (a bare event-bus `ChangeNotifier`, see [Auth token lifecycle](#auth-token-lifecycle)),
   so a forced logout from anywhere in the app (even from inside a Dio
   interceptor with no `BuildContext`) routes back to `SignInScreen` via a
   global `navigatorKey`.
2. **`AppProviders`** (`core/providers/app_providers.dart`) builds the entire
   provider graph as `late final` fields in explicit dependency order, each
   chained with `..onInit()`:
   ```
   AuthProvider           → onInit() first, nothing depends on race-y session state
   ProfileProvider        → onInit()
   GroupProvider          → depends on AuthProvider + ProfileProvider (constructor args)
   TaskProvider           → depends on GroupProvider
   ExpenseProvider        → depends on GroupProvider
   JournalProvider        → depends on ProfileProvider
   GlobalDataProvider     → depends on all six above, coordinates load/reset lifecycle
   ThemeProvider / FontProvider → registered lazily via ChangeNotifierProvider(create:)
   ```
   Providers that are pre-constructed (`late final` fields) are registered
   with `ChangeNotifierProvider.value(...)` so Provider doesn't try to
   recreate them; `ThemeProvider`/`FontProvider` use `create:` since they're
   fine being constructed lazily by the framework.
3. **`MaterialApp`** is rebuilt by a `Consumer2<ThemeProvider, FontProvider>`
   at the root of `ManageApp.build()`, wired with `navigatorKey`,
   `theme`/`darkTheme` built by `AppThemes.lightTheme/darkTheme(font: ...)`,
   and `home: const SplashScreen()`.
4. **`SplashScreen`** does the actual work, in this exact order:
   ```dart
   await authProvider.restoreSession();      // read secure storage, set _currentUser if present
   await globalDataProvider.loadAllData();   // profile → active group → [tasks, expenses, journal] in parallel
   navigationService.pushReplacement(context,
     isAuthenticated ? HomeScreen() : const SignInScreen());
   ```
   While waiting, a `Timer.periodic` cycles through a fixed list of loading
   strings purely for UX flavor (including a joke line — this is real, not a
   typo: `'Our server is shit. Please wait...'`).

   Note this is a **token-presence check, not a token-validity check** — a
   stored-but-expired access token still routes to `HomeScreen`; the first
   authenticated API call afterwards is what actually exercises the refresh
   flow (and, if the refresh token is also dead, boots the user back to
   sign-in from inside the app via `sessionExpiredNotifier` rather than from
   splash).
5. **`GlobalDataProvider.loadAllData()`** (`core/providers/global_data_provider.dart`)
   is the single entry point that populates every feature provider — no
   feature provider self-loads in its own `onInit()`, specifically to avoid
   duplicate fetches when providers are constructed. Sequencing matters here:
   `profileProvider.loadProfile()` must resolve before `groupProvider.restoreActiveGroup()`
   because group restoration falls back to the profile's server-synced
   `defaultGroupId` when there's no local preference. Once that's done,
   `Future.wait([taskProvider.loadTasks(), expenseProvider.loadExpenses(), journalProvider.loadInitial()])`
   fetches the three independent resources concurrently.

---

## Core infrastructure

### Networking layer

**`ApiClient`** (`core/services/api_client.dart`) wraps one `Dio` instance:
`BaseOptions(baseUrl: AppUrls.baseUrl, contentType: 'application/json')`, no
explicit timeouts (Dio defaults apply). Three interceptors, in order:

1. An inline `onRequest` interceptor that reads the access token from
   `TokenStorageService` on every outgoing request and attaches
   `Authorization: Bearer <token>` if present (no in-memory token cache —
   every request re-reads secure storage).
2. `AuthInterceptor` — the refresh/retry logic, see below.
3. `LogInterceptor(requestBody: true, responseBody: true)`, added **only
   `if (kDebugMode)`** — full request/response logging never ships to
   release builds.

**`ApiResult<T>`** (`core/services/api_result.dart`) is a genuine Dart 3
sealed-class Either:

```dart
sealed class ApiResult<T> {
  R when<R>({required R Function(T data) success, required R Function(Failure failure) failure});
}
final class ApiSuccess<T> extends ApiResult<T> { final T data; }
final class ApiError<T>   extends ApiResult<T> { final Failure failure; }
```

`when()` pattern-matches exhaustively — the compiler enforces both branches
are handled. `Failure` carries a message, optional status code, and a
`FailureType` enum (`timeout, noConnection, cancelled, badCertificate,
badResponse, unknown`).

**`ApiServices`** (`core/services/api_services.dart`) is the single HTTP
call surface: generic `get/post/put/patch/delete<T>` methods, each taking a
`parser: T Function(dynamic) `. Every `DioException` is converted into a
typed `Failure` with a friendly message via a status-code `switch`
(400/401/403/404/409/422/429/5xx/other). One deliberate business rule: **a
401 on a request that already carried an `Authorization` header always gets
a generic "Your session has expired" message**, never the backend's raw
text — by the time `ApiServices` sees the error, `AuthInterceptor` has
*already* tried a silent refresh, so a surviving 401 means the session is
genuinely dead. Unauthenticated calls (sign-in/sign-up) keep the backend's
specific message (e.g. "Invalid email or password").

Each feature has a thin **service** class (`TaskService`, `ExpenseService`,
`GroupService`, `JournalService`, `AuthService`, `ProfileService`,
`HealthService`) that calls `ApiServices` and unwraps `ApiResult` into
either the parsed model or a thrown feature-specific exception
(`TaskServiceException`, etc.) — this is the one place `ApiResult`'s
sealed-class pattern gets unwrapped; it never leaks up to providers or UI.
Every service accepts an optional injected `ApiServices`/dependency,
defaulting to a module-level singleton — a manual, framework-free DI
pattern used consistently everywhere (`AuthService({ApiServices? api}) :
_api = api ?? apiServices;`), which is also what makes services swappable
for fakes in tests.

### Auth token lifecycle

**Storage** — `TokenStorageService` wraps `flutter_secure_storage`
(Keychain on iOS, Keystore-backed EncryptedSharedPreferences on Android).
Three keys: `auth_access_token`, `auth_refresh_token`, `auth_user` (JSON).
Writes/deletes across multiple keys use `Future.wait([...])` to run in
parallel rather than sequentially, cutting platform-channel round-trip
latency.

**Refresh & retry — the standout reliability piece.** `AuthInterceptor`
(`core/services/auth_interceptor.dart`) intercepts Dio's `onError`:

- Only acts on a `401` that isn't the refresh call itself and hasn't already
  been retried once (tracked via `requestOptions.extra['authInterceptorRetried']`)
  — this hard-caps retries at 1, preventing infinite refresh loops.
- **Single-flight refresh**: concurrent 401s share one in-flight refresh
  call instead of each firing its own:
  ```dart
  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  }
  ```
  If 5 requests 401 at once, exactly one `POST /auth/refresh` fires; all 5
  await the same `Future`.
- On success: persists the new token pair, re-attaches the new
  `Authorization` header to the original failed request, marks it retried,
  and re-dispatches it via `dio.fetch(...)` — the original caller
  transparently receives a successful response despite the initial 401.
- On the refresh call itself getting 401/403 (refresh token rejected — the
  session is unrecoverable): clears all stored auth data and fires
  `sessionExpiredNotifier.notifySessionExpired()`.
- On any *other* refresh failure (network blip, 5xx): treated as
  transient — returns `null`, lets the original error surface normally so
  the user's own "Retry" affordance can re-attempt. This distinction
  (session-dead vs. transient-network-blip) is a deliberate design choice
  documented directly in the class.

**Global session-expiry fan-out** — `SessionExpiredNotifier` is a trivial
`ChangeNotifier` singleton with one method (`notifySessionExpired()`) and no
payload — a pure event bus used because the Dio layer has no
`BuildContext`/`Provider` access. Three independent listeners react to the
same event:

| Listener | Reaction |
|---|---|
| `ManageApp` (main.dart) | Forces navigation to `SignInScreen` via the global `navigatorKey`, clearing the stack |
| `AuthProvider` | Nulls `_currentUser` in memory (storage was already cleared by the interceptor) |
| `GlobalDataProvider` | Wipes in-memory task/expense/journal/profile state |

This gives a clean "global logout" with no provider needing a
`BuildContext` or navigation awareness.

### State management pattern

Pure `provider` package (`ChangeNotifier`), no other state library. Every
feature provider extends **`BaseProvider`** (`features/shared/providers/base_provider.dart`),
a small shared base that is *not* a generic "resource state" base (it has no
`isLoading`/`errorMessage` fields — each provider reimplements those
itself) but *does* enforce:

- Abstract `onInit()`/`onDispose()` lifecycle hooks (manually chained at
  construction time in `AppProviders`, not Flutter's own lifecycle).
- A `disposed` flag, checked before every `notifyListeners()` call to avoid
  use-after-dispose exceptions from late-completing async work.
- **Post-frame deferral**: if `notifyListeners()` is called while
  `SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks`
  (i.e. mid-build), it's deferred to `addPostFrameCallback` instead of firing
  immediately. This exists because several providers have chained,
  interdependent async `onInit()`s (`GroupProvider` awaits `AuthProvider`,
  `GlobalDataProvider` awaits everything) — without this guard, one
  provider's async work resolving mid-build elsewhere in the tree would
  throw Flutter's "setState()/markNeedsBuild() called during build" error.

Screens read providers with `context.watch<T>()` (build-time subscription,
whole-object) or `context.read<T>()` (one-shot, for actions). **No `Selector`
usage exists anywhere in the codebase** — every `watch` rebuilds on any
field change in that provider, which is an accepted tradeoff given the app's
screen sizes (see [Performance](#performance--reliability-engineering)).

### Navigation

Two parallel navigation mechanisms coexist by design:

- **`NavigationService`** (`core/services/navigation_service.dart`) — a
  thin, context-based wrapper (`push`/`pushReplacement`/`pushAndRemoveUntil`/`pop`),
  used by ordinary screen-initiated navigation.
- **A global `navigatorKey`** (`GlobalKey<NavigatorState>`, declared
  alongside `NavigationService`) attached to the root `MaterialApp`,
  specifically so context-less code (the Dio auth interceptor) can still
  force navigation back to sign-in on session expiry.

---

## Design system

The whole app is themed through Flutter's `ThemeExtension<T>` mechanism,
layered on top of standard `ThemeData`/`ColorScheme` for anything the custom
extension doesn't cover.

- **`AppTheme`** (`core/themes/theme_extensions/app_theme.dart`) —
  `extends ThemeExtension<AppTheme>`, holds 3 colors, 15 Material 3 text
  styles, and 10 numeric tokens (border radius, control height,
  margins/spacings, elevations), all nullable, with `copyWith()`/`lerp()`
  implemented (so theme transitions animate smoothly across every field
  type via `Color.lerp`/`TextStyle.lerp`/`lerpDouble`).
- **`AppThemes`** (`core/themes/app_theme.dart`) — builds the two
  `ThemeData` objects, `lightTheme({required font})`/`darkTheme({required font})`,
  as **factory functions, not consts**, because text styles depend on the
  runtime-selected font. Deliberately pins `primaryContainer`/
  `secondaryContainer` (and all `surfaceContainer*` slots) to `AppColors`
  rather than using `ColorScheme.fromSeed` — a code comment explains
  `fromSeed` was producing an unwanted purple cast and mismatched blues
  between `SegmentedButton`'s selected pill and the FAB/avatar (this fix
  shipped as commit `8dc85a2`).
- **Access pattern** — one extension, `BuildContextThemeExtensions`:
  ```dart
  extension BuildContextThemeExtensions on BuildContext {
    AppTheme get appTheme => Theme.of(this).extension<AppTheme>()!;
    bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  }
  ```
  Every shared widget reads tokens via `context.appTheme.xxx ?? literalFallback`
  — nullable-field-with-fallback is the house style throughout.

**Design tokens:**

| Scale | File | Values |
|---|---|---|
| Colors | `app_colors.dart` | `primaryColor 0xFF0153F7`, `secondaryColor 0xFF022B80`, plus background/surface/text/outline/error, each with a `Dark` variant (brand blue stays identical in dark mode; background/surface/text/outline flip) |
| Spacing | `app_spacing.dart` | `space1..space20` (2px steps) + aliases `xSmall(4)/small(8)/medium(16)/large(24)/xLarge(28)` |
| Sizing | `app_sizing.dart` | `size2..size24` (mostly 2px steps) + `size36(72)`, same alias names/values as spacing |
| Elevation | `app_elevation.dart` | `small 1.0 / medium 3.0 / large 6.0` |

(`AppSpacing` and `AppSizing` overlap almost entirely — see [Known Issues](#known-issues--technical-debt).)

**Typography** — `AppFonts` defines `enum AppFontOption { bitcount, roboto,
poppins, inter, lato }` (default `bitcount`), each dispatching to a
`google_fonts` call. `AppStyles` is the Material 3 type-scale table (15
named methods: display/headline/title/body/label × large/medium/small),
the single place font size/weight per role is defined. A text-widget
hierarchy in `features/shared/widgets/text/` — `DisplayText`, `HeadlineText`,
`TitleText`, `BodyText`, `LabelText` (each with `.large/.medium/.small`
constructors) — reads exclusively from `context.appTheme`, not
`Theme.of(context).textTheme`, so a font swap or brightness change flows
through one path everywhere text appears.

**Runtime customization** — `ThemeProvider`/`FontProvider` (both extend
`BaseProvider`) persist to `shared_preferences` via `ThemePreferenceService`/
`FontPreferenceService` (keys `settings_is_dark_mode`, `settings_app_font`).
Both providers default to a hardcoded value (`true`/dark, `bitcount`) before
their async `onInit()` read resolves — meaning a user whose saved preference
differs sees one frame of the default before the real preference loads (a
minor, known cold-start flicker, not flicker-free by design). There is
**no "follow system theme" option** — `ThemeProvider.themeMode` only ever
returns `ThemeMode.dark`/`.light`, even though `MaterialApp` is wired to
accept `ThemeMode.system`.

**Shared widget library** (`features/shared/widgets/`) — the primitives
every screen is built from:

| Widget | Purpose |
|---|---|
| `AppButton` | `.primary/.secondary/.destructive`, full-width, theme-radius, wraps `Semantics(button: true, ...)` — never bypass this for accessibility |
| `AppCard` | Generic card wrapper; supports an optional `Gradient` painted behind the child (used by the task tile's priority gradient) |
| `AppScaffold` | `Scaffold` + `SafeArea` + tap-outside-to-dismiss-keyboard + optional scrollable body that still fills short screens |
| `AppBodyColumn` | Theme-margined `Column` — mandated for top-level screen columns |
| `AppBottomSheet` | Modal sheet shell: drag handle, title/icon, scrollable body, auto footer or custom footer |
| `AppDatePicker` / `AppTimePicker` | `FormField` wrappers around the native date/time pickers, styled like a text field |
| `AppDropdownField<T>` | Custom animated single-select dropdown (not Material's `DropdownButton`) |
| `AppImage` | `.asset`/`.network`; network variant uses `cached_network_image` with a spinner placeholder and broken-image fallback |
| `AppSvgIcon` | `flutter_svg` wrapper inheriting size/color from ambient `IconTheme`, like `Icon` |
| `AppTextField` | Default/`.password` (obscure + reveal toggle)/`.multiline` (borderless, for journal entries) |
| `InfoCard` / `InfoRow` | Bordered metadata block with divider-separated icon+label+value rows (task detail, etc.) |
| `MemberDropdownField` | `AppDropdownField<GroupMemberModel>` specialization, appends "(You)" for the current user |
| `ScreenAppBar` | Flat app bar, theme-matched background, optional back button, `TitleText.large` title |
| `SettingsAvatarButton` | Avatar `IconButton` opening `SettingsScreen`, present in every top-level tab's app bar |

---

## Feature deep dives

### Feature: Auth

**Models** — `UserModel` (id/name/email + optional phone/defaultGroupId/createdAt),
`TokenPairModel` (accessToken/refreshToken), `AuthSessionModel` (wraps both
— its `fromJson` reads `user` from a nested key but tokens from the
top-level response object, matching the backend's response shape).

**`AuthProvider`** funnels sign-in and sign-up through one private
`_authenticate(action)` helper: sets loading, clears error, calls the
service, on success persists the `AuthSessionModel` via `TokenStorageService`
and updates `_currentUser`, on failure sets `_errorMessage` from the
service's exception, always resets loading in `finally`. `restoreSession()`
(splash-time auto-login) just reads whatever session is in secure storage.
`signOut()` best-effort calls the server logout endpoint (swallowing
failures — local session is cleared regardless of server outcome) then
unconditionally clears storage in a `finally` block.

**Sign-in / sign-up screens** are near-identical `StatefulWidget`s: a
`Form` + one controller per field, validation triggered only on submit
(`autovalidateMode` left at default), disabling all fields and swapping the
submit button's label to a progressive form ("Signing in...") while
`AuthProvider.isLoading`. On success both call
`GlobalDataProvider.loadAllData()` then `pushAndRemoveUntil(HomeScreen())`,
clearing the stack so back-navigation can't return to sign-in. On failure,
`authProvider.errorMessage` shows in a `SnackBar`.

**Validation** (`auth_validators.dart`): email must match
`^[^@\s]+@[^@\s]+\.[^@\s]+$`; password requires a minimum length of 8
(`passwordMinLength`). Sign-up additionally validates full name (non-empty)
and confirm-password (must equal the *live* password field text, not a
snapshot).

### Feature: Task

**Model** (`TaskModel`) — `id`, `title`, `description`, `priority`
(`TaskPriority: low/medium/high`), `status` (`TaskStatus: open/completed`,
defaults to `open` if the server omits it — backward compat with older API
responses), `createdAt`, `dueDate`, `groupId`, `createdBy`, `assignedTo`
(defaults server-side to the creator when omitted).

**`TaskProvider`** splits filtering into two tiers:

- **Server-side**: `taskStatusFilter` (defaults to `open`, `null` = both)
  and the active-group scope — changing either re-triggers a full
  `loadTasks()` network call.
- **Client-side**: priority filter, date filter (`all/today/tomorrow/custom`),
  sort option (`dueDate/priority`) — these only call `notifyListeners()`;
  the public `tasks` getter re-derives the visible list on every read:
  ```dart
  tasks => _applySort(_tasks.where(_matchesClientFilters).toList())
  ```
  Sorting by due date puts tasks with no due date last; sorting by priority
  ranks `high(3) > medium(2) > low(1) > null(0)`, descending.

CRUD mutations avoid full reloads: `createTask` appends the server's
returned task locally only if it still matches the current status filter
(so creating a `completed` task while filtered to "open" correctly doesn't
show it); `updateTask` filters out the old copy and re-adds the updated one
only if it still passes the filter (this is *how* marking a task complete
makes it vanish from an "open" list without a re-fetch); `deleteTask`
removes it locally after the server call succeeds.

**Screens**:
- `TaskListScreen` — a `SegmentedButton<bool>` toggles "this group" vs "all
  groups"; body is a `RefreshIndicator` + `ListView.builder`; empty/loading/
  error states are handled explicitly, including a "no groups yet" prompt
  that redirects task creation to `GroupsScreen` first.
- `TaskDetailScreen` — lazily loads group members if not cached (to resolve
  the assignee's display name), shows a `_PriorityCard` banner, an
  `InfoCard` of due/created/assignee metadata, and a "Close Task" action
  that calls `updateTask(status: completed)`.
- `TaskFormScreen` — shared create/edit form. Assignment is **create-only**
  (the API doesn't support reassigning an existing task); on create it
  defaults the assignee to the current user if they're a group member.
  Validates title/description/date/time as required fields via the `Form`;
  priority is checked manually in `_submit()` (not wired through the form
  validator) and shown via `SnackBar` if missing.
- `TaskFilterSheet` — every control (status/priority/sort dropdowns, date
  `ChoiceChip`s) writes directly to the corresponding `TaskProvider` setter
  with no local buffering, so filters apply live underneath the open sheet;
  "Apply" is effectively just "close," "Clear All" resets everything.

**Priority-colored tile & overflow history** (`task_tile.dart`) — the
current design paints the whole `AppCard` background with a
`LinearGradient` from the full-saturation priority color to a near-black
tint of it (`Color.lerp(priorityColor, Colors.black, 0.75)`), replacing an
earlier neutral-card-with-colored-stripe design. All text/icons switched to
fixed white/white-alpha since theme-derived colors don't contrast reliably
against an arbitrary priority hue. This shipped across two commits:
`cd3c73b` fixed an `IntrinsicHeight`+`Row` overflow bug (replaced with a
`Stack` + plain `Column` so wrapping description text grows the tile height
instead of overflowing), then `360779b` replaced the stripe layout entirely
with the full-surface gradient. `TaskPriorityBadge.colorFor` maps
`high→colorScheme.error`, `medium→colorScheme.primary` (deliberately not
`tertiary`, which is unset in `AppThemes` and falls back to Material's
default muted purple), `low→colorScheme.outline`.

### Feature: Expense

Group expense-splitting, Splitwise-*adjacent* but intentionally simpler:
**there is no settlement/netting algorithm** — `ExpenseSplit` is documented
in-code as "just recorded amounts for now; no settle-up/netting logic
exists," and there's no `SplitType` enum (no percentage-split mode). Every
split is a flat `{userId, amountOwed}` record; "equal split" is a client-side
convenience button, not a distinct persisted mode.

**Model** (`ExpenseModel`) — `id`, `title`, `amount` (the total), `category`
(`ExpenseCategory: food/transport/shopping/bills/entertainment/health/other`),
`date`, `groupId`, `payerId` (null → server defaults to the creator), `splits`
(`List<ExpenseSplit>`), `essential` (bool, drives the dashboard's
essential/non-essential breakdown).

**Equal-split algorithm** (`ExpenseFormScreen._splitEqually`) — works in
integer cents to avoid floating-point remainder drift, then distributes the
leftover cent-by-cent to the first N members so the split total always
equals the entered amount exactly:
```
totalCents = round(amount * 100)
baseShareCents = totalCents ~/ memberCount
remainderCents = totalCents % memberCount
for i, member in enumerate(checkedMembers):
    cents = baseShareCents + (1 if i < remainderCents else 0)
```
e.g. $10.00 split 3 ways → $3.34 / $3.33 / $3.33. Custom (non-equal, manual)
per-member amounts are also supported — a user can type arbitrary values as
long as they sum to the total within a `0.01` tolerance
(`AppStrings.splitsMismatchError` otherwise); payer/splits are **creation-only**,
not editable on an existing expense.

**Dashboard & charts** — `ExpenseProvider.categoryBreakdownThisMonth` does
all the aggregation (filter to current month → sum per category → sort
descending → normalize to fractions of the month's total), recomputed as a
plain getter on every access (no memoization — fine at expected list sizes).
`ExpenseDonutChart` is a **custom `CustomPainter`** (not a charting
package) drawing one `drawArc` per category starting at 12 o'clock, no
animation. `ExpenseCategoryStyle` centralizes the fixed decorative
icon/color mapping per category, explicitly kept separate from `AppTheme`
design tokens since it's not a theme concern.

**Filtering/sorting is entirely client-side** on the already-loaded list —
`ExpenseFilterSheet` (category only), plus a free-text search and date-range
picker living directly in `AllExpensesScreen`; `ExpenseSortSheet`
(newest/oldest/amount high/amount low). `AllExpensesScreen` groups the list
by date with inline headers, but only when the active sort is
date-based (`newest`/`oldest`) — grouping by date under an amount-sort would
be meaningless, and the screen guards for that explicitly.

### Feature: Group

A `GroupModel` (name, invite code, creator, and — only on the list endpoint
— the caller's `role`) is the shared context that scopes both tasks and
expenses: switching the active group (`GroupsScreen._switchTo`) immediately
re-triggers `TaskProvider.loadTasks()` and `ExpenseProvider.loadExpenses()`.
"Active group" has **no server concept** — it's purely a client-side
notion.

**Invite codes** are server-generated (returned on create), joined via a
single required text field with `TextCapitalization.characters`.
`InviteCodeView` integrates `share_plus` (`Share.share('Join my group...')`)
and clipboard copy, and is reused in both the create-group success screen
and the group-details screen so an owner can always re-share the code.

**Roles** — `GroupRole: owner/member`. Only owners see the rename form and
the destructive "Delete Group" action (behind a confirmation dialog) in
`GroupDetailsScreen`; non-owners only see the invite-code view.

**Active-group persistence** (`GroupPreferenceService`, backed by
`shared_preferences`) resolves with a 3-tier fallback on restore: local
saved preference → the profile's server-synced `defaultGroupId` (covers a
fresh install/new device) → the first group in the list → `null`. Every
`setActiveGroup` call also does a **best-effort, non-blocking, `unawaited`**
sync of the new default group to the server via `ProfileProvider`, silently
swallowing failures — a cross-device convenience sync that must never
surface as a user-facing error.

### Feature: Journal

One entry per calendar day (enforced by backend upsert semantics — a
`JournalEntryModel` has `date` normalized to midnight, `content`).
`JournalProvider` paginates **backward from today in 30-day windows**,
tracking `_earliestLoadedDate` and clamping against the account's creation
date (falling back to "today" if the profile hasn't loaded `createdAt` yet,
which avoids generating an unbounded run of empty days). The `days` getter
synthesizes a descending, **gap-filled** list — days with no entry become
explicit "missing" slots (not omitted), which is how `JournalDayTile`
renders a muted "No entry" row for any day, including ones before the user
ever wrote anything.

**Autosave** (`journal_save_status_indicator.dart` + `JournalEntryScreen`)
is debounce-based, no manual save button:
- Every keystroke resets an 800ms `Timer`; when it fires, `_save()` runs
  only if the text actually changed since the last save (`_lastSavedContent`
  comparison avoids redundant no-op network calls).
- Status cycles through `idle → saving → saved`/`error`, rendered as a
  small indicator in the app bar (spinner while saving, muted "Saved" label,
  or a tappable "Could not save entry" retry button on error).
- **Flush-before-pop**: wrapped in `PopScope(canPop: false, ...)` — a pop
  attempt cancels any pending debounce timer and awaits `_save()`
  synchronously before completing the navigation, so the last few keystrokes
  before a fast back-swipe aren't lost.

`CreateTodayCard` replaces the generic day tile specifically for an
empty "today" slot, nudging the user to write with a more prominent CTA
than the muted "missing" styling used for past gaps.

### Feature: Settings

Composes: `ProfileHeader` (avatar/name/edit), a Groups shortcut, a
"Customise the app" screen (font picker), Dark Mode `Switch.adaptive`
(→ `ThemeProvider`), and sign-out. **Profile edit** validates name
(non-empty), email (same regex as auth), and an *optional* phone
(`^\+?[0-9]{7,15}$` if present — empty clears it); on success it also pushes
the update into `AuthProvider.updateCurrentUser` to keep the in-memory
signed-in user consistent. **Change password** requires current password,
a new password (≥8 chars), and a matching confirmation — does not force a
re-login or invalidate other sessions client-side.

**Hidden health-check debug tool** — double-tapping the app-version text
at the bottom of `SettingsScreen` (`onDoubleTap`, with `NoSplash` splash
factory so the tap gives zero visual feedback while hidden) reveals a
button that calls `GET /health` and displays raw `status`/`uptime`/`db`
fields — a developer/tester diagnostic for confirming the backend and its
database are reachable, deliberately hidden from ordinary users.

### Feature: Home & Reminders

`HomeScreen` holds a `static const` list of four already-instantiated tab
screens (`TaskListScreen`, `ExpenseDashboardScreen`, `RemindersScreen`,
`JournalScreen`) rendered via `IndexedStack` — all four stay mounted across
tab switches, so scroll position, in-progress filters, etc. survive
navigating away and back. Settings is reached via a `SettingsAvatarButton`
in each tab's own app bar, not a fifth nav destination.

`RemindersScreen` is a genuine placeholder — a centered bell icon and a
"coming soon" string, no provider, no service, no state. It occupies a nav
slot but has no functionality yet.

---

## Performance & reliability engineering

A consolidated list of the deliberate (documented-in-code) optimizations
found across the codebase, gathered here since they cut across features:

- **Single-flight token refresh** — concurrent 401s share one in-flight
  `/auth/refresh` call instead of each firing their own (`AuthInterceptor`).
- **Parallel independent I/O** — `TokenStorageService` writes/deletes
  multiple secure-storage keys via `Future.wait`; `GlobalDataProvider.loadAllData()`
  loads tasks/expenses/journal concurrently once the (genuinely sequential)
  profile→group dependency resolves.
- **Debug-only verbose logging** — Dio's `LogInterceptor` is gated behind
  `kDebugMode`, avoiding overhead and request/response-body leakage in
  release builds.
- **Disposal-safe, build-safe `notifyListeners()`** — `BaseProvider` no-ops
  after disposal and defers to a post-frame callback when called mid-build,
  preventing both use-after-dispose crashes and Flutter's
  "called during build" exceptions in a provider graph with chained async
  initialization.
- **Debounced autosave with flush-on-exit** — journal entries save 800ms
  after the last keystroke, with a synchronous flush on back-navigation so
  no edits are silently dropped.
- **`IndexedStack` tab persistence** — all four home tabs stay mounted, so
  switching tabs doesn't rebuild or reset scroll/filter state.
- **Client-side filter/sort layering** — task and expense filtering/sorting
  happen client-side on an already-loaded list wherever they don't need a
  server round-trip (only status/group-scope changes trigger a network
  call for tasks; expense filters are 100% client-side), minimizing
  redundant fetches at the cost of holding the full list in memory (see
  [Known Issues](#known-issues--technical-debt) re: no pagination).
- **`ListView.builder`** used consistently for potentially-large lists
  (tasks, all-expenses, journal's infinite-scroll list); the expense
  dashboard's small, fixed-size section list intentionally uses a plain
  `ListView` instead.
- **Cent-based equal-split arithmetic** avoids floating-point drift when
  dividing an amount across N people.
- **Custom-painted donut chart** instead of pulling in a full charting
  package for one simple ring visualization.
- **`const` widgets** used where inputs allow, enabling Flutter's
  const-canonicalization to skip rebuilds of static subtrees.

**Accepted tradeoffs / not (yet) optimized**, documented here rather than
silently glossed over:
- No `Selector`-based fine-grained rebuild scoping anywhere — every
  `context.watch<T>()` rebuilds the whole watching subtree on any change to
  that provider. Acceptable at current screen/list sizes; would need
  revisiting if any feature list grows large or a screen watches multiple
  frequently-changing providers together.
- No pagination on tasks/expenses — `listTasks`/`listExpenses` fetch
  everything in one call, filtered/sorted client-side afterward.
- No memoization on repeatedly-recomputed getters (`categoryBreakdownThisMonth`,
  `filteredExpenses`, journal's `days` list) — cheap today, would need
  caching if these collections grow large.
- No local/offline database — the app has zero functionality without
  network connectivity beyond whatever's already loaded in memory.

---

## Testing

Current state: **2 widget tests, 0 unit tests** (`test/task_filter_sheet_test.dart`,
`test/journal_screen_test.dart`), no mocking library adopted yet in
practice (both existing tests use hand-written fake service subclasses).
CI runs `flutter test` on every PR.

Two docs in `docs/` capture the plan and teaching material:

- **`docs/TESTING_ROADMAP.md`** — the deliberate phased order: pure unit
  tests (enums/models, zero Flutter dependency) → provider unit tests with
  `mocktail` mocks → isolated single-widget tests → consolidating the two
  existing full-app widget tests onto shared helpers → integration tests
  (1-2 critical flows only) → repeat per feature. The two existing tests
  jump straight to the hardest tier (full provider tree + full screen), so
  the roadmap explicitly starts over at the simplest layer rather than
  building on that pattern.
- **`docs/UNIT_TESTING_GUIDE.md`** — a from-scratch tutorial covering
  `test`/`group`/`expect`/matchers, Arrange-Act-Assert, `mocktail` (mock
  declaration, `when`/`thenAnswer`/`thenThrow`, `verify`, `registerFallbackValue`
  gotcha for custom-typed `any()` args), `setUp` vs. shared mocks, and a
  common-pitfalls checklist (missing `await`, `thenReturn` on an async
  method, testing private methods directly instead of through the public
  API).

The app's layering (constructor-injected services → providers → widgets)
is what makes this roadmap viable without a DI framework: every provider
takes its service as a constructor parameter, so a test passes a fake/mock
service and the provider has no way to tell the difference.

```bash
fvm flutter test                                    # everything, same as CI
fvm flutter test test/path/to/file_test.dart         # one file
fvm flutter test --coverage                          # coverage/lcov.info
```

---

## Known issues / technical debt

Documented plainly so they're not mistaken for intended behavior:

- **`AppUrls.devBaseUrl` is dead code.** It's defined (env-var-driven
  localhost URL via `String.fromEnvironment`) but `ApiClient` always uses
  the hardcoded production `AppUrls.baseUrl` regardless of build flavor —
  there's no actual environment-based base-URL switching wired up despite
  the scaffolding suggesting there should be.
- **`AppScaffold` uses a raw `GestureDetector`** (tap-outside to dismiss the
  keyboard) — this conflicts with this project's own standing rule against
  `GestureDetector` usage. It's a small, contained, always-loaded shared
  widget, so worth a follow-up fix (e.g. swap for a transparent
  `Listener`/`InkWell`-based approach) rather than a functional bug.
- **`AppSpacing` and `AppSizing` are near-duplicate scales** — both define
  `xSmall/small/medium/large/xLarge` aliases at identical pixel values via
  different backing constant sets. Likely candidates to merge into one
  scale.
- **No settlement/netting algorithm for expenses** — despite the
  Splitwise-like UI, the app only stores flat per-member `amountOwed`
  records; there is no "who owes whom, net" computation and no percentage-
  split mode. If a feature request describes either, it does not exist yet.
- **Cold-start theme/font flicker** — `ThemeProvider`/`FontProvider` render
  one frame with their hardcoded defaults (dark mode, `bitcount` font)
  before their `shared_preferences` read resolves; a user with a different
  saved preference sees a brief flash of the default.
- **No "follow system theme" mode**, even though `MaterialApp` is wired to
  accept `ThemeMode.system`.
- **`RemindersScreen` is a placeholder** occupying a permanent bottom-nav
  slot with zero functionality behind it.
- **`TaskListScreen`'s `ListView.builder` items have no explicit `Key`** —
  fine for a fully-rebuilt-from-provider list, but would need addressing if
  reorder animations or `AnimatedList`-style transitions are ever added.

---

## Development

This repo pins its Flutter SDK via **`fvm`** — always run `fvm flutter ...`,
never the bare global `flutter`, or dependency resolution can fail against
a mismatched SDK version. See `.fvmrc` for the pinned version.

```bash
fvm flutter pub get       # install dependencies
fvm flutter run           # run on a connected device/emulator
fvm flutter test          # run the full test suite
fvm flutter analyze       # static analysis (flutter_lints, see analysis_options.yaml)
```

Project-specific coding, theming, git-flow, and Jira-ticket workflow
standards live in `.agent/` and are loaded automatically for this repo — see
`CLAUDE.md` for the index.
