import SwiftUI
import FitnessRPGCore

struct ModelHarnessPanel: View {
    let snapshot: ModelHarnessSnapshot
    let runtimeSummary: ModelRuntimeDiagnosticsSummary?

    init(
        snapshot: ModelHarnessSnapshot,
        runtimeSummary: ModelRuntimeDiagnosticsSummary? = nil
    ) {
        self.snapshot = snapshot
        self.runtimeSummary = runtimeSummary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本地模型 Harness")
                .font(.headline)

            Group {
                section("输入上下文", snapshot.inputContext)
                section("Skill 规则", snapshot.skillRules)
                section("生成路径", snapshot.generationPath)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Fallback")
                    .font(.subheadline.weight(.semibold))
                Text(snapshot.fallbackPolicy)
                    .font(.footnote)
            }

            if let runtimeSummary {
                runtimeSection(runtimeSummary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Memory 草稿")
                    .font(.subheadline.weight(.semibold))
                Text("完成后记录训练反馈、降阶信号和下一次建议。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(snapshot.promptPreview)
                .font(.caption.monospaced())
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func section(_ title: String, _ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ForEach(lines, id: \.self) { line in
                Text("· \(line)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runtimeSection(_ summary: ModelRuntimeDiagnosticsSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: summary.systemImageName)
                    .foregroundStyle(summary.tintColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.headline)
                        .font(.subheadline.weight(.semibold))
                    Text(summary.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ForEach(summary.rows) { row in
                ModelRuntimeDiagnosticsRowView(row: row, tint: summary.tintColor)
            }
        }
        .padding(10)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ModelRuntimeDiagnosticsPanel: View {
    let summary: ModelRuntimeDiagnosticsSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: summary.systemImageName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(summary.tintColor)
                    .frame(width: 34, height: 34)
                    .background(summary.tintColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("本地模型 Runtime")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(summary.headline)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(summary.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ForEach(summary.rows) { row in
                ModelRuntimeDiagnosticsRowView(row: row, tint: summary.tintColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ModelRuntimeDiagnosticsRowView: View {
    let row: ModelRuntimeDiagnosticsRow
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: row.systemImageName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(row.value)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension ModelRuntimeDiagnosticsSummary {
    var tintColor: Color {
        switch tintName {
        case "green":
            return .green
        case "orange":
            return .orange
        case "red":
            return .red
        case "blue":
            return .blue
        default:
            return .accentColor
        }
    }
}
