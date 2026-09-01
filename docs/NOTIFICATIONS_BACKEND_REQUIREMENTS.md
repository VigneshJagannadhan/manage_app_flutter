# Notifications API — Backend Requirements

## Overview

The Huddle mobile app is adding reminder notifications for four categories: **journal** (write today's entry), **task** (a task is due), **expense** (log today's spending), and **general** (catch-all/announcement style).

The design is **pull, not push**: there is no APNs/FCM integration on the client. Instead, the app periodically calls `GET /notifications/schedule` and turns whatever comes back into local device notifications. This means:

- The backend is the single source of truth for **whether** and **when** each reminder fires — e.g. "has this user already written a journal entry today?", "has this user already logged an expense today?", "is this task's `dueDate` coming up?". The client does none of that logic; it only displays what it's told.
- There is no delivery guarantee if the app isn't opened — the client fetches on app launch and app resume only. This is an accepted tradeoff, not something to fix server-side (e.g. no need to build actual push delivery).
- Every reminder a user could receive is gated by a per-category on/off switch (and, for journal/expense, a preferred time of day) that the user sets in-app. The backend must respect these when building the response to `GET /notifications/schedule` — a disabled category's items must be **excluded from the response entirely**, not included with some "muted" flag.

## Auth

Same Bearer-token auth as every other endpoint in this API (`Authorization: Bearer <accessToken>`).

## Endpoint 1 — `GET /notifications/schedule`

Returns the reminders currently due for the authenticated user, already filtered by their preferences (Endpoint 2).

### Response

```json
{
  "notifications": [
    {
      "id": "journal-2026-08-27",
      "type": "journal",
      "title": "Don't forget to journal today",
      "body": "A couple of lines about your day goes a long way.",
      "scheduledAt": "2026-08-27T20:00:00Z",
      "data": {}
    },
    {
      "id": "task-6512f.-due",
      "type": "task",
      "title": "Task due soon: Buy groceries",
      "body": "Due today at 6:00 PM",
      "scheduledAt": "2026-08-27T18:00:00Z",
      "data": { "taskId": "6512f...", "groupId": "64f01..." }
    }
  ]
}
```

### Field notes

- **`id`** (string, required) — must be **stable** for the same logical reminder across repeated calls (e.g. `"journal-<date>"`, `"expense-<date>"`, `"task-<taskId>-due"`). The client re-fetches and reschedules from scratch on every app launch/resume, and relies on this id staying the same to avoid showing duplicate notifications for the same underlying reminder.
- **`type`** (string, required) — one of `"journal" | "task" | "expense" | "general"`.
- **`title` / `body`** (strings, required) — shown verbatim in the device notification.
- **`scheduledAt`** (ISO 8601 UTC timestamp, required) — when the client should fire this locally. If it's already in the past by the time the client processes the response, the client just skips it (won't show a stale notification), so it's fine for this to occasionally be in the near past due to fetch timing.
- **`data`** (object, required, may be empty) — free-form, used only for tapping through to the right screen in-app:
  - `type: "task"` → `{ "taskId": "...", "groupId"?: "..." }` (`taskId` required)
  - `type: "expense"` → `{ "expenseId": "...", "groupId"?: "..." }` (`expenseId` required)
  - `type: "journal"` → `{ "date"?: "2026-08-27" }` (optional; client defaults to today if absent)
  - `type: "general"` → no required fields; client just opens the home screen on tap.

### Behavior requirements

1. Only include a category's items if that category's toggle is currently `true` per Endpoint 2's stored preferences for this user.
2. For `journal`/`expense`: only include today's reminder if the user hasn't already journaled / logged an expense today, and only once it's at or past their configured `journalReminderTime`/`expenseReminderTime` (see Endpoint 2). If they've already done the thing today, omit it — don't send a reminder for something already done.
3. For `task`: include one entry per task with an upcoming/overdue `dueDate` assigned to (or visible to) this user, per whatever due-soon window the backend considers appropriate (e.g. due within the next 24h, or already overdue and still open). Exclude completed/deleted tasks.
4. For `general`: entirely at the backend's discretion — no specific behavior required by the client, just the shape above.

## Endpoint 2 — `GET` / `PATCH /notifications/preferences`

Stores per-user notification category preferences. `PATCH` is a **partial patch** — only include the fields being changed in the request body; unspecified fields are left unchanged.

### Shape (same for `GET` response and `PATCH` request body)

```json
{
  "generalRemindersEnabled": true,
  "journalReminderEnabled": true,
  "taskReminderEnabled": true,
  "expenseReminderEnabled": true,
  "journalReminderTime": "20:00",
  "expenseReminderTime": "21:00"
}
```

- `generalRemindersEnabled`, `journalReminderEnabled`, `taskReminderEnabled`, `expenseReminderEnabled` — booleans.
- `journalReminderTime`, `expenseReminderTime` — nullable strings, `"HH:mm"` 24-hour format, the user's preferred local time for that day's reminder. There is no equivalent time field for `task` (due-date-driven, not time-of-day) or `general` (ad hoc, not scheduled to a fixed daily time) — don't add one.

### Defaults for a new user (no row yet)

All four booleans default to `true`; `journalReminderTime` defaults to `"20:00"`, `expenseReminderTime` defaults to `"21:00"`.

## Open questions for the backend implementer

These are intentionally left for the backend team to decide — the client doesn't need a specific answer, just needs the response shapes above to stay stable:

1. **Timezone handling** for `journalReminderTime`/`expenseReminderTime` — these are entered as local wall-clock time on the device. Decide whether to store the user's IANA timezone (e.g. captured at preference-update time, or from profile/locale data already on file) or handle it another way. This affects when "today" starts/ends for the "already done today?" check too.
2. **Look-ahead window** for `GET /notifications/schedule` — e.g. "everything due in the next 24h" vs. a longer window. Since the client discards and reschedules on every fetch, a short window (next 24-48h) is simplest and keeps responses small; a longer window is also fine as long as `scheduledAt` timestamps stay correct.
3. **Content** of `general` reminders — what triggers one, what it says. No client behavior depends on the specifics.
