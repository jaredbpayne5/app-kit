Start watching the mailbox.

Create an empty file at `.ai/.watching`, then stop. Do nothing else — do not
read the mailbox, do not touch any other file, do not summarise the repo.

Once you stop, the `stop` hook (`.cursor/hooks/wait-for-mail.sh`) takes over and
waits for Claude to hand over a task. Waiting is done by a sleeping shell
script, so it costs nothing until real mail arrives.

When mail lands you will be handed the task automatically. Carry it out as
written, honouring `AGENTS.md` and the Mode set in the mailbox, then fill in the
Implementation report, set Owner to `claude` and Status to `ready-for-review`,
and stop.
