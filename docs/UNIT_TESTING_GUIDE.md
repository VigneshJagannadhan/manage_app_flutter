# Unit Testing Guide

A concept-first, step-by-step walkthrough for writing the first unit tests in
this repo. This covers **unit tests only** (pure Dart logic - no
`pumpWidget`, no screens). Widget/integration tests are a separate learning
stage - see [TESTING_ROADMAP.md](TESTING_ROADMAP.md) for where those fit.

Read once top to bottom the first time; after that, use it as a reference.

---

## 1. What a unit test actually is

A unit test calls one small piece of code (a function, a method, a getter)
directly - no UI, no real network, no real database - and checks the output
matches what you expect. If a test needs to spin up a widget tree or talk to
a server to pass, it's not a unit test anymore.

Why bother: a unit test runs in milliseconds, fails with a precise line
number, and can be run hundreds of times a second while you work. That's the
entire pitch - fast, precise feedback.

## 2. Anatomy of a test file

Every Dart test file has the same skeleton:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskPriorityApi', () {
    test('apiValue maps low to LOW', () {
      expect(TaskPriority.low.apiValue, 'LOW');
    });

    test('apiValue maps high to HIGH', () {
      expect(TaskPriority.high.apiValue, 'HIGH');
    });
  });
}
```

- `main()` - the entry point the test runner calls. Every test file has
  exactly one.
- `group(description, callback)` - purely organizational. Groups related
  tests so failures print nested and readably. Optional but recommended once
  you have more than 2-3 tests in a file.
- `test(description, callback)` - one test case. The description shows up in
  failure output, so write it as a sentence describing the expected
  behavior, not the input ("throws on unknown value", not "test 3").
- `expect(actual, matcher)` - the assertion. First argument is the value you
  got, second is what you expected (or a *matcher*, see below).

## 3. Arrange - Act - Assert

Every test body, no matter how simple, is really three steps. Naming them
explicitly helps once tests get more involved:

```dart
test('fromApiValue throws on an unknown value', () {
  // Arrange - set up inputs (here, none needed beyond the literal)
  const badValue = 'URGENT';

  // Act - call the thing under test
  void act() => TaskPriorityApi.fromApiValue(badValue);

  // Assert - check the outcome
  expect(act, throwsArgumentError);
});
```

For a one-liner like `expect(TaskPriority.low.apiValue, 'LOW')`, act and
assert collapse into the same line - that's fine, you don't need to
force the three-comment structure onto trivial tests. Reach for it when a
test has real setup (constructing a model, configuring a mock) so it stays
readable.

## 4. Matchers - `expect`'s second argument

`expect` accepts more than a literal value. Matchers from `flutter_test`
you'll use constantly:

| Matcher | Meaning |
|---|---|
| `equals(x)` (or just `x`) | deep equality |
| `isNull` / `isNotNull` | null checks |
| `isTrue` / `isFalse` | bool checks |
| `throwsArgumentError` | the callback throws `ArgumentError` |
| `throwsA(isA<TaskServiceException>())` | throws a specific type |
| `isA<TaskModel>()` | runtime type check |
| `contains(x)` | list/string/iterable contains `x` |
| `hasLength(n)` | collection length |
| `isEmpty` / `isNotEmpty` | collection/string emptiness |

Note the pattern for exceptions: you pass a **function reference**, not a
function *call*, to `expect` - `expect(act, throwsArgumentError)`, not
`expect(act(), throwsArgumentError)`. If you call it eagerly, the exception
throws before `expect` ever runs and the test crashes instead of failing
cleanly.

---

## 5. Step-by-step: your first test file - `task_enums_test.dart`

Target: [lib/core/enums/task_enums.dart](../lib/core/enums/task_enums.dart).
This is the best possible starting point - pure functions, no classes to
construct, no async, no mocking.

**Step 1** - create the file at `test/core/enums/task_enums_test.dart`. The
path mirrors `lib/core/enums/task_enums.dart` - keeping test paths parallel
to `lib/` paths is the convention this repo already follows (see the `lib/
` vs `test/` structure once more test files exist) and makes a test easy to
find later.

**Step 2** - import what's under test and `flutter_test`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_app/core/enums/task_enums.dart';
```

**Step 3** - write one test per behavior. Looking at the source, `TaskPriorityApi`
has exactly two public members worth testing: `apiValue` (3 enum values -> 3
cases) and `fromApiValue` (3 valid strings + 1 invalid-input case):

