import SwiftUI
import FitnessRPGCore

struct WatchExecutionView: View {
    let quest: DailyQuest
    @State private var stepIndex = 0

    private var currentStep: WatchStep? {
        guard !quest.watchSteps.isEmpty else {
            return nil
        }

        return quest.watchSteps[min(stepIndex, quest.watchSteps.count - 1)]
    }

    var body: some View {
        Group {
            if let step = currentStep {
                VStack(alignment: .leading, spacing: 10) {
                    Text(quest.difficulty)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    Text(step.instruction)
                        .font(.headline)

                    Text(step.target)
                        .font(.subheadline)

                    Text(step.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(step.safetyNote)
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    HStack {
                        Button("完成") { advance() }
                        Button("过重") { advance() }
                    }

                    HStack {
                        Button("跳过") { advance() }
                        Button("RPE内") { advance() }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("暂无 Watch 步骤")
                        .font(.headline)
                    Text("请回到 iPhone 重新生成任务。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private func advance() {
        guard !quest.watchSteps.isEmpty else {
            return
        }

        stepIndex = min(stepIndex + 1, quest.watchSteps.count - 1)
    }
}

#Preview {
    WatchExecutionView(
        quest: QuestEngine.quest(
            for: ReadinessEngine.evaluate(MockHealthProfiles.green),
            storyNode: "回声训练厅"
        )
    )
}
