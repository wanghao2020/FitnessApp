import SwiftUI
import FitnessRPGCore

struct TodayCommandCenterView: View {
    let readiness: ReadinessResult
    let modelMode: ModelMode
    let sourceNote: String?
    @ObservedObject var watchSyncModel: WatchQuestSyncModel

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
                        if let sourceNote, !sourceNote.isEmpty {
                            Text(sourceNote)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text(watchSyncModel.statusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ReadinessPanel(readiness: readiness)
                    QuestPanel(quest: quest)

                    Button("发送到 Watch") {
                        watchSyncModel.send(quest: quest, readinessColor: readiness.color)
                    }
                    .buttonStyle(.borderedProminent)

                    if let result = watchSyncModel.latestResult {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Watch 回传")
                                .font(.headline)
                            Text(result.safetyFeedback)
                            Text(result.nextRecommendation)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    ModelHarnessPanel(snapshot: harness)
                }
                .padding()
            }
            .navigationTitle("Fitness RPG")
            .onAppear {
                watchSyncModel.send(quest: quest, readinessColor: readiness.color)
            }
            .onChange(of: readiness.score) { _, _ in
                watchSyncModel.send(quest: quest, readinessColor: readiness.color)
            }
            .onChange(of: readiness.color) { _, _ in
                watchSyncModel.send(quest: quest, readinessColor: readiness.color)
            }
            .onChange(of: readiness.title) { _, _ in
                watchSyncModel.send(quest: quest, readinessColor: readiness.color)
            }
        }
    }
}

#Preview {
    TodayCommandCenterView(
        readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
        modelMode: .localFirst,
        sourceNote: "已读取 HealthKit 今日健康摘要。",
        watchSyncModel: WatchQuestSyncModel(session: nil)
    )
}
