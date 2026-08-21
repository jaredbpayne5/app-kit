---
name: app-review
description: "Reviews an implementation change without editing it, or the whole app at the release gate. Starts from docs/PRD.md, the job's AC/INV, and the diff — not CONTRACT.md compliance. Claude only. Use for code, PR, diff, branch, job, or whole-app reviews."
user-invocable: true
argument-hint: "[job N, diff, branch, commit, PR, or whole-app]"
---

# Review

Claude only. Review builder code. Stay read-only except one write: on
`PASS` for a job, check that job's box in `docs/BACKLOG.md`.

This chat must not have written the code. If it did, stop and say independent
review is blocked. A new thinker chat should run `/app-review`.

Do not tell anyone to open a Cursor skill file. This playbook is complete.

## Scope

Review the implementation target named by the user. It may be a job in
`docs/BACKLOG.md`, a file, diff, branch, commit, pull request, or the whole
app at the release gate.

If the user does not name a target, review `git diff main...HEAD` plus staged,
unstaged, and untracked files on the current branch. If there are no local
changes, say so instead of substituting a whole-repository audit.

Use Cursor `/app-critic` for `docs/PRD.md` or `docs/CONTRACT.md` that has not been
implemented. This skill reviews code.

## Standard

Start from `docs/PRD.md`, the job's `AC-n`/`INV-n`, and the diff. The
question is *would the user succeed?* — not *does this match my
`docs/CONTRACT.md`*. Contract-compliance is a secondary check, not the
standard. If the implementation satisfies the contract but the user would
still fail, that is `FAIL` and a contract reopen.

Approve only when:

- The user can accomplish the PRD outcome this job claims to deliver.
- Cited `AC-n` / `INV-n` hold.
- No known defect or unhandled risk could break the source or `AGENTS.md`
  rules for security, data loss, compatibility, or operations.

Do not demand perfection or block on personal taste. Cite technical evidence
or repository conventions.

The verdict is independent agent evidence. It is not GitHub approval.

## Review order

1. **Set the frame.** Give yourself `docs/PRD.md`, the job's `AC-n` /
   `INV-n` IDs, `AGENTS.md` rules, the complete diff, and test evidence.
   Name the user affected.
2. **Take the broad view.** Confirm the change belongs in the system, matches
   the intended behavior, and delivers one reviewable outcome. Report a
   mismatch before reviewing details.
3. **Review the main behavior.** Start with the files and flows that deliver
   the outcome. Check behavior, failures, security boundaries, interfaces,
   compatibility, and operations.
4. **Review every human-written changed line in context.** Read enough
   surrounding code to judge correctness, regressions, complexity, names,
   comments, style, and docs. Keep findings within the change's scope.
5. **Check this repo's gates.** Seams in `AGENTS.md` were used. No hardcoded
   hex or `text-[15px]`. No new screen without a named export and
   `app-pull-design`. No secrets. No backend, accounts, or server-side sync.
6. **Review the proof.** Check that tests:
   - Cover the changed behavior and affected failure paths.
   - Match the tier the job's `Tests:` field declared. A job that says `flow`
     needs a Maestro run, and a `--allow-skip` run does not count.
   - Prove every cited `AC-n`, `INV-n`, or job criterion.
   - Assert behavior a user or caller can observe, or a documented contract.
   - Would fail under a broken implementation.
7. **Check the receipt.** Run `npm run receipt:check -- --command=verify`. A
   receipt is written as the last step of the `verify` chain, so it is reached
   only if every earlier check exited 0, and it carries the commit it ran
   against. It is a claim with a commit attached, not proof against a
   deliberate forge — anything that can run shell can write a file. Report what
   it says:
   - No receipt for `HEAD`, or a receipt from an older commit: the "checks
     pass" claim is unproven. Say so in the findings rather than assuming
     either outcome.
   - A dirty tree, then or now: the commit does not describe what was
     verified.

   A missing receipt is not automatically `FAIL` — you may run the checks
   yourself instead. What is not allowed is taking the claim on trust.
8. Run focused checks that can confirm or disprove a claim that could change
   a finding or verdict (`npm run check`, `npm test`). Do not pipe to `tail`.
9. **Report findings.** Return actionable findings in priority order.

## Whole-app target (release gate)

When the user asks for a whole-app review, also check:

- **Product fit.** Does the shipped app match the PRD outcomes? Report
  drift. After first store ship, do not demand a revert of a correct fix
  to satisfy a stale doc — report the drift.
- **Architecture.** Coherence, unnecessary complexity, dead code.
- **Authority.** No backend, accounts, or server-side sync unless Matt
  already approved that stop-and-discuss. Seams in `AGENTS.md` are used.
  No new screen without a named export.
- **Security.** No secrets in source, commits, or `EXPO_PUBLIC_*`. No
  logged tokens, keys, or receipts. On-device data stays on-device unless
  the product added a network feature.

Store-readiness is `npm run preflight` and `/app-ship`, not this skill.
Runtime abuse is Cursor `/app-harden`. You may list simplify work;
Grok performs the edits. Do not gain app-write authority here.

## Code review findings

Report only real bugs, user-impacting issues, and proven simplifications
introduced or exposed by the change. A simplification must deliver the same
outcome and proof with less state, indirection, duplication, or operational
work. Report it only as `Could fix`.

Use this format for every finding:

```text
Priority: Must fix / Should fix / Could fix
Confidence: 0–5
What I found: Describe the technical problem.
Why it matters: Explain the impact on users or callers.
ELI5: In one or two short sentences, state the exact condition that triggers the problem and what the user experiences. Use no analogies, jargon, or acronyms.
Where: File and line.
Suggested fix: Give a short, practical direction.
```

Priority means:

- **Must fix:** Unsafe to merge. Security failure, data loss, broken required
  behavior, or a serious regression.
- **Should fix:** A real defect or reliability risk that should be corrected
  before merge.
- **Could fix:** A proven, limited problem or simplification that does not
  need to block merge. Do not use this for style preferences.

Confidence means:

- **5:** Confirmed by reproduction, test, or direct code evidence.
- **4:** Strong evidence with no credible alternative explanation.
- **3:** Probable, but some runtime evidence is unavailable.
- **0–2:** Do not report. Investigate further or mark the area unverified.

## Verdict

Use exactly `PASS`, `FAIL`, or `BLOCKED`.

- `PASS`: no Must fix or Should fix findings remain. For a job, check
  its box in `docs/BACKLOG.md`. A checked box means built and reviewed.
- `FAIL`: a Must fix or Should fix finding remains. Name the fixes.
  Next skill is builder `/app-code` on those fixes. Do not check the box.
- `BLOCKED`: missing required context, specialist coverage, or this chat
  wrote the code.

Could fix findings do not prevent `PASS`. State what remains unverified.
Do not approve solely because checks pass.

## Boundaries

- Keep findings within the change, but inspect enough surrounding code to
  judge each changed line.
- Do not turn preferences into findings.
- Do not implement the fix in this chat.
