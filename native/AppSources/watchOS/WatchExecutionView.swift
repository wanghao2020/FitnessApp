import SwiftUI
import FitnessRPGCore

struct WatchExecutionView: View {
    @ObservedObject var syncModel: WatchQuestSyncModel
    @State private var stepIndex = 0

    private var quest: DailyQuest {
        syncModel.quest
    }

    private var currentStep: WatchStep? {
        guard stepIndex < quest.watchSteps.count else {
            return nil
        }

        return quest.watchSteps[stepIndex]
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

                    Text(syncModel.statusText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("完成") { record(.complete, step: step) }
                        Button("过重") { record(.tooHeavy, step: step) }
                    }

                    HStack {
                        Button("跳过") { record(.skip, step: step) }
                        Button("RPE内") { record(.rpeWithinTarget, step: step) }
                    }
                }
            } else {
                if quest.watchSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("暂无 Watch 步骤")
                            .font(.headline)
                        Text("请回到 iPhone 重新生成任务。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("任务步骤已完成")
                            .font(.headline)
                        Text(syncModel.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .onChange(of: quest.title) { _, _ in
            stepIndex = 0
        }
    }

    private func record(_ action: WatchAction, step: WatchStep) {
        guard stepIndex < quest.watchSteps.count else {
            return
        }

        syncModel.record(action: action, step: step, order: stepIndex + 1)
        advance()
    }

    private func advance() {
        guard !quest.watchSteps.isEmpty else {
            return
        }

        stepIndex = min(stepIndex + 1, quest.watchSteps.count)
    }
}

#Preview {
    WatchExecutionView(
        syncModel: WatchQuestSyncModel(session: nil)
    )
}
