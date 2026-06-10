# Migration Index

This project is the clean target for the Fitness RPG WatchOS / iPhone + Apple Watch local LLM app context.

## Migrated Project Baseline

- `README.md` copied from `/Users/Hao/Documents/Claude-Learning/fitness-rpg-watchos-local-llm/README.md`, then updated with this migration section.
- `docs/project-brief.md` copied from `/Users/Hao/Documents/Claude-Learning/fitness-rpg-watchos-local-llm/docs/project-brief.md`.
- `.gitignore` copied from `/Users/Hao/Documents/Claude-Learning/fitness-rpg-watchos-local-llm/.gitignore`.

## Migrated Conversation Records

- `records/raw/codex-thread-student-reply-source-019e7bcd.jsonl`
  - Source thread: `019e7bcd-c4d3-73b2-b35f-1d3f8d2d3fce`
  - Thread title: `撰写学生回复`
  - Original path: `/Users/Hao/.codex/sessions/2026/05/31/rollout-2026-05-31T10-12-23-019e7bcd-c4d3-73b2-b35f-1d3f8d2d3fce.jsonl`
  - Contains the full original thread, including earlier unrelated student-reply discussion.

- `records/transcripts/student-reply-watchos-development-extract.md`
  - Readable extraction from the same thread.
  - Starts at `2026-06-01T08:50:00.000Z`, where the discussion shifted to `fitness-coach-rpg`, Apple Watch data, HealthKit, iPhone/watchOS app shape, Gemma / LiteRT-LM, local model harness, memory, and project-specific skills.

- `records/raw/codex-thread-fitness-rpg-watchos-local-llm-019e829b.jsonl`
  - Source thread: `019e829b-7991-7b51-a464-d4342566322f`
  - Thread title: `Fitness RPG WatchOS Local LLM`
  - Original path: `/Users/Hao/.codex/sessions/2026/06/01/rollout-2026-06-01T17-54-47-019e829b-7991-7b51-a464-d4342566322f.jsonl`
  - Contains the dedicated clean development thread.

- `records/transcripts/fitness-rpg-watchos-local-llm-thread.md`
  - Readable extraction from the dedicated thread.
  - Includes the handoff from the source thread and the first design recommendation: start with the Local LLM Harness end-to-end loop.

- `records/raw/codex-thread-migration-conversation-019e82a1.jsonl`
  - Source thread: `019e82a1-3401-7301-8d55-bf357c129a76`
  - Thread title: `迁移 watchOS 对话记录`
  - Original path: `/Users/Hao/.codex/sessions/2026/06/01/rollout-2026-06-01T18-01-03-019e82a1-3401-7301-8d55-bf357c129a76.jsonl`
  - Contains the current migration conversation.

- `records/transcripts/migration-conversation-thread.md`
  - Readable extraction from the current migration conversation.
  - Includes the search, source identification, copying, indexing, and verification steps.

## Key Migrated Decisions

- Product shape: iPhone is the planning, HealthKit, local LLM, memory, settings, and story-state surface; Apple Watch is the workout execution, RPE/completion capture, heart-rate context, and lightweight story-interaction surface.
- Skill strategy: `fitness-coach-rpg` should be productized as rules, templates, logs, and narrative knowledge, not embedded as one giant prompt.
- Data path: Apple Watch data enters through Apple Health / HealthKit, then gets converted into app-level summaries before model use.
- Runtime strategy: local-first model runtime, with Gemma / LiteRT-LM class models on iPhone where feasible and optional remote APIs for heavier weekly or story work.
- Harness priority: Intent Router, Health Data Adapter, Readiness Engine, Memory Store, Retrieval Engine, Prompt Builder, Model Runtime, Validator + Committer.
- MVP priority: start with `Daily Quest Path`, because it exercises HealthKit summaries, readiness, retrieval, prompting, model output validation, quest generation, and story state in one narrow loop.

## Notes

- I did not find a separate filesystem directory named `撰写学生回复` under `/Users/Hao/Documents/Claude-Learning`; that name exists as a Codex thread title.
- The raw JSONL files are intentionally preserved so tool calls, patches, and exact original messages remain recoverable.
- The copied project baseline came from the earlier clean source directory, but this current directory is now the active migration target.
