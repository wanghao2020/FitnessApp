import SwiftUI
import FitnessRPGCore

struct TodayCommandCenterView: View {
    let readiness: ReadinessResult
    let modelMode: ModelMode
    let sourceNote: String?
    let healthDataSourceSnapshot: HealthDataSourceSnapshot
    @ObservedObject var watchSyncModel: WatchQuestSyncModel
    @ObservedObject var persistenceModel: TodayPersistenceModel
    let showsDiagnostics: Bool
    @State private var navigationPath: [AppLaunchDestination]

    init(
        readiness: ReadinessResult,
        modelMode: ModelMode,
        sourceNote: String?,
        healthDataSourceSnapshot: HealthDataSourceSnapshot = .loading,
        watchSyncModel: WatchQuestSyncModel,
        persistenceModel: TodayPersistenceModel,
        initialDestination: AppLaunchDestination = .today,
        showsDiagnostics: Bool = false
    ) {
        self.readiness = readiness
        self.modelMode = modelMode
        self.sourceNote = sourceNote
        self.healthDataSourceSnapshot = healthDataSourceSnapshot
        self.watchSyncModel = watchSyncModel
        self.persistenceModel = persistenceModel
        self.showsDiagnostics = showsDiagnostics
        _navigationPath = State(initialValue: initialDestination == .today ? [] : [initialDestination])
    }

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

    private var todaySummary: TodayCommandCenterSummary {
        TodayCommandCenterSummary(
            readiness: questReadiness,
            quest: quest,
            executionLogCount: persistenceModel.todayRecord?.executionLogs.count ?? 0
        )
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
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TodayHeroCard(
                        summary: todaySummary,
                        sourceNote: sourceNote,
                        watchStatusText: watchSyncModel.statusText,
                        tint: questReadinessColor.todayTint
                    )

                    if healthDataSourceSnapshot.shouldShowNotice {
                        TodayHealthSourceNoticeCard(snapshot: healthDataSourceSnapshot)
                    }

                    if showsDiagnostics {
                        WatchConnectivityDiagnosticsPanel(snapshot: watchSyncModel.diagnosticsSnapshot)
                    }

                    TodayQuestActionCard(
                        quest: quest,
                        summary: todaySummary,
                        tint: questReadinessColor.todayTint
                    )

                    if let result = persistenceModel.latestResult ?? watchSyncModel.latestResult {
                        TodayWatchResultCard(result: result)
                    }

                    TodayReadinessGuidanceCard(readiness: questReadiness, tint: questReadinessColor.todayTint)

                    TodayStoryProgressCard(
                        title: persistenceModel.currentStoryNodeTitle,
                        reason: persistenceModel.storyProgression.lastReason,
                        storageStatusText: persistenceModel.storageStatusText
                    )

                    if showsDiagnostics {
                        ModelHarnessPanel(snapshot: harness)
                    }
                }
                .padding()
                .padding(.bottom, 86)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                TodayStickyWatchCTA(summary: todaySummary) {
                    watchSyncModel.send(quest: quest, readinessColor: questReadinessColor)
                }
            }
            .navigationTitle(AppNavigationDisplay.todayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppLaunchDestination.self) { destination in
                switch destination {
                case .today:
                    EmptyView()
                case .history:
                    HistoryView(persistenceModel: persistenceModel)
                case .latestHistoryDetail:
                    HistoryView(persistenceModel: persistenceModel, initialDisplay: .latestDetail)
                case .memoryReview:
                    MemoryReviewView(persistenceModel: persistenceModel)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(value: AppLaunchDestination.memoryReview) {
                        HStack(spacing: 4) {
                            Image(systemName: AppNavigationDisplay.memoryReviewEntrySystemImage)
                            Text(AppNavigationDisplay.memoryReviewEntryLabel)
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppNavigationDisplay.memoryReviewTitle)

                    NavigationLink(value: AppLaunchDestination.history) {
                        HStack(spacing: 4) {
                            Image(systemName: AppNavigationDisplay.historyEntrySystemImage)
                            Text(AppNavigationDisplay.historyEntryLabel)
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppNavigationDisplay.historyTitle)
                }
            }
            .onChange(of: watchSyncModel.latestExecutionPayload, initial: true) { _, payload in
                guard let payload else { return }
                persistenceModel.applyExecutionPayload(payload)
            }
        }
    }
}

