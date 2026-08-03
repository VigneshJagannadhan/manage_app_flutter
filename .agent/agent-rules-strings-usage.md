# Agent Rules: String Usage

**Version:** 1.0
**Status:** Active
**Purpose:** Guidelines for all agents working with user-facing strings in screens/widgets.

---

## Core Rules

1. Strings must never be hardcoded in screens (or any widget/presentation code).
2. Every user-facing string must exist in `AppStrings`
   ([lib/core/resources/app_strings.dart](../lib/core/resources/app_strings.dart)).
3. Usage at the call site must be `AppStrings.name` - never an inline string literal.
4. When a hardcoded or inline string is found:
   - Check if an equivalent entry already exists in `AppStrings` - if yes, reuse it.
   - If not, create a new `static const String` entry in `AppStrings` and reference
     it via `AppStrings.name`.

---

## What counts as a violation

```dart
// ❌ WRONG - inline string literal in a screen/widget
Text('Task Details')

// ✅ CORRECT - sourced from AppStrings
Text(AppStrings.taskDetails)
```

This applies to any user-visible text: `Text` widgets, `AppBar` titles, button
labels, dialog/snackbar messages, tooltips, hints, empty-state copy, etc.

---

## What is exempt

- Non-visible technical strings: keys, route names, asset paths, enum-like
  identifiers, log messages, map/JSON keys.
- Debug-only output (e.g. `debugPrint`, `print`).

If unsure whether a string is user-facing, flag it during review rather than
silently leaving it hardcoded.

---

## Naming Convention

- `camelCase`, matching the existing entries in `AppStrings`
  (e.g. `taskDetails`, `noDueDate`).
- Name should describe the string's meaning/purpose, not its screen location
  (e.g. `closeTask`, not `taskDetailsScreenCloseButtonLabel`).
- Reuse an existing entry whenever the text is identical rather than creating
  a near-duplicate.

---

## Review Checklist

- [ ] No inline string literals in `Text`/label/message widgets.
- [ ] Every such string resolves to `AppStrings.<name>`.
- [ ] No duplicate entries added to `AppStrings` for text that already exists.
- [ ] New entries follow the naming convention above.