```dart
void main() {
  group('TaskPriorityApi', () {
    test('apiValue returns the exact backend string for each priority', () {
      expect(TaskPriority.low.apiValue, 'LOW');
      expect(TaskPriority.medium.apiValue, 'MEDIUM');
      expect(TaskPriority.high.apiValue, 'HIGH');
    });

    test('fromApiValue parses every valid backend string', () {
      expect(TaskPriorityApi.fromApiValue('LOW'), TaskPriority.low);
      expect(TaskPriorityApi.fromApiValue('MEDIUM'), TaskPriority.medium);
      expect(TaskPriorityApi.fromApiValue('HIGH'), TaskPriority.high);
    });

    test('fromApiValue throws ArgumentError for an unknown string', () {
      expect(() => TaskPriorityApi.fromApiValue('URGENT'), throwsArgumentError);
    });
  });

  group('TaskStatusApi', () {
    test('apiValue returns the exact backend string for each status', () {
      expect(TaskStatus.open.apiValue, 'OPEN');
      expect(TaskStatus.completed.apiValue, 'COMPLETED');
    });

    test('fromApiValue parses every valid backend string', () {
      expect(TaskStatusApi.fromApiValue('OPEN'), TaskStatus.open);
      expect(TaskStatusApi.fromApiValue('COMPLETED'), TaskStatus.completed);
    });

    test('fromApiValue throws ArgumentError for an unknown string', () {
      expect(() => TaskStatusApi.fromApiValue('ARCHIVED'), throwsArgumentError);
    });
  });
}
```

**Step 4** - run it:

```bash
fvm flutter test test/core/enums/task_enums_test.dart
```

You should see 6 passing tests. Try deliberately breaking one (e.g. change
`'LOW'` to `'LOWER'` in the test) and re-run, to see what a failure looks
like before you need to debug a real one.

That's the whole pattern for testing pure functions: enumerate the inputs
that matter (every valid case, plus the invalid case), assert the output for
each.

---

## 6. Step-by-step: testing a data model - `task_model_test.dart`

Target: [lib/features/task/models/task_model.dart](../lib/features/task/models/task_model.dart).
Slightly more involved: `TaskModel` has a constructor, `fromJson`, `toJson`,
and `copyWith` - this is where you start thinking about **edge cases**, not
just the golden path.

**Step 1** - create `test/features/task/models/task_model_test.dart`.

**Step 2** - test `fromJson` with a full, well-formed payload first (the
golden path):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/features/task/models/task_model.dart';

