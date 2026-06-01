# Chinese RPG Visual Refresh Design

## Goal

Refresh the existing interactive prototype into a Chinese-first Fitness RPG command center that clearly communicates the product direction: iPhone as the daily intelligence hub, Apple Watch as the execution surface, and RPG narrative as a motivational layer over safe training decisions.

This refresh should keep the prototype practical and scannable. It should not turn the app into a fantasy landing page or hide the health and safety logic behind decoration.

## Source Ideas

The design should productize the earlier Fitness Coach RPG skill concepts as visible interface structure:

- Training safety stays first. Rest and recovery must be rewarded as progress, not treated as failure.
- Readiness maps to world state:
  - Green: resonance stable; main quest can advance.
  - Yellow: resonance unstable; reduce load and progress through technique.
  - Red: overload risk; recovery chapter protects the next training arc.
- Training focus maps to narrative framing:
  - Push day: breakthrough, force, barrier breaking.
  - Pull day: control, climb, seize.
  - Leg day: carrying, standing, marching.
  - Recovery day: camp, travel, repair.
- RPG growth uses five attributes: strength, endurance, constitution, agility, intelligence.
- Skill content should appear as rules, templates, labels, and story snippets rather than one large prompt.

## Chosen Direction

Use Approach A: a Chinese RPG tactical dashboard.

The interface should feel like a real app screen for repeated daily use, with enough RPG identity to make the fitness loop emotionally memorable. The first screen remains a command center, not a marketing page.

## UI Structure

The refreshed prototype will keep the current one-page layout and interaction model, but rename and reshape the sections:

- Hero: `今日任务中枢`, with a concise Chinese summary and scenario switcher for `绿 / 黄 / 红`.
- Readiness panel: `今日状态`, showing score, status color, training mode, and readiness drivers.
- Health summary: `健康摘要`, showing sleep, HRV, resting heart rate, load, and injury notes in Chinese.
- World state strip: a compact RPG layer such as `世界状态：共振稳定 / 共振偏移 / 营火修复`.
- Daily quest: `今日任务`, showing quest title, training focus, and intensity boundary.
- Safety validator: `安全边界`, combining restrictions and workout-specific safety notes.
- Workout plan: `训练计划`, with exercises, target, RPE cap, and rest.
- RPG coach: `剧情教练`, with the story framing and action buttons.
- Character growth: `角色成长`, showing the five attributes and the expected reward for today's quest.
- Apple Watch panel: `Apple Watch 执行`, with current step and compact quick actions.
- Model mode: `模型模式`, with local-first, hybrid, and remote-disabled options.
- Workout result: `训练结果`, showing completion feedback and story progression.

## Content Language

All visible UI copy in the prototype should be Chinese. Technical product concepts may keep familiar names when useful, such as `Apple Watch`, `RPE`, `HealthKit`, and `HRV`.

Suggested scenario language:

- Green: `共振稳定`, `破障试炼`, `推进训练日`.
- Yellow: `共振偏移`, `深厅校准`, `技术修炼日`.
- Red: `营火修复`, `恢复任务`, `无高强度训练`.

Suggested actions:

- Coach actions: `开始任务`, `降低强度`, `进入恢复营地`.
- Watch actions: `完成`, `过重`, `跳过`, `RPE≤目标`.
- Result status: `任务完成`.

## Visual System

The visual direction should become calmer, denser, and more product-like:

- Use a light, health-oriented base with warm off-white surfaces and dark readable text.
- Use multiple restrained accents instead of a one-note palette:
  - green for stable readiness,
  - amber for caution,
  - red for recovery risk,
  - blue or teal for system and story signals.
- Keep cards at an 8px radius or less.
- Avoid nested card styling.
- Keep the Apple Watch panel dark to create a clear device contrast.
- Avoid large fantasy illustration for this pass. If stronger immersion is needed later, use `imagegen` to create a subtle campfire or resonance background asset after layout stabilizes.

## Interaction Model

The existing interactions remain:

- Scenario buttons update readiness, quest, safety, world state, watch payload, and suggested rewards.
- Model mode buttons update local/remote behavior explanation.
- Coach action buttons set the chosen action.
- Completing the mock workout updates the result panel with Chinese feedback.

New interaction state is not required for this pass. The goal is to improve product clarity and visual polish without expanding the prototype's state machine.

## Data Shape Changes

Small data additions are allowed if they keep the prototype easy to understand:

- Add Chinese labels to scenarios and model modes.
- Add world-state metadata to quest output.
- Add attribute reward metadata to quest output.
- Add chapter or node metadata for the story panel.

The implementation should avoid over-modeling the RPG system. This is still a prototype, not the final memory engine.

## Responsive Requirements

The layout must remain usable on desktop and narrow mobile widths:

- Chinese headings and long labels must wrap cleanly.
- Button text must not overflow.
- Scenario switching must remain reachable near the top.
- Exercise rows must collapse to one column on mobile.
- No horizontal page overflow.

## Verification

Before calling the refresh complete:

- Run JavaScript syntax checks for all prototype modules.
- Run a deterministic scenario smoke check for green, yellow, and red states.
- Confirm the local server returns the page.
- Verify the page visually in the in-app browser or equivalent local browser.
- Check a narrow/mobile viewport for text overlap and horizontal overflow.
