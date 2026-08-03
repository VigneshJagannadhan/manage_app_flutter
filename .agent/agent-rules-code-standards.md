# Agent Rules - Code Standards

This file is a living document. It will be updated during development as new
standards and conventions are agreed upon. Keep it open to editing.

> Note: The user's global CLAUDE.md designates `AGENTS.md` as the canonical
> code standard. This file does not exist yet in this repo. Until it does,
> this file (`agent-rules-code-standards.md`) is the standards reference for
> this project - reconcile the two if/when `AGENTS.md` is added.

---

## 1. Coding Best Practices

Follow all standard coding best practices strictly, including:

- **SOLID**
  - Single Responsibility - a class/widget should have one reason to change.
  - Open/Closed - extend behaviour without modifying existing working code.
  - Liskov Substitution - subtypes must be usable wherever the base type is expected.
  - Interface Segregation - don't force classes to depend on methods they don't use.
  - Dependency Inversion - depend on abstractions, not concrete implementations.
- **DRY** (Don't Repeat Yourself) - no duplicated logic or widget trees.
- **KISS** (Keep It Simple, Stupid) - prefer the simplest solution that works.
- **YAGNI** (You Aren't Gonna Need It) - don't build for hypothetical future requirements.

Flag any violation of these principles found during evaluations, with a suggested fix.

---

## 2. Structure & Naming

Flag any of the following if seen during evaluations, even if unrelated to the
current ticket:

- Folder structure issues (files in the wrong layer/feature folder).
- Naming issues - files, classes, variables, methods not following consistent
  conventions.
- Anything unusual, inconsistent, or out of place vs. the rest of the codebase.

---

## 3. Widget Reuse

- Always reuse existing custom widgets instead of rewriting UI.
- If the same UI/logic block appears more than once (2+ times), extract it into
  a reusable widget instead of duplicating it.

(See also: global CLAUDE.md widget rules - use `PrimaryButton` over `AppButton`,
wrap `PrimaryButton`s with accessibility, never use `GestureDetector` - flag if found.)

---

## 4. File Size & Organization

- Don't let files grow too long - split into separate files when a file is
  doing too much.
- **One file, one widget.** Private widgets (prefixed `_`) used only within
  that file are fine and don't need to be split out.

---

## 5. Layer Separation

Keep **data**, **business logic**, and **presentation** layers strictly
separate:

- Data layer: models, API/DB access, repositories.
- Business layer: state management, use cases, services.
- Presentation layer: screens, widgets, UI-only logic.

Flag any violation where these layers are mixed (e.g. API calls inside a
widget's `build` method, business logic embedded in UI code).
