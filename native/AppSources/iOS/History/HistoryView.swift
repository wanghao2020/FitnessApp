import SwiftUI
import FitnessRPGCore

enum HistoryInitialDisplay {
    case list
    case latestDetail
}

struct HistoryView: View {
    @ObservedObject var persistenceModel: TodayPersistenceModel
    let initialDisplay: HistoryInitialDisplay
    let modelRuntimeFixtureMode: ModelRuntimeDebugFixtureMode?
    @State private var weeklyPolishResponse: ModelRuntimeResponse?
    @State private var isRegeneratingWeeklyPolish = false

    init(
        persistenceModel: TodayPersistenceModel,
        initialDisplay: HistoryInitialDisplay = .list,
        modelRuntimeFixtureMode: ModelRuntimeDebugFixtureMode? = nil
    ) {
        self.persistenceModel = persistenceModel
        self.initialDisplay = initialDisplay
        self.modelRuntimeFixtureMode = modelRuntimeFixtureMode
    }

    var body: some View {
        Group {
            if let errorText = persistenceModel.historyLoadErrorText {
                ContentUnavailableView(
                    "历史记录读取失败",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorText)
                )
            } else if persistenceModel.historyDays.isEmpty {
                HistoryEmptyStateView(message: persistenceModel.historyEmptyStateText)
            } else if initialDisplay == .latestDetail, let latestDay = persistenceModel.historyDays.first {
                HistoryDetailView(day: latestDay)
            } else {
                historyList
            }
        }
        .navigationTitle(initialDisplay == .latestDetail ? "训练详情" : AppNavigationDisplay.historyTitle)
        .navigationBarTitleDisplayMode(initialDisplay == .latestDetail ? .inline : .large)
        .onAppear {
            persistenceModel.reloadHistory()
        }
        .task(id: weeklySummaryRefreshID) {
            await refreshWeeklyPolishResponse()
        }
    }

    private var historyList: some View {
        List {
            Section {
                WeeklyTrainingSummaryCard(
                    summary: persistenceModel.weeklyTrainingSummary,
                    polishResponse: weeklyPolishResponse,
                    isRegenerating: isRegeneratingWeeklyPolish,
                    regenerateAction: {
                        Task {
                            await regenerateWeeklyPolish()
                        }
                    },
                    clearAction: clearWeeklyPolishCache
                )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(persistenceModel.historyDays) { day in
                    NavigationLink {
                        HistoryDetailView(day: day)
                    } label: {
                        HistoryDayRow(day: day)
                    }
                }
            } header: {
                Label("最近训练", systemImage: "clock.arrow.circlepath")
            }
        }
        .listStyle(.insetGrouped)
    }

    private var weeklySummaryRefreshID: String {
        let summary = persistenceModel.weeklyTrainingSummary
        return [
            summary.dateRangeLabel,
            summary.completionLabel,
            summary.readinessLabel,
            modelRuntimeFixtureMode?.rawValue ?? "default"
        ].joined(separator: "|")
    }

    private var modelRuntimeResourceObserver: LocalModelResourceBundleObserver {
        #if DEBUG
        if let modelRuntimeFixtureMode {
            return .debugFixture(mode: modelRuntimeFixtureMode)
        }
        #endif

        return LocalModelResourceBundleObserver()
    }

    @MainActor
    private func refreshWeeklyPolishResponse(ignoringCache: Bool = false) async {
        guard !persistenceModel.historyDays.isEmpty else {
            weeklyPolishResponse = nil
            return
        }

        if !ignoringCache,
           let cachedResponse = persistenceModel.weeklySummaryPolishEntry?.modelRuntimeResponse {
            weeklyPolishResponse = cachedResponse
            return
        }

        let response = await WeeklySummaryPolishRunner.response(
            summary: persistenceModel.weeklyTrainingSummary,
            provider: modelRuntimeResourceObserver.provider
        )
        if response.source == .localModel {
            weeklyPolishResponse = response
            persistenceModel.saveWeeklySummaryPolishResponse(response)
        } else {
            weeklyPolishResponse = nil
        }
    }

    @MainActor
    private func regenerateWeeklyPolish() async {
        guard !isRegeneratingWeeklyPolish else {
            return
        }

        isRegeneratingWeeklyPolish = true
        persistenceModel.clearWeeklySummaryPolishEntry()
        weeklyPolishResponse = nil
        await refreshWeeklyPolishResponse(ignoringCache: true)
        isRegeneratingWeeklyPolish = false
    }

    @MainActor
    private func clearWeeklyPolishCache() {
        persistenceModel.clearWeeklySummaryPolishEntry()
        weeklyPolishResponse = nil
    }
}

private struct WeeklyTrainingSummaryCard: View {
    let summary: WeeklyTrainingSummary
    let polishResponse: ModelRuntimeResponse?
    let isRegenerating: Bool
    let regenerateAction: () -> Void
    let clearAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("本周回顾", systemImage: "calendar.badge.clock")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(summary.dateRangeLabel)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(summary.headline)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .lineLimit(2)
                Text(summary.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label(summary.completionLabel, systemImage: "checklist")
                Label(summary.readinessLabel, systemImage: "heart.text.square")
                Label(summary.safetyLabel, systemImage: "shield.lefthalf.filled")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(summary.nextWeekPlanTitle)
                    .font(.subheadline.weight(.semibold))

                ForEach(Array(summary.nextWeekActions.enumerated()), id: \.offset) { _, action in
                    Label(action, systemImage: "arrow.forward.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let polishResponse, polishResponse.source == .localModel {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("本地模型润色", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text(polishResponse.draft.title)
                        .font(.subheadline.weight(.semibold))
                    Text(polishResponse.draft.body)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Label(polishResponse.draft.nextAction, systemImage: "arrow.right.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button(action: regenerateAction) {
                            Label(
                                isRegenerating ? "生成中" : "重新生成",
                                systemImage: "arrow.clockwise"
                            )
                        }
                        .disabled(isRegenerating)

                        Button(role: .destructive, action: clearAction) {
                            Label("清除缓存", systemImage: "trash")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
    }
}

private struct HistoryDayRow: View {
    let day: TrainingHistoryDay

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: day.completionSymbolName)
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
                .foregroundStyle(day.readinessColor.historyTint)
                .frame(width: 28, height: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(day.date)
                    .font(.headline.monospacedDigit())
                Text(day.questTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(day.storyContextLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(day.resultSummary) · \(day.readinessSummary)", systemImage: "applewatch")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct HistoryDetailView: View {
    let day: TrainingHistoryDay

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HistoryDetailHeroView(day: day)

                HistorySectionCard("Watch 回传", systemImage: "applewatch") {
                    Text(day.executionSummary)
                    Text(day.recommendation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if day.watchLogRows.isEmpty {
                        Label("等待 Watch 回传步骤。", systemImage: "clock")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(day.watchLogRows) { row in
                                HistoryWatchLogRowView(row: row)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                HistorySectionCard("Readiness", systemImage: "heart.text.square") {
                    Text(day.readinessSummary)
                        .font(.subheadline.weight(.semibold))
                    Text(day.record.readiness.explanation)
                        .foregroundStyle(.secondary)
                    Text(day.record.readiness.safetyGuidance)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Quest", systemImage: "list.bullet.clipboard") {
                    Text(day.record.quest.objective)
                    Text(day.stepSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Memory 草稿", systemImage: "book.closed") {
                    Text(day.memoryDraft)
                }

                HistorySectionCard("故事节点", systemImage: "sparkles") {
                    Text(day.storyNodeTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(day.storyReason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("训练详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HistoryDetailHeroView: View {
    let day: TrainingHistoryDay

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(day.resultSummary, systemImage: day.completionSymbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(day.readinessColor.historyTint)

            VStack(alignment: .leading, spacing: 6) {
                Text(day.questTitle)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .lineLimit(3)
                Label(day.storyContextLabel, systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Label(day.rewardSummary, systemImage: "star.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                HistoryMetricTile(
                    title: "Watch",
                    value: day.watchProgressLabel,
                    systemImage: "applewatch",
                    tint: day.readinessColor.historyTint
                )
                HistoryMetricTile(
                    title: "Readiness",
                    value: "\(day.record.readiness.score)",
                    systemImage: "heart.fill",
                    tint: day.readinessColor.historyTint
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct HistoryMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(3)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct HistoryWatchLogRowView: View {
    let row: TrainingHistoryWatchLogRow

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: row.actionSymbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(actionTint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(row.stepTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(row.rpeLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(row.note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(row.actionLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(actionTint)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var actionTint: Color {
        switch row.actionLabel {
        case "过重":
            return .red
        case "跳过":
            return .secondary
        case "RPE 达标":
            return .blue
        default:
            return .green
        }
    }
}

private struct HistoryEmptyStateView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "还没有历史记录",
            systemImage: "clock.arrow.circlepath",
            description: Text(message)
        )
        .padding()
    }
}

private struct HistorySectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    private let content: Content

    init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private extension ReadinessColor {
    var historyTint: Color {
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

#Preview {
    NavigationStack {
        HistoryView(persistenceModel: TodayPersistenceModel())
    }
}
