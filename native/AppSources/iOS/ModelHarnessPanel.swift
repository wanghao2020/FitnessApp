import SwiftUI
import FitnessRPGCore

struct ModelHarnessPanel: View {
    let snapshot: ModelHarnessSnapshot

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
}
