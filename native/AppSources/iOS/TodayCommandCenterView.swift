import SwiftUI
import FitnessRPGCore

struct TodayCommandCenterView: View {
    let readiness: ReadinessResult
    let modelMode: ModelMode
    let sourceNote: String?
    @ObservedObject var watchSyncModel: WatchQuestSyncModel
    @ObservedObject var persistenceModel: TodayPersistenceModel

    private var fallbackQuest: DailyQuest {
        let storyNode = StoryProgressionEngine.displayNode(for: readiness.color).title
        return QuestEngine.quest(for: readiness, storyNode: storyNode)
    }

    private var quest: DailyQuest {
        persistenceModel.todayQuest ?? fallbackQuest
    }

    private var questReadiness: ReadinessResult {
        persistenceModel.todayRecord?.readiness ?? readiness
    }

    private var questReadinessColor: ReadinessColor {
        questReadiness.color
    }

    private var harness: ModelHarnessSnapshot {
        ModelHarnessBuilder.snapshot(
            readiness: questReadiness,
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
                        watchSyncModel.send(quest: quest, readinessColor: questReadinessColor)
                    }
                    .buttonStyle(.borderedProminent)

                    if let result = persistenceModel.latestResult ?? watchSyncModel.latestResult {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Watch 回传")
                                .font(.headline)
                            Text(result.safetyFeedback)
                            Text(result.nextRecommendation)
                                .foregroundStyle(.secondary)
                            Text(result.memoryDraft)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("故事进度")
                            .font(.headline)
                        Text(persistenceModel.currentStoryNodeTitle)
                        Text(persistenceModel.storyProgression.lastReason)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(persistenceModel.storageStatusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    ModelHarnessPanel(snapshot: harness)
                }
                .padding()
            }
            .navigationTitle("Fitness RPG")
            .toolbar {
                NavigationLink {
                    HistoryView(persistenceModel: persistenceModel)
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
            .onChange(of: watchSyncModel.latestExecutionPayload, initial: true) { _, payload in
                guard let payload else { return }
                persistenceModel.applyExecutionPayload(payload)
            }
        }
    }
}

#Preview {
    TodayCommandCenterView(
        readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
        modelMode: .localFirst,
        sourceNote: "已读取 HealthKit 今日健康摘要。",
        watchSyncModel: WatchQuestSyncModel(session: nil),
        persistenceModel: TodayPersistenceModel()
    )
}
