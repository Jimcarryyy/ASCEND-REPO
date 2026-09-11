SESSION-END DOCS SYNC — ASCEND

Before writing anything, fetch the CURRENT raw content of each file listed 
below (I've given you the exact raw GitHub URLs). If you cannot browse/fetch 
URLs, stop and ask me to paste the current content of each file first — do 
not guess or edit blind.

Then review this entire chat thread and extract anything that changed, was 
decided, was fixed, was newly designed, or was newly discovered as a bug/
contradiction. Produce updates to the files below. Only output files that 
actually need a change based on this session — skip any file with nothing 
new to add.

For each file you update, follow its update mode exactly:

REPLACE (rewrite the full file, keep it clean, no stacked history):
- .ai/CURRENT_TASK.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CURRENT_TASK.md
  → replace entirely with the current in-progress task(s) as of the end of 
  this session.
- .ai/NEXT_STEPS.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/NEXT_STEPS.md
  → replace entirely with the current prioritized next-step list.
- .ai/PROJECT_STATUS.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/PROJECT_STATUS.md
  → replace entirely with ONE clean current-state snapshot. Never write a 
  completion percentage unless I explicitly confirmed one in this chat. If 
  old status text had a percentage or "operational" claim not confirmed here, 
  leave it out rather than guess.

APPEND-ONLY (fetch current file, add a new dated entry at the top/bottom per 
its existing convention, never delete or rewrite old entries):
- .ai/CHANGELOG.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CHANGELOG.md
  → append a new dated entry summarizing what was actually changed/fixed/built 
  this session.
- .ai/DECISIONS.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/DECISIONS.md
  → append a new dated entry for any decision made in this chat (scope calls, 
  "we're doing X not Y", deferred features, etc.), with a one-line rationale.

SELECTIVE / SURGICAL EDIT (fetch current file, amend or add only the specific 
section that changed; leave the rest of the file untouched — do NOT regenerate 
the whole doc):
- docs/COMBAT_SPEC.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/COMBAT_SPEC.md
- docs/PROGRESSION_SPEC.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/PROGRESSION_SPEC.md
- docs/UI_UX_SPEC.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/UI_UX_SPEC.md
- docs/GAME_DESIGN.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/GAME_DESIGN.md
- docs/ARCHITECTURE_SPEC.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ARCHITECTURE_SPEC.md
- docs/ASSET_MANIFEST.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ASSET_MANIFEST.md
- docs/CODE_DEPENDENCY_GUIDE.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/CODE_DEPENDENCY_GUIDE.md
- docs/CODEBASE_CLEANUP_GUIDE.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/CODEBASE_CLEANUP_GUIDE.md
- docs/ROBLOX_PERFORMANCE_RULES.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ROBLOX_PERFORMANCE_RULES.md
- docs/AI_PROMPT_GUIDE.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/AI_PROMPT_GUIDE.md
- docs/README.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/README.md
- .ai/AI_REPOSITORY_SCANNING_GUIDE.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/AI_REPOSITORY_SCANNING_GUIDE.md
- .ai/AI_ROLE_ROSTER.md
  https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/AI_ROLE_ROSTER.md

For these: if this session's change CONTRADICTS existing text (a number, a 
keybind, a name, a mechanic description), don't silently overwrite it — show 
me the old line and the new line side by side and flag it as a correction, 
not a silent edit. If it's brand new information with nothing to contradict, 
add it as a new subsection in the most logical existing location.

RULES FOR ALL OUTPUTS:
1. Output each file as its own clearly labeled markdown code block, headed 
   with the exact file path, so I can copy-paste directly into GitHub.
2. Do not invent details that weren't actually discussed/decided in this chat. 
   If something is ambiguous, mark it inline as [NEEDS CONFIRMATION: ...] 
   rather than guessing.
3. Keep additions concise — bullet points and short entries, not padded prose.
4. If this session revealed a bug, contradiction, or unfinished item that 
   doesn't have a natural home in the files above, put it under a "## Open 
   Items From This Session" heading appended to .ai/NEXT_STEPS.md.
5. At the very end, give me a one-line summary list of which files you 
   updated and which you skipped (and why skipped, if not obvious).

Now fetch the current content of the relevant files above, scan this full 
chat thread, and produce the updates.