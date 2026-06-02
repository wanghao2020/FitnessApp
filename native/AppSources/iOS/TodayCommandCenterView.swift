import SwiftUI
import FitnessRPGCore

struct TodayCommandCenterView: View {
    let readiness: ReadinessResult
    let modelMode: ModelMode

    private var quest: DailyQuest {
        QuestEngine.quest(for: readiness, storyNode: "回声训练厅")
    }

    private var harness: ModelHarnessSnapshot {
        ModelHarnessBuilder.snapshot(
            readiness: readiness,
            quest: quest,
            mode: modelMode,
            logs: []
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("今日任务中枢")
                            .font(.largeTitle.bold())
                        Text("iPhone 是大脑，Apple Watch 是执行面。")
                            .foregroundStyle(.secondary)
                    }

                    ReadinessPanel(readiness: readiness)
                    QuestPanel(quest: quest)
                    ModelHarnessPanel(snapshot: harness)
                }
                .padding()
            }
            .navigationTitle("Fitness RPG")
        }
    }
}

#Preview {
    TodayCommandCenterView(
        readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
        modelMode: .localFirst
    )
}
