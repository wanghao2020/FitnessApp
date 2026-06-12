# Demo Scheme Runbook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a shared Xcode demo scheme plus a simulator smoke script so the deterministic demo seed can be opened and verified without manually entering launch arguments.

**Architecture:** Reuse the existing iOS app target and add a separate shared scheme that only changes launch arguments. The smoke script builds that scheme into an isolated DerivedData directory, installs it on a booted iPhone simulator, launches with the same arguments, and checks persisted JSON artifacts.

**Tech Stack:** Xcode shared schemes, `xcodebuild`, `xcrun simctl`, POSIX shell, existing JSON persistence files.

**Execution status:** Implemented in `4ee4561 chore(native): add demo seed scheme`.

---

## Files

- Create: `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGDemo.xcscheme`
- Create: `native/scripts/demo-seed-simulator-smoke.sh`
- Create: `docs/validation/demo-seed-runbook.md`
- Modify: `README.md`
- Modify: `native/README.md`
- Modify: `docs/superpowers/plans/2026-06-12-demo-scheme-runbook.md`

## Tasks

- [x] **Step 1: Verify RED for missing demo scheme**

Run: `test -f native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGDemo.xcscheme`
Expected: exit 1 because the scheme does not exist yet.

- [x] **Step 2: Verify RED for missing smoke script**

Run: `test -x native/scripts/demo-seed-simulator-smoke.sh`
Expected: exit 1 because the script does not exist yet.

- [x] **Step 3: Add shared demo scheme**

Create `FitnessRPGDemo.xcscheme` by mirroring the existing `FitnessRPG` scheme and adding LaunchAction command line arguments:

```xml
<CommandLineArguments>
   <CommandLineArgument argument = "--fitnessrpg-demo-seed" isEnabled = "YES"></CommandLineArgument>
   <CommandLineArgument argument = "--fitnessrpg-open-history" isEnabled = "YES"></CommandLineArgument>
   <CommandLineArgument argument = "--fitnessrpg-show-diagnostics" isEnabled = "YES"></CommandLineArgument>
</CommandLineArguments>
```

- [x] **Step 4: Add simulator smoke script**

Create `native/scripts/demo-seed-simulator-smoke.sh` so it:

- Finds a booted iPhone simulator or boots `iPhone 17`.
- Builds `FitnessRPGDemo` with a temporary DerivedData directory.
- Installs `FitnessRPG.app`.
- Launches `com.hao.fitnessrpg` with demo arguments.
- Checks the app data container for demo JSON fields.

- [x] **Step 5: Add demo seed runbook**

Create `docs/validation/demo-seed-runbook.md` with Xcode and CLI instructions plus expected evidence.

- [x] **Step 6: Update README entries**

Document `FitnessRPGDemo` and `native/scripts/demo-seed-simulator-smoke.sh` in root and native READMEs.

- [x] **Step 7: Verify GREEN**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -list
bash native/scripts/demo-seed-simulator-smoke.sh
git diff --check
```

Expected: scheme is listed, smoke script confirms JSON seed data, and diff check passes.

- [x] **Step 8: Commit and push**

Run:

```bash
git add README.md native/README.md native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGDemo.xcscheme native/scripts/demo-seed-simulator-smoke.sh docs/validation/demo-seed-runbook.md docs/superpowers/specs/2026-06-12-demo-scheme-runbook-design.md docs/superpowers/plans/2026-06-12-demo-scheme-runbook.md
git commit -m "chore(native): add demo seed scheme"
git push
```
