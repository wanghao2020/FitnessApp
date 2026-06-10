import fs from "node:fs";
import path from "node:path";

function readJsonl(file) {
  return fs
    .readFileSync(file, "utf8")
    .split(/\n/)
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

function contentText(content = []) {
  return content
    .map((item) => item.text ?? item.input_text ?? item.output_text ?? "")
    .filter(Boolean)
    .join("\n\n")
    .trim();
}

function writeTranscript({ source, output, title, threadId, notes, from }) {
  const records = readJsonl(source);
  const lines = [
    `# ${title}`,
    "",
    `- Thread ID: \`${threadId}\``,
    `- Raw source: \`${source}\``,
    `- Extracted: \`${new Date().toISOString()}\``,
  ];

  if (from) {
    lines.push(`- Extract starts at: \`${from}\``);
  }

  if (notes) {
    lines.push(`- Note: ${notes}`);
  }

  lines.push("", "## Messages", "");

  for (const record of records) {
    if (from && record.timestamp < from) continue;
    if (record.type !== "response_item") continue;
    const payload = record.payload ?? {};
    if (payload.type !== "message") continue;
    if (!["user", "assistant"].includes(payload.role)) continue;

    const text = contentText(payload.content);
    if (!text) continue;

    lines.push(`### ${record.timestamp} - ${payload.role}`);
    lines.push("");
    lines.push(text);
    lines.push("");
  }

  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, `${lines.join("\n").trim()}\n`, "utf8");
}

writeTranscript({
  source:
    "/Users/Hao/.codex/sessions/2026/06/01/rollout-2026-06-01T17-54-47-019e829b-7991-7b51-a464-d4342566322f.jsonl",
  output:
    "records/transcripts/fitness-rpg-watchos-local-llm-thread.md",
  title: "Fitness RPG WatchOS Local LLM Thread",
  threadId: "019e829b-7991-7b51-a464-d4342566322f",
  notes:
    "Readable extraction of the dedicated Fitness RPG WatchOS thread. Full raw JSONL is preserved under records/raw.",
});

writeTranscript({
  source:
    "/Users/Hao/.codex/sessions/2026/05/31/rollout-2026-05-31T10-12-23-019e7bcd-c4d3-73b2-b35f-1d3f8d2d3fce.jsonl",
  output:
    "records/transcripts/student-reply-watchos-development-extract.md",
  title: "Student Reply Thread WatchOS Development Extract",
  threadId: "019e7bcd-c4d3-73b2-b35f-1d3f8d2d3fce",
  from: "2026-06-01T08:50:00.000Z",
  notes:
    "Only the watchOS / Fitness Coach RPG / local LLM development portion is extracted; earlier student-reply content remains in the raw JSONL archive.",
});

writeTranscript({
  source:
    "/Users/Hao/.codex/sessions/2026/06/01/rollout-2026-06-01T18-01-03-019e82a1-3401-7301-8d55-bf357c129a76.jsonl",
  output:
    "records/transcripts/migration-conversation-thread.md",
  title: "Migration Conversation Thread",
  threadId: "019e82a1-3401-7301-8d55-bf357c129a76",
  notes:
    "Readable extraction of the conversation that migrated the Fitness RPG WatchOS context into a clean project.",
});
