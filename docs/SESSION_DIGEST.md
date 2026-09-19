SESSION DIGEST EXTRACTION — ASCEND (READ-ONLY, NO REPO EDITS)

Do NOT fetch or edit any repo files and do NOT write doc updates. Your only job is to review THIS ENTIRE chat thread and produce one compact, self-contained Session Digest that I will feed into a later consolidation prompt.

Session number: <<N>> | Date(s) of this chat: <<YYYY-MM-DD or "unknown">> | AI tool: <<Claude / ChatGPT / Gemini>>

RULES
1. Tag every bullet with exactly one confidence tag:
   [DEV-CONFIRMED] = I explicitly approved, applied, or stated it in this chat
   [VERIFIED] = a repo file was actually fetched or pasted in this chat and the fact comes from it
   [PROPOSED] = you suggested it; I never confirmed it was applied
   [UNCERTAIN] = ambiguous; say what is unclear
   Never upgrade PROPOSED to DEV-CONFIRMED. Code or docs you wrote count as PROPOSED unless I said I applied them.
2. Do not invent anything. Use exact file paths, names, keybinds, and numbers when they were discussed.
3. Bullets only, about 500 words maximum.
4. If the thread is too long to review reliably, say so and list which parts you may have missed.

OUTPUT EXACTLY THIS STRUCTURE
## SESSION DIGEST #<<N>> — <<date>> — Roles used: <...>
### A. Applied changes (only what I confirmed applied)
### B. Decisions and scope calls (include deferred or cut features, with a one-line rationale)
### C. Bugs / contradictions discovered (file or section, plus evidence)
### D. Designs or code proposed but NOT confirmed applied
### E. Doc corrections needed (doc name, old text -> new text)
### F. Open items / unresolved questions
### G. Files read or referenced (mark which were actually fetched)
### H. Claims in existing docs that I said are inaccurate


MULTI-SESSION CATCH-UP DOCS SYNC — ASCEND

I ran <<N>> separate sessions without a docs sync. Below are <<N>> Session Digests, oldest first, followed by my standard Session-End Docs Sync prompt. Follow the standard prompt exactly, EXCEPT wherever it says "this chat thread", that means "the Session Digests". The digests are the only record of those sessions.

STEP 0: Fetch the current raw content of every file the standard prompt lists. If you cannot browse, stop and ask me to paste them.

STEP 1: RECONCILIATION REPORT (output this first, before any file)
- Timeline: one line per session, ordered by date (by session number if a date is unknown).
- Conflicts: where digests disagree, the later [DEV-CONFIRMED] item wins. Show the earlier and later items side by side and flag them as a correction.
- Contradictions I have not resolved: mark them [NEEDS CONFIRMATION: ...] and do not pick a side.
- Duplicates: merge them and note it.
- Superseded open items: an item that a later session resolved must not stay open.
- [PROPOSED] and [UNCERTAIN] items never become facts. They may appear only in NEXT_STEPS or Open Items, labeled as proposed.

STEP 2: APPEND-ONLY FILES
- CHANGELOG.md and DECISIONS.md get one entry per session, dated with that session's date, labeled "(backfilled from Session Digest #n)". Use [DATE UNKNOWN] if no date was given. Only [DEV-CONFIRMED] and [VERIFIED] items count as changes or decisions.
- Never delete or rewrite existing entries.

STEP 3: REPLACE FILES (CURRENT_TASK, NEXT_STEPS, PROJECT_STATUS)
- Build each from the union of all digests, not just the latest one.
- Before each REPLACE, output a "Dropped Content Report": anything in the old file that is not carried over, and where it went (CHANGELOG entry, or intentionally discarded and why). Nothing should disappear without an entry.
- PROJECT_STATUS: one snapshot, no completion percentage unless I confirm one.

STEP 4: SURGICAL DOC EDITS
- Contradictions to existing docs are shown as old line and new line, flagged as corrections. Brand-new information goes in the most logical existing section.

STEP 5: OUTPUT IN BATCHES
- Batch 1: Reconciliation Report plus the .ai/ files.
- Batch 2: the docs/ files.
- Wait for me to say CONTINUE between batches.
- End with a one-line list of files updated and files skipped.