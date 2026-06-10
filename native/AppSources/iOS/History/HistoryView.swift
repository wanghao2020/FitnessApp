import SwiftUI
import FitnessRPGCore

struct HistoryView: View {
    @ObservedObject var persistenceModel: TodayPersistenceModel

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
            } else {
                List {
                    Section("最近训练") {
                        ForEach(persistenceModel.historyDays) { day in
                            NavigationLink {
                                HistoryDetailView(day: day)
                            } label: {
                                HistoryDayRow(day: day)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            persistenceModel.reloadHistory()
        }
    }
}

private struct HistoryDayRow: View {
    let day: TrainingHistoryDay

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ReadinessDot(color: day.readinessColor)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(day.date)
                    .font(.headline)
                Text(day.questTitle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text("\(day.completionLabel) · \(day.readinessSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryDetailView: View {
    let day: TrainingHistoryDay

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(day.date)
                        .font(.title.bold())
                    Text(day.questTitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Label(day.completionLabel, systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(day.readinessColor.historyTint)
                }

                HistorySectionCard("Readiness") {
                    Text(day.readinessSummary)
                    Text(day.record.readiness.explanation)
                        .foregroundStyle(.secondary)
                    Text(day.record.readiness.safetyGuidance)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Quest") {
                    Text(day.record.quest.objective)
                    Text(day.stepSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Watch 回传") {
                    Text(day.executionSummary)
                    Text(day.recommendation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Memory 草稿") {
                    Text(day.memoryDraft)
                }

                HistorySectionCard("故事节点") {
                    Text(day.storyNodeTitle)
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
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ReadinessDot: View {
    let color: ReadinessColor

    var body: some View {
        Circle()
            .fill(color.historyTint)
            .frame(width: 10, height: 10)
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
