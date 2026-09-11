# Getting the wall reviewed

Step 2 of the procedure is a hard gate: nothing gets built in Kotlin until the
questions are approved. This is how that approval actually happens.

No pull request. The wall goes over as a link, feedback comes back on WhatsApp.

## What you need

- This repo
- Python 3.12 and Pillow (`build_wall.py` needs it for the mascot)
- **Claude Code on your own account**, so you can publish an artifact

The artifact is published from *your* account and shared with Vishnu. It is not
a repo file and it is not on his account.

## The loop

```
you                                          Vishnu
───                                          ──────
1. author / fix the Python
2. re-emit the JSON
3. run every check until green
4. python build_wall.py
5. publish → share the link      ────────▶   6. opens the wall
                                             7. ticks the questions to change
                                             8. types a note on each
                                             9. "Copy notes for Claude"
   11. paste into your Claude    ◀────────   10. pastes into WhatsApp
   12. back to 1
```

Repeat until he says approved. Then, and only then, step 3 of the build guide.

## Publishing it the first time

```bash
cd brainpass/tools/curriculum
python build_wall.py
```

It writes `brainpass/build/wall/question_wall.html`. Ask your Claude session to
publish that file as an artifact, then send Vishnu the link.

The page is fully self-contained — the question data is spliced in at build time
and the mascot is inlined — so it has no network dependency and nothing to
break once published.

## Republishing — the part that matters

**Every later round must go to the SAME artifact, not a new one.**

Publish a second artifact and he gets a second link, and neither of you can tell
which version he approved. In Claude Code:

- Same session: publishing the same file path again redeploys to the same URL.
- New session: give Claude the artifact's URL and say to update that one.
  Without the URL it will create a separate artifact.

Then just message him "updated" — the link he already has now shows the new
version.

## What he sends back

The wall's basket produces a block like this, and it is what lands in WhatsApp:

```
Questions to change:

1.1.1#0 (predict, coder) — Nupo does these steps. Tap the square he ends on.
    change: grid is too busy, drop to 4x4

2.3.1#4 (count, number) — How many stars? Tap the number.
    change: (not said)
```

The `1.1.1#0` part is `stop id` + `#` + the question's index within that stop,
so there is never any doubt which question is meant. Paste the whole block
straight into your Claude session — it identifies each question exactly.

`(not said)` means he ticked it but did not type a note. Ask rather than guess.

## Tell him this before his first review

**The basket does not survive a closed tab.** Picks and notes are held in
memory only — no autosave. Closing or reloading the wall loses the lot, which
across 648 questions is a genuinely painful way to lose an hour.

So: review in batches, and hit **Copy notes for Claude** and paste somewhere
safe every twenty or so questions rather than once at the very end.

If that turns out to be annoying in practice, say so — the wall can be rebuilt
to save review state properly, so his picks persist and you both see them. It
is real work, not a setting, so it is worth doing only if the simple loop hurts.

## Before you depend on any of this

Publish a throwaway page from your account and share it with Vishnu, and have
him confirm he can actually open it. Sharing between two accounts can be limited
by an organization boundary, and it is better to find that out now than halfway
through a review round.

## While you are waiting

Approval blocks Kotlin, not everything. Good use of the wait:

- get the checks green and keep them green
- read `tools/curriculum/README.md` properly
- get the phone set up and drive an existing skill end to end, so you learn the
  device workflow on content that already works
- prototype one hard drawing — for band D, one of the 3D views
