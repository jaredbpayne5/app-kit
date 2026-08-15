Start watching the mailbox.

Do these steps and nothing else. Do not read the mailbox, do not touch any other
file, do not summarise the repo.

1. If `.ai/current-task.md` does not exist, create it by copying
   `.ai/current-task.template.md`.
2. If `.ai/mailbox-state.json` does not exist, create it containing exactly:

   ```json
   {
     "seq": 0,
     "owner": "none",
     "status": "idle",
     "mode": "none",
     "updated": "—"
   }
   ```

3. Create an empty file at `.ai/.watching`.
4. Stop.

Steps 1 and 2 only matter in a fresh clone — those two files are gitignored, so
a clone arrives with only the blank master copy. If they already exist, leave
them exactly as they are. Never overwrite a live mailbox.

Once you stop, the `stop` hook (`.cursor/hooks/wait-for-mail.sh`) takes over and
waits for Claude to hand over a task. Waiting is done by a sleeping shell
script, so it costs nothing until real mail arrives.

When mail lands you will be handed the task automatically. Follow
`.cursor/skills/mailbox/SKILL.md`, then carry it out as written, honouring
`AGENTS.md` and the Mode set in the mailbox. Fill in the Implementation
report, set Owner to `claude` and Status to `ready-for-review`, and stop.
