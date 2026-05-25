# Runbook: use_computer tool safety

**Trigger:** every GUI action (click, drag, type).
**Cost of failure:** wrong-app opened, lost unsaved work, taskbar misclick, time wasted.
**Adapted from:** Kimi K2.6's `runbooks/use_computer.md` (D419) + my YouTube-goal incidents.

## Pre-action checklist
- [ ] **1. Locate before clicking:** Take a screenshot or use `get_pixel_coords_of_element` to confirm the target's pixel coordinates. Don't guess from memory of a layout I last saw N actions ago — the page may have scrolled.
- [ ] **2. Click centers, not edges.** Cursor tip in the center of buttons, icons, and links. Edges of boxes can miss.
- [ ] **3. Wait after state changes.** After launching apps, clicking submit, or triggering dialogs, take a screenshot before the next action. Don't assume immediate completion.
- [ ] **4. After critical actions (publish, submit, upload), screenshot to verify.**
- [ ] **5. Bottom corners are high-risk.** Taskbar (bottom) and task switcher (bottom corners) are easy to misclick. Verify coordinates explicitly there.
- [ ] **6. Unexpected window → close via X.** Don't try to figure out what it is; close and re-orient.
- [ ] **7. File picker quirks (GTK):** Double-click on a folder does NOT navigate. Press **Enter** on a selected folder. Use the search/filter box for filenames.
- [ ] **8. Dialog scrolling:** Mouse wheel / PageDown may not work. Use Tab to move focus, or `Ctrl+-` 2–3× to zoom out the page so the OK/Submit button is visible without scrolling.

## YouTube-flow specifics (relevant when goal resumes)
- "Details → Next → Captions upload → Next → Next → Public → Publish" — never skip the captions upload step.
- Visibility radio buttons: click the radio dot itself, not just the label.
- Save Draft button is in the same row as Publish — verify which one I'm clicking.

## Historical context
- D415–416: multiple coordinate misclicks led to wrong apps opening; recovered each time but at action-budget cost.
- V6 publish in D419 s1: I'd left it mid-flight in V6; restoring the right tab took 2 actions.

## Rule in memory does not run itself
This checklist must be executed before the GUI action, not recalled abstractly.
