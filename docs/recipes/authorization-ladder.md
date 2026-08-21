# The authorization ladder

Not all agent actions carry the same risk. Editing a file is recoverable with
`git checkout`. Submitting to the App Store is not. Treating both as "needs
permission" produces a prompt for everything, which trains everyone to click
through — and then the one prompt that mattered gets clicked through too.

So the rungs are separate, and each one is its own decision.

## 1. The rungs

| Rung | Examples | Who decides | Reversible? |
|------|----------|-------------|-------------|
| **1. Edit** | Write code, tests, docs | Agent, freely | Yes — `git checkout` |
| **2. Commit** | `git commit` | Agent, freely | Yes — local history |
| **3. Publish history** | `git push` | **Ask Matt** | Awkward — rewrites are public |
| **4. Build** | `eas build`, `expo prebuild` | **Ask Matt** | Yes, but costs money or credits |
| **5. Upload** | `eas submit`, `store:push`, `web:deploy` | **Ask Matt** | Barely — a build number is consumed |
| **6. Publish to users** | Release in App Store / Play Console | **Matt only, in the console** | No — users have it |

An agent operates freely on rungs 1 and 2. It stops on 3 through 5. It never
touches rung 6 — that one has no CLI in this repo on purpose.

## 2. Why each stop exists

- **Rung 3** is where work becomes visible to anything outside this machine.
- **Rung 4** is the first rung that spends money. EAS credits are real, and a
  loop that retries a build is a loop that spends.
- **Rung 5** consumes a build number and a review slot. Two bad uploads in a day
  is a real cost even though nothing shipped.
- **Rung 6** cannot be undone. A user who downloaded a broken build has it until
  they update.

## 3. What enforces this

Rungs 3 to 5 are matched by `scripts/lib/guard-deploy-match.sh` and surfaced
through the shell hooks, which is why `npm run guard-check` covers 65 cases. That
matcher is a **speed bump for spend, not a security boundary**: it catches the
common command shapes, not every possible wrapper.

The rest is prose in `AGENTS.md` under "Ask before". Prose is enough for a
supervised chat. It is not enough for an unattended loop, which is why an
unattended run has to convert every one of these into a queued item for Matt
rather than an `ask` that nothing answers.

## 4. Adding a rung

New capability that spends money, publishes, or changes identity? Add it to the
matcher **and** to the "Ask before" list, then add a case to
`guard-deploy-match.test.sh` proving it is caught. A rung with no test is a rung
that quietly stops working.

Note that `.cursor/hooks.json`, the guard scripts, and the fail-proof test are
all denied to agents by design. Adding a rung is work for Matt, or a diff Matt
pastes.
