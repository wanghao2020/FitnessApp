# WatchConnectivity Quest Sync Design

## Goal

Add the first WatchConnectivity pass for Fitness RPG so the iPhone can send the current `DailyQuest` to Apple Watch and the Watch can send `ExecutionLog` records back to iPhone.

This pass should also do a targeted Core refactor around the new sync boundary. The goal is not a broad cleanup. The goal is to make the next native feature easier to reason about by giving models, engines, and sync contracts clearer homes.

## Chosen Direction

Use the Core-first sync contract approach.

`FitnessRPGCore` should define the versioned payloads and deterministic encoding behavior. The iOS and watchOS targets should implement thin WatchConnectivity adapters that depend on those contracts. UI view models can expose simple status text and current quest/log state, but they should not own sync schema details.

This keeps platform framework code out of Core, preserves testability, and avoids mixing transport concerns into readiness or quest logic.

## Architecture

The feature has three layers:

1. Shared Core contracts
   - `DailyQuest`, `WatchStep`, `ExecutionLog`, and related enums become codable where needed for transport.
   - A versioned sync envelope identifies message type, schema version, and payload.
   - Pure tests prove quest and execution payloads round-trip without WatchConnectivity.

2. Platform transport adapters
   - iOS owns a `WCSession` adapter that sends the current quest and receives execution logs.
   - watchOS owns a `WCSession` adapter that receives quests and sends execution logs.
   - Each adapter hides `WCSessionDelegate` details behind a small app-facing observable model.

3. SwiftUI integration
   - iOS shows a compact sync status and sends the current quest when the Today Command Center has a quest.
   - watchOS starts with the existing safe mock quest, then replaces it when a valid quest arrives from iPhone.
   - Watch action buttons append `ExecutionLog` records and send them back to iPhone.

## Core Refactor Scope

Keep the refactor small and tied to the sync feature.

Recommended file boundaries:

- `Models.swift`: stable domain value types such as health, quest, execution, and model harness snapshots.
- `MockHealthProfiles.swift`: mock health profiles.
- `ReadinessEngine.swift`: readiness evaluation.
- `QuestEngine.swift`: quest generation.
- `ExecutionEngine.swift`: execution result resolution.
- `ModelHarnessBuilder.swift`: model harness preview generation.
- `HealthSignals.swift`: health signal mapping, as it exists today.
- `SyncPayloads.swift`: sync envelope, message kind, quest payload, execution payload, and encoding helpers.

The refactor should preserve public APIs wherever possible. Existing tests should continue to compile with minimal changes.

## Sync Contracts

Core should define a small, versioned contract. A concrete first pass can use:

- `SyncMessageKind.quest`
- `SyncMessageKind.executionLogs`
- `SyncEnvelope`
  - `schemaVersion`
  - `kind`
  - `encodedAt`
  - payload data
- `QuestSyncPayload`
  - `quest`
  - `readinessColor`
  - `generatedAt`
- `ExecutionLogSyncPayload`
  - `questTitle`
  - `logs`
  - `sentAt`

The envelope should make unsupported schema versions and mismatched message kinds explicit decode failures. Those failures should not crash either app. They should become sync status text.

## Data Flow

```text
iPhone HealthKit summary
    -> ReadinessEngine
    -> QuestEngine
    -> QuestSyncPayload
    -> iOS WatchConnectivity adapter
    -> watchOS WatchConnectivity adapter
    -> WatchExecutionView
    -> ExecutionLog records
    -> watchOS WatchConnectivity adapter
    -> iOS WatchConnectivity adapter
    -> ExecutionEngine.resolve
```

The model harness should continue to see bounded app objects only. Raw HealthKit samples and raw WatchConnectivity dictionaries must not enter prompt previews.

## iOS Behavior

The iOS app should derive the current quest from the existing readiness flow, then send it through the sync model.

The UI can remain compact. The Today Command Center should show:

- current HealthKit source note,
- current Watch sync status,
- a send or retry affordance if useful,
- latest returned execution result if logs arrive during the session.

The iOS app should not block quest display when WatchConnectivity is unavailable. The phone is still the planning surface even if the Watch is offline.

## watchOS Behavior

The watch app should keep the existing mock quest as a safe fallback. When a valid `QuestSyncPayload` arrives, it replaces the displayed quest.

The four Watch buttons should create real logs:

- `complete`
- `tooHeavy`
- `skip`
- `rpeWithinTarget`

Each log should include step order, RPE, and a concise note. After a log is appended, the view advances to the next step when appropriate and attempts to sync logs back to iPhone.

The first pass can use fixed RPE values per button. A later pass can add richer RPE input.

## Transport Strategy

Use `WCSession` where available on iOS and watchOS.

The adapter should try immediate messaging when the counterpart is reachable. If not reachable, it can fall back to background transfer such as user info transfer. The exact API choice should stay inside the adapter so UI and Core do not care whether a payload was sent live or queued.

Because the current Xcode project has separate buildable iOS and watchOS app targets, this pass focuses on source structure and buildable WatchConnectivity adapters. Full real-device companion installation and embedding settings may need a later project-configuration pass after simulator or device testing.

## Error Handling

Expected non-fatal states:

- WatchConnectivity unavailable on the platform.
- Session not activated.
- Watch not paired or app not installed.
- Counterpart not reachable.
- Message send failed.
- Payload decode failed.
- Unsupported schema version.
- Unexpected message kind.

Each state should become a short app-facing status. None should crash, change readiness scoring, or erase the fallback quest.

## Testing

Core tests should be added before production changes:

- quest sync payload encodes and decodes with the same `DailyQuest`,
- execution log payload encodes and decodes with ordered logs,
- mismatched message kind fails decoding,
- unsupported schema version fails decoding.

Existing Core tests must continue to pass.

Platform verification should include:

```bash
(cd native/FitnessRPGCore && swift test)
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
node prototype/tests/prototypeContract.test.mjs
```

The browser prototype is not changed in this pass, but its contract check should remain green.

## Safety Boundaries

This pass must not:

- make Apple Watch the safety authority,
- let watchOS generate quests,
- write HealthKit data,
- start real workout sessions,
- add persistence,
- add local model runtime behavior,
- send raw HealthKit samples over WatchConnectivity,
- reward unsafe overreaching in narrative text.

The iPhone remains the planning and safety surface. The Watch remains the execution and feedback surface.

## Non-Goals

This pass does not include:

- polished real-device pairing UX,
- complete iPhone and Watch target embedding configuration,
- background workout sessions,
- live heart-rate streaming,
- complication or widget support,
- SwiftData persistence,
- cloud sync,
- remote model routing,
- manual story choice sync.

## Future Follow-Ups

After this pass:

1. Add project configuration for a production companion watch app relationship if device testing requires it.
2. Persist returned execution results, memory drafts, and story progression.
3. Add richer Watch-side RPE input and completion review.
4. Add local model runtime behind the deterministic harness and validator.
5. Expand diagnostics for HealthKit plus WatchConnectivity together.
