import SwiftUI
import FitnessRPGCore

struct MemoryReviewView: View {
    @ObservedObject var persistenceModel: TodayPersistenceModel

    var body: some View {
        Group {
            if let errorText = persistenceModel.memoryReviewLoadErrorText {
                ContentUnavailableView(
                    "记忆读取失败",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorText)
                )
            } else if persistenceModel.memoryReviewEntries.isEmpty {
                MemoryReviewEmptyStateView(message: persistenceModel.memoryReviewEmptyStateText)
            } else {
                memoryList
            }
        }
        .navigationTitle(AppNavigationDisplay.memoryReviewTitle)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            persistenceModel.reloadMemoryReview()
        }
    }

    private var memoryList: some View {
        List {
            Section {
                ForEach(persistenceModel.memoryReviewEntries) { entry in
                    NavigationLink {
                        MemoryReviewDetailView(entry: entry)
                    } label: {
                        MemoryReviewRow(entry: entry)
                    }
                }
            } header: {
                Label("最近记忆", systemImage: AppNavigationDisplay.memoryReviewEntrySystemImage)
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct MemoryReviewRow: View {
    let entry: MemoryReviewEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.completionSymbolName)
                .symbolRenderingMode(.hierarchical)
                .font(.title3)
                .foregroundStyle(memoryTint)
                .frame(width: 28, height: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date)
                    .font(.headline.monospacedDigit())
                Text(entry.questTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(entry.storyContextLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.draft)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }

    private var memoryTint: Color {
        switch entry.completionLabel {
        case "已完成":
            return .green
        case "已降阶":
            return .orange
        default:
            return .secondary
        }
    }
}

private struct MemoryReviewDetailView: View {
    let entry: MemoryReviewEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                MemoryReviewHeroView(entry: entry)

                MemoryReviewSectionCard("来源", systemImage: "link") {
                    Text(entry.sourceSummary)
                    Text(entry.questTitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                MemoryReviewSectionCard("故事节点", systemImage: "sparkles") {
                    Text(entry.storyNodeTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(entry.storyContextLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                MemoryReviewSectionCard("奖励摘要", systemImage: "star.fill") {
                    Text(entry.rewardSummary)
                }

                MemoryReviewSectionCard("Memory 草稿", systemImage: "book.closed") {
                    Text(entry.draft)
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("记忆详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MemoryReviewHeroView: View {
    let entry: MemoryReviewEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(entry.completionLabel, systemImage: entry.completionSymbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(entry.questTitle)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .lineLimit(3)

            Label(entry.storyContextLabel, systemImage: "sparkles")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(entry.draft)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct MemoryReviewEmptyStateView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "还没有记忆",
            systemImage: AppNavigationDisplay.memoryReviewEntrySystemImage,
            description: Text(message)
        )
        .padding()
    }
}

private struct MemoryReviewSectionCard<Content: View>: View {
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

#Preview {
    NavigationStack {
        MemoryReviewView(persistenceModel: TodayPersistenceModel())
    }
}
