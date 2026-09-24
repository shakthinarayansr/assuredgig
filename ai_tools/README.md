# ai_tools

Where the *thinking* around this codebase lives, so it stops evaporating between
sessions. `CLAUDE.md` holds standing context and settled decisions; the
BRD/PRD/TRD hold the product contract. This folder holds everything in motion:
what we noticed, what we suggested, what we got wrong, and what we agreed.

It exists because the expensive knowledge in this project is not the code. It is
the thirty seconds it took to discover that the OTP verify endpoint answers 422
and not 400 — a fact that costs nothing to write down and half an hour to
rediscover.

## The five folders

| Folder | Holds | Enters when | Leaves when |
|---|---|---|---|
| `proposals/` | Suggestions raised during dev, not yet agreed | Anyone — human or Claude — proposes something beyond the task at hand | Approved → `memory/` · Rejected → `archives/` |
| `memory/` | Approved decisions and their reasons | A proposal is approved, or a decision is made directly | Superseded → `archives/` |
| `reasoning/` | Mistakes and corrections found by testing against real data | Reality disagrees with what we assumed | Never — a correction stays true even when the code moves on |
| `skills/` | Approved, repeatable procedures for this project | A way of working proves itself and is approved | Superseded → `archives/` |
| `archives/` | Superseded and rejected entries, kept whole | Anything leaves the folders above | Never |

Nothing is ever deleted. An entry moves, and its `status` and `superseded_by`
say what happened to it. A rejected proposal is as useful as an approved one —
it is the record of a path we chose not to take, and the reason.

## The flow

```
        suggestion
             │
             ▼
      ┌─────────────┐   approved    ┌──────────┐  superseded  ┌────────────┐
      │  proposals  │──────────────▶│  memory  │─────────────▶│  archives  │
      └─────────────┘               └──────────┘              └────────────┘
             │                            │                          ▲
             │ rejected                   │ proves repeatable        │
             └────────────────────────────┼──────────────────────────┘
                                          ▼
                                    ┌──────────┐
                                    │  skills  │
                                    └──────────┘

      testing against real data ──▶ reasoning/   (one way, never leaves)
```

**Why `reasoning/` is one-way.** The other folders track *intent*, which changes.
`reasoning/` tracks *what happened when we ran it* — and that stays true. When
the backend starts distinguishing an expired code from a wrong one, the entry
saying it once did not is still an accurate record of why the client was built
to conflate them.

## Writing an entry

Copy the folder's `_TEMPLATE.md`, name it `YYYY-MM-DD-short-slug.md`.

Dates, not sequence numbers: two people adding entries on branches never collide,
and chronology is the useful ordering anyway.

Every entry carries frontmatter. `status` is the field the whole system runs on:

| Folder | Valid `status` |
|---|---|
| `proposals/` | `open` · `approved` · `rejected` · `deferred` |
| `memory/` | `active` · `superseded` |
| `reasoning/` | `confirmed` (reproduced) · `suspected` (seen once) |
| `skills/` | `active` · `draft` · `retired` |
| `archives/` | `rejected` · `superseded` |

Keep entries short. An entry nobody reads is worth less than no entry, and the
value is in the *why* — the code already says what.

Link entries with plain relative markdown links. A proposal that came out of a
correction should link the `reasoning/` entry that produced it; that pairing is
the most useful thing in here.

## Seeing where everything stands

```sh
./ai_tools/status.sh            # everything, grouped by folder and status
./ai_tools/status.sh open       # just the open proposals
```

There is no hand-maintained index, deliberately. An index is a file that goes
stale silently; the script reads the frontmatter and cannot.

## Skills are symlinked into `.claude/`

Claude Code only discovers project skills in `.claude/skills/`. The source of
truth lives here, in `ai_tools/skills/`, and `.claude/skills/<name>` is a
symlink to it. Both are committed, so a clone gets working skills and the whole
system stays under one folder.

Adding an approved skill:

```sh
mkdir -p ai_tools/skills/<name>              # write SKILL.md inside it
ln -s ../../ai_tools/skills/<name> .claude/skills/<name>
```

## For Claude, in a future session

Read `ai_tools/memory/` and `ai_tools/reasoning/` before proposing architecture
or touching the API layer — between them they hold the decisions and the
hard-won facts about how this specific backend actually behaves.

Do not move an entry out of `proposals/` on your own judgment. Proposing is
yours; approving is the user's.
