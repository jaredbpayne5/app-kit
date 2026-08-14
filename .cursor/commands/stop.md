Stop watching the mailbox.

Delete the file `.ai/.watching` if it exists, then stop. Do nothing else.

This is the off switch. It also works while the watcher is mid-wait: the
waiting script checks for this file on every pass and stands down as soon as it
disappears.