private struct TodayHeroCard: View {
    let summary: TodayCommandCenterSummary
    let sourceNote: String?
    let watchStatusText: String
    let tint: Color

    private var statusLine: String {
        [watchStatusText, sourceNote]
            .compactMap { note in
                guard let note, !note.isEmpty else { return nil }
                return note
            }
            .joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(summary.readinessLabel, systemImage: "heart.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            Text("今日任务中枢")
                .font(.system(.title, design: .rounded, weight: .bold))
                .lineLimit(2)

            Text(statusLine)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                TodayInlineMetric(
                    title: "Readiness",
                    value: summary.readinessScoreLabel,
                    systemImage: "heart.text.square",
                    tint: tint
                )
                Divider()
                    .padding(.vertical, 4)
                TodayInlineMetric(
                    title: "Watch",
                    value: summary.watchProgressLabel,
                    systemImage: "applewatch",
                    tint: tint
                )
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct TodayInlineMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

private struct TodayQuestActionCard: View {
    let quest: DailyQuest
    let summary: TodayCommandCenterSummary
    let tint: Color

    var body: some View {
        TodaySectionCard("今日任务", systemImage: "sparkles") {
            VStack(alignment: .leading, spacing: 10) {
                Text(quest.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .lineLimit(3)
                Label(summary.questContextLabel, systemImage: "flag.checkered")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Label(summary.rewardSummary, systemImage: "star.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(quest.objective)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(quest.watchSteps.enumerated()), id: \.offset) { index, step in
                    TodayWatchStepRow(index: index + 1, step: step, tint: tint)
                }
            }
            .padding(.top, 2)
        }
    }
}

private struct TodayHealthSourceNoticeCard: View {
    let snapshot: HealthDataSourceSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: snapshot.systemImageName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(snapshot.tintColor)
                .frame(width: 34, height: 34)
                .background(snapshot.tintColor.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.headline)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(snapshot.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct TodayStickyWatchCTA: View {
    let summary: TodayCommandCenterSummary
    let sendAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: sendAction) {
                Label(summary.primaryActionLabel, systemImage: summary.primaryActionSystemImage)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .background(.regularMaterial)
    }
}

private struct TodayWatchStepRow: View {
    let index: Int
    let step: WatchStep
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(step.instruction)
                    .font(.subheadline.weight(.semibold))
                Text("\(step.target) · \(step.duration)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(step.safetyNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct TodayWatchResultCard: View {
    let result: WorkoutResult

    var body: some View {
        TodaySectionCard("Watch 回传", systemImage: "checkmark.circle.fill") {
            Text(result.safetyFeedback)
            Text(result.nextRecommendation)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(result.memoryDraft)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TodayReadinessGuidanceCard: View {
    let readiness: ReadinessResult
    let tint: Color

    var body: some View {
        TodaySectionCard("Readiness", systemImage: "heart.text.square") {
            HStack(alignment: .firstTextBaseline) {
                Text(readiness.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(readiness.score)")
                    .font(.title3.bold())
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }
            Text(readiness.explanation)
                .foregroundStyle(.secondary)
            Text(readiness.safetyGuidance)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TodayStoryProgressCard: View {
    let title: String
    let reason: String
    let storageStatusText: String

    var body: some View {
        TodaySectionCard("故事进度", systemImage: "sparkles") {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(reason)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(storageStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TodaySectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    private let content: Content

    init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private extension ReadinessColor {
    var todayTint: Color {
        switch self {
        case .green:
            return .green
        case .yellow:
            return .orange
        case .red:
            return .red
        }
    }
}

private extension HealthDataSourceSnapshot {
    var tintColor: Color {
        switch tintName {
        case "green":
            return .green
        case "blue":
            return .blue
        case "orange":
            return .orange
        case "red":
            return .red
        default:
            return .accentColor
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
