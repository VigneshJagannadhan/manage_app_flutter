# Agent Rules: Git Flow

**Version:** 1.0
**Status:** Active
**Purpose:** How agents commit, branch, and push on this project

---

## Trigger

These rules only fire when the user says **"Let's push this change"** (or a clear
equivalent), or one of the explicit shorthand triggers below. Do not commit,
branch, or push proactively - not after finishing an implementation, not after
the user says "looks good," and not because a plan was approved. Wait for the
explicit trigger phrase.

Giving a commit message on request (e.g. "commit message") is a text answer, not
an instruction to run `git commit`. Never commit as a side effect of being asked
what the message should be.

**Shorthand triggers** - these mean commit, push, and open a PR, and also pin
the PR's target branch:
- **"PR -dev"** → commit, push, and open a PR into `dev`.
- **"PR -main"** → commit, push, and open a PR into `main` (still from the
  current feature/fix branch, same mechanics as `-dev`, just a different
  base - used to trigger a build).

If the user says "Let's push this change" without `-dev`/`-main`, default the
PR target to `dev` (Step 5). Normal feature/bugfix work merges into `dev`;
`main` is only targeted when the intent is to trigger a build.

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

- **Ticket number present:** `<ticket-number>/<kebab-case-summary>`
  e.g. `TAS-1234/auto-scroll-on-keyboard-open`
- **No ticket number:** `<type>/<kebab-case-summary>`, using the same
  Conventional Commits type classified in Step 1.
  e.g. `feat/auto-scroll-on-keyboard-open`, `fix/prevent-keyboard-overflow`,
  `docs/update-readme-setup`

The `<kebab-case-summary>` is a short slug of the change (same intent as the
commit summary, kebab-cased).

---

## Step 4: Branch, commit, push

1. **Never commit directly to `main` or `dev`.** If currently on `main` or
   `dev`, pull latest `dev` first so the new branch starts from up-to-date
   code, then create and switch to the branch from Step 3:
   ```
   git checkout dev
   git pull origin dev
   git checkout -b feat/auto-scroll-on-keyboard-open
   ```
2. Commit with the Step 2 message.
3. Push to remote (set upstream on first push):
   ```
   git push -u origin <branch-name>
   ```

If already on a non-`main`, non-`dev` feature branch when triggered, commit
and push to that branch directly - don't create a new one unless the user
asks. This applies regardless of whether the PR target is `dev` or `main`.

---

## Step 5: Open a PR

Determine the PR base branch from the trigger: `main` if triggered by
**"PR -main"**, otherwise `dev` (default, including plain "Let's push this
change" and **"PR -dev"**).

After pushing, open a pull request into that base branch:
```
gh pr create --base <dev|main> --head <branch-name> --title "<commit message>" --body "<body>"
```
- Title: same as the Step 2 commit message.
- Body: one or two bullet points summarizing the change. If the branch has a
  real ticket number, reference it in the body.
- If a PR already exists for the branch (continuing prior work), skip this -
  just push, don't try to create a duplicate.
- Creation only - never merge the PR.

If the branch has a real ticket number, transition that ticket to
**Resolved** right after the PR is opened (look up the transition ID via
`getTransitionsForJiraIssue` rather than assuming it - transition IDs are
workflow-specific). Skip this for ticketless (`<type>/...`) branches, since
there's no ticket to transition.

After opening the PR (and transitioning the ticket, if applicable), switch
back to `dev`:
```
git checkout dev
```

---

## Quick Checklist

- [ ] Triggered by "Let's push this change", "PR -dev", "PR -main" (or
      equivalent), not inferred
- [ ] Change classified as feat/fix/refactor/chore/docs/style/test
- [ ] Commit message is `type: summary` only - no body, no Co-Authored-By
- [ ] Branch name is `<ticket>/<slug>` if a ticket is known, else
      `<type>/<slug>`
- [ ] Pulled latest `dev` before branching off it
- [ ] Never committed to `main` or `dev`
- [ ] Pushed to remote after committing
- [ ] PR opened into `main` (if "PR -main") or `dev` (default / "PR -dev"),
      skipped only if one already existed
- [ ] Ticket transitioned to Resolved (skipped only for ticketless branches)
- [ ] Back on `dev` after opening the PR
