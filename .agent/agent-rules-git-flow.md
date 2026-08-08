# Agent Rules: Git Flow

**Version:** 1.0
**Status:** Active
**Purpose:** How agents commit, branch, and push on this project

---

## Trigger

These rules only fire when the user says **"Let's push this change"** (or a clear
equivalent). Do not commit, branch, or push proactively - not after finishing an
implementation, not after the user says "looks good," and not because a plan was
approved. Wait for the explicit trigger phrase.

Giving a commit message on request (e.g. "commit message") is a text answer, not
an instruction to run `git commit`. Never commit as a side effect of being asked
what the message should be.

---

## Step 1: Classify the change

Look at the staged/unstaged diff (`git status`, `git diff`) and classify it as one
of the [Conventional Commits](https://www.conventionalcommits.org/) types:

| Type       | When                                                         |
|------------|--------------------------------------------------------------|
| `feat`     | New user-facing capability or behavior                       |
| `fix`      | Bug fix                                                       |
| `refactor` | Restructuring with no behavior change                        |
| `chore`    | Tooling, deps, config, CI - no app behavior change            |
| `docs`     | Documentation only                                            |
| `style`    | Formatting only, no logic change                              |
| `test`     | Test-only changes                                             |

If the diff mixes types, classify by the dominant/primary intent of the change.

---

## Step 2: Write the commit message

**Format:** `<type>: <short summary>`

```
feat: auto scrolling on keyboard open
fix: prevent keyboard overflow on sign-in screen
refactor: extract scrollable body from AppScaffold
```

Rules:
- One line only. **No body, no description, no bullet points.**
- Lowercase summary, imperative mood, no trailing period.
- **Never** add a `Co-Authored-By: Claude` (or any AI attribution) trailer.
- Never add PR/task boilerplate ("Generated with...", tool links, etc).

---

## Step 3: Determine the branch name

Check whether the user's request references a ticket number (e.g. "P#1234",
"JIRA-1234", "#1234", or similar mentioned in conversation).

- **Ticket number present:** `P#<ticket-number>/<kebab-case-summary>`
  e.g. `P#1234/auto-scroll-on-keyboard-open`
- **No ticket number:** `P#0000/<kebab-case-summary>`
  e.g. `P#0000/auto-scroll-on-keyboard-open`

The `<kebab-case-summary>` is a short slug of the change (same intent as the
commit summary, kebab-cased).

---

## Step 4: Branch, commit, push

1. **Never commit directly to `main`.** If currently on `main`, create and switch
   to the branch from Step 3 before committing:
   ```
   git checkout -b P#0000/auto-scroll-on-keyboard-open
   ```
2. Commit with the Step 2 message.
3. Push to remote (set upstream on first push):
   ```
   git push -u origin <branch-name>
   ```

If already on a non-`main` feature branch when triggered, commit and push to
that branch directly - don't create a new one unless the user asks.

---

## Quick Checklist

- [ ] Triggered by "Let's push this change" (or equivalent), not inferred
- [ ] Change classified as feat/fix/refactor/chore/docs/style/test
- [ ] Commit message is `type: summary` only - no body, no Co-Authored-By
- [ ] Branch name is `P#<ticket>/<slug>` (ticket number if known, else `0000`)
- [ ] Never committed to `main`
- [ ] Pushed to remote after committing