void main() {
  group('TaskModel.fromJson', () {
    test('parses a fully-populated payload', () {
      final task = TaskModel.fromJson({
        '_id': 'task-1',
        'title': 'Buy milk',
        'description': 'From the corner store',
        'priority': 'HIGH',
        'status': 'OPEN',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'dueDate': '2026-01-05T00:00:00.000Z',
        'groupId': 'group-1',
        'createdBy': 'user-1',
        'assignedTo': 'user-2',
      });

      expect(task.id, 'task-1');
      expect(task.title, 'Buy milk');
      expect(task.priority, TaskPriority.high);
      expect(task.status, TaskStatus.open);
      expect(task.dueDate, DateTime.parse('2026-01-05T00:00:00.000Z'));
    });
```

**Step 3** - now the edge cases. Ask "what can legitimately be missing?" by
reading the source: `status` falls back to `open` when absent (there's a
comment explaining why - older backend responses), and `dueDate` is nullable.
These deserve their own tests, not just extra `expect`s bolted onto the test
above - if one assertion fails, you want the *test name* to already tell you
which case broke:

```dart
    test('defaults status to open when the field is absent', () {
      final task = TaskModel.fromJson({
        '_id': 'task-1',
        'title': 'Buy milk',
        'description': '',
        'priority': 'LOW',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(task.status, TaskStatus.open);
    });

    test('leaves dueDate null when the field is absent', () {
      final task = TaskModel.fromJson({
        '_id': 'task-1',
        'title': 'Buy milk',
        'description': '',
        'priority': 'LOW',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(task.dueDate, isNull);
    });
  });
```

**Step 4** - test `toJson`, focused on the parts that *aren't* a trivial
mirror of the fields - the things a careless refactor could silently break:
enum serialization uses `.apiValue` (not the enum name), and server-assigned
fields are never sent back:

```dart
  group('TaskModel.toJson', () {
    test('serializes priority and status using apiValue, not the enum name', () {
      final task = TaskModel(
        title: 'Buy milk',
        description: '',
        priority: TaskPriority.high,
        status: TaskStatus.open,
        createdAt: DateTime(2026, 1, 1),
      );

      final json = task.toJson();

      expect(json['priority'], 'HIGH');
      expect(json['status'], 'OPEN');
    });

    test('omits server-assigned fields', () {
      final task = TaskModel(
        id: 'task-1',
        title: 'Buy milk',
        description: '',
        priority: TaskPriority.low,
        createdAt: DateTime(2026, 1, 1),
        createdBy: 'user-1',
      );

      final json = task.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('createdBy'), isFalse);
    });
  });
```

**Step 5** - test `copyWith`, specifically that it only changes what you told
it to and leaves everything else untouched:

```dart
  group('TaskModel.copyWith', () {
    test('changes only status, keeps every other field', () {
      final original = TaskModel(
        id: 'task-1',
        title: 'Buy milk',
        description: 'From the corner store',
        priority: TaskPriority.medium,
        status: TaskStatus.open,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(status: TaskStatus.completed);

      expect(updated.status, TaskStatus.completed);
      expect(updated.title, original.title);
      expect(updated.priority, original.priority);
      expect(updated.createdAt, original.createdAt);
    });
  });
}
```

Run it the same way: `fvm flutter test test/features/task/models/task_model_test.dart`.

**The general lesson from this file:** for any data class, test three
things - parsing the golden path, parsing the fields that have
fallback/nullable behavior, and serialization edge cases (not the fields
that trivially round-trip, the ones with special-case logic).

---

## 7. Concept: mocking, and why `TaskProvider` needs it

`TaskProvider` (the next test target) depends on a real `TaskService`, which
makes real HTTP calls via `dio`. You do not want your unit tests to hit a
real network - they'd be slow, flaky (fail on no wifi), and could mutate
real server data.

The fix is already built into the code: `TaskProvider`'s constructor takes
`taskService` as a parameter (`TaskProvider({required this.taskService, ...})`)
rather than constructing its own `TaskService()` internally. This is called
**dependency injection**, and it's *why* this codebase is testable at all -
in a test, you pass in a **fake** `TaskService` instead of a real one, and
`TaskProvider` has no idea the difference.

A "fake" can be:
- **hand-written** - a subclass overriding the methods you need (this is
  what the two existing widget tests in this repo do), or
- a **mock object** generated by a library - you declare what to return for
  a given call, and the library builds a fake that returns exactly that.

This repo has adopted **mocktail** for mocks going forward (see the roadmap
doc). Mocktail's appeal: no code generation step (unlike `mockito`, which
needs `build_runner`), just plain Dart classes.

## 8. Mocktail concepts

Add it first: `fvm flutter pub add --dev mocktail`.

**Declaring a mock** - one line per class you need to fake:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';

class MockTaskService extends Mock implements TaskService {}
class MockGroupProvider extends Mock implements GroupProvider {}
```

`extends Mock implements X` gives you an object that *is* an `X` (so it
type-checks anywhere an `X` is expected) but where every method returns
`null`/throws by default until you configure it.

**Stubbing a method** - telling the mock what to do when called, with `when`:

```dart
final mockTaskService = MockTaskService();

// Synchronous return value:
when(() => mockGroupProvider.activeGroupId).thenReturn('group-1');

// Async return value (most of TaskService's methods are Future-returning):
when(() => mockTaskService.listTasks(
      status: any(named: 'status'),
      groupId: any(named: 'groupId'),
    )).thenAnswer((_) async => [/* fake TaskModel list */]);

// Throwing:
when(() => mockTaskService.listTasks(
      status: any(named: 'status'),
      groupId: any(named: 'groupId'),
    )).thenThrow(TaskServiceException('network error'));
```

Key points:
- `when(() => ...)` - the argument is a **function that makes the call**,
  not the call's result. This is how mocktail intercepts it.
- `thenReturn(x)` for synchronous values, `thenAnswer((_) async => x)` for
  `Future`-returning methods - `thenReturn` on an `async` method returns the
  wrong type (a bare value instead of a `Future`) and won't compile/match.
- `any()` / `any(named: 'x')` - matches *any* value for that argument. Use
  it when the test doesn't care about the exact argument, only that some
  call happens. Use `named:` for named parameters (`listTasks` uses named
  params, so both `status` and `groupId` need `any(named: '...')` if you're
  not asserting a specific value for them).

**Verifying a call happened** - when the point of the test is "did it call
the service correctly," not just "what did it return":

```dart
verify(() => mockTaskService.deleteTask(id: 'task-1')).called(1);
```

**A gotcha you will hit immediately:** if any mocked method takes an
argument whose type isn't a built-in (like your own `TaskModel`), and you
use `any()` for it, mocktail needs a fallback instance registered once per
type, or it throws at test-run time. Add this in `setUpAll`:

```dart
setUpAll(() {
  registerFallbackValue(TaskModel(title: '', description: '', priority: null, createdAt: DateTime(2026)));
});
```

You'll only need this the first time a test passes a custom type to `any()`
- the error message when it's missing is explicit about which type to
register, so you don't need to pre-guess this.

## 9. `setUp` - avoiding repeated boilerplate

Rather than constructing `MockTaskService()` inside every single `test()`,
`setUp` runs before *each* test in the enclosing `group`, giving every test
a fresh instance:

```dart
void main() {
  late MockTaskService mockTaskService;
  late MockGroupProvider mockGroupProvider;
  late TaskProvider provider;

  setUp(() {
    mockTaskService = MockTaskService();
    mockGroupProvider = MockGroupProvider();
    when(() => mockGroupProvider.activeGroupId).thenReturn('group-1');
    provider = TaskProvider(taskService: mockTaskService, groupProvider: mockGroupProvider);
  });

  // tests go here, each gets a brand-new provider/mocks
}
```

This matters more than it looks: mocks carry state (which stubs are
configured, call counts for `verify`). Reusing one mock across tests means
an earlier test's stubbing can silently leak into a later test. A fresh mock
per test avoids that entirely - always prefer `setUp` over a single
shared mock declared at the top of the file.

---

## 10. Step-by-step: your first mocked test - `task_provider_test.dart`

Target: [lib/features/task/providers/task_provider.dart](../lib/features/task/providers/task_provider.dart).

**Step 1** - imports and the mock declarations:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:manage_app/core/enums/task_enums.dart';
import 'package:manage_app/core/services/task_service.dart';
import 'package:manage_app/features/group/providers/group_provider.dart';
import 'package:manage_app/features/task/models/task_model.dart';
import 'package:manage_app/features/task/providers/task_provider.dart';

class MockTaskService extends Mock implements TaskService {}
class MockGroupProvider extends Mock implements GroupProvider {}
```

**Step 2** - a small helper to build a `TaskModel` without repeating every
field in each test (this is not a mock - just a plain constructor helper for
test data):

```dart
TaskModel _task({
  String id = 't1',
  TaskPriority priority = TaskPriority.medium,
  TaskStatus status = TaskStatus.open,
  DateTime? dueDate,
}) {
  return TaskModel(
    id: id,
    title: 'Task $id',
    description: '',
    priority: priority,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    dueDate: dueDate,
  );
}
```

**Step 3** - `setUp`, then the first test: `loadTasks` populates `tasks` and
manages `isLoading`. Note the test function itself is `async` and the call
is `await`ed - almost everything on `TaskProvider` is asynchronous, and
forgetting `await` is the single most common mistake once you get here (the
test finishes and reports green *before* the async work even runs):

```dart
void main() {
  late MockTaskService mockTaskService;
  late MockGroupProvider mockGroupProvider;
  late TaskProvider provider;

  setUp(() {
    mockTaskService = MockTaskService();
    mockGroupProvider = MockGroupProvider();
    when(() => mockGroupProvider.activeGroupId).thenReturn('group-1');
    provider = TaskProvider(taskService: mockTaskService, groupProvider: mockGroupProvider);
  });

  group('loadTasks', () {
    test('populates tasks and clears isLoading on success', () async {
      when(() => mockTaskService.listTasks(
            status: any(named: 'status'),
            groupId: any(named: 'groupId'),
          )).thenAnswer((_) async => [_task(id: 't1'), _task(id: 't2')]);

      expect(provider.isLoading, isFalse); // hasn't loaded yet

      await provider.loadTasks();

      expect(provider.isLoading, isFalse); // finished loading
      expect(provider.tasks, hasLength(2));
      expect(provider.errorMessage, isNull);
    });

    test('sets errorMessage when the service throws', () async {
      when(() => mockTaskService.listTasks(
            status: any(named: 'status'),
            groupId: any(named: 'groupId'),
          )).thenThrow(TaskServiceException('network error'));

      await provider.loadTasks();

      expect(provider.errorMessage, 'network error');
      expect(provider.tasks, isEmpty);
    });
  });
```

**Step 4** - test the client-side filtering logic. This is the highest-value
part of this file: it's real branching logic (`_matchesClientFilters`,
`_matchesDateFilter`) that's private, so you test it *indirectly* - call the
public setter, then read the public `tasks` getter:

```dart
  group('priority filter', () {
    test('tasks getter only returns tasks matching the priority filter', () async {
      when(() => mockTaskService.listTasks(
            status: any(named: 'status'),
            groupId: any(named: 'groupId'),
          )).thenAnswer((_) async => [
            _task(id: 't1', priority: TaskPriority.high),
            _task(id: 't2', priority: TaskPriority.low),
          ]);
      await provider.loadTasks();

      provider.setPriorityFilter(TaskPriority.high);

      expect(provider.tasks.map((t) => t.id), ['t1']);
    });
  });
```

**Step 5** - test sorting, including the null-handling edge case
(`_compareByDueDate` sends tasks with no due date to the end - that's
exactly the kind of logic that's easy to get backwards and worth locking
down with a test):

```dart
  group('sorting', () {
    test('dueDate sort puts tasks without a due date last', () async {
      when(() => mockTaskService.listTasks(
            status: any(named: 'status'),
            groupId: any(named: 'groupId'),
          )).thenAnswer((_) async => [
            _task(id: 'no-due-date', dueDate: null),
            _task(id: 'due-later', dueDate: DateTime(2026, 3, 1)),
            _task(id: 'due-soon', dueDate: DateTime(2026, 2, 1)),
          ]);
      await provider.loadTasks();

      expect(provider.tasks.map((t) => t.id), ['due-soon', 'due-later', 'no-due-date']);
    });
  });
}
```

Run it: `fvm flutter test test/features/task/providers/task_provider_test.dart`.

---

## 11. Running tests day to day

```bash
# One file - use this constantly while writing/debugging a test
fvm flutter test test/features/task/providers/task_provider_test.dart

# One test by name (substring match) within a file
fvm flutter test test/features/task/providers/task_provider_test.dart --plain-name "dueDate sort"

# Everything - same as CI runs on every PR
fvm flutter test

# With coverage, to see what's still untested
fvm flutter test --coverage
```

## 12. Common pitfalls checklist

- **Missing `await`** on an async call inside a test - the test body
  returns before the real work happens, and the assertion either passes for
  the wrong reason or checks stale state. If a `TaskProvider` method returns
  `Future<...>`, the test calling it must be `async` and use `await`.
- **Sharing one mock instance across tests** instead of recreating it in
  `setUp` - stubs and call counts leak between tests, causing failures that
  only reproduce when tests run in a particular order.
- **`thenReturn` on an async method** - use `thenAnswer((_) async => value)`
  for anything returning `Future<T>`.
- **Testing the private helper directly** - you can't (`_matchesDateFilter`
  isn't visible outside the file), and you shouldn't try to via `@visibleForTesting`
  hacks here - go through the public API (`setDateFilter` + `tasks` getter)
  the same way real callers do. If a public getter can't exercise a branch of
  private logic, that's usually a sign the logic should be a plain top-level
  function instead.
- **One `expect` failure hides the rest** - each `test()` stops at its first
  failed `expect`. Prefer several small, precisely-named tests over one big
  test with ten assertions, so a failure tells you exactly which behavior
  broke without a debugger.

## 13. Quick reference

| Concept | Syntax |
|---|---|
| Define a test | `test('description', () { ... });` |
| Async test | `test('description', () async { await ...; });` |
| Group tests | `group('description', () { test(...); test(...); });` |
| Setup per test | `setUp(() { ... });` |
| One-time setup | `setUpAll(() { ... });` |
| Basic assertion | `expect(actual, expected);` |
| Exception assertion | `expect(() => call(), throwsArgumentError);` |
| Declare a mock | `class MockX extends Mock implements X {}` |
| Stub sync return | `when(() => mock.method()).thenReturn(value);` |
| Stub async return | `when(() => mock.method()).thenAnswer((_) async => value);` |
| Stub a throw | `when(() => mock.method()).thenThrow(SomeException());` |
| Match any argument | `any()` (positional), `any(named: 'x')` (named) |
| Verify a call happened | `verify(() => mock.method(arg)).called(1);` |
| Register a custom-type fallback | `registerFallbackValue(someInstance);` (in `setUpAll`) |
