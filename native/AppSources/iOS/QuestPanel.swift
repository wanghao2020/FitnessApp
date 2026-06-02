import SwiftUI
import FitnessRPGCore

struct QuestPanel: View {
    let quest: DailyQuest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(quest.title)
                    .font(.headline)
                Spacer()
                Text(quest.difficulty)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }

            Text(quest.objective)
                .font(.subheadline)

            Text(quest.attributeRewards.joined(separator: " / "))
                .font(.footnote.weight(.semibold))

            ForEach(Array(quest.watchSteps.enumerated()), id: \.offset) { index, step in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watch \(index + 1)：\(step.instruction)")
                        .font(.subheadline.weight(.semibold))
                    Text("\(step.target) · \(step.duration)")
                        .font(.footnote)
                    Text(step.safetyNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
