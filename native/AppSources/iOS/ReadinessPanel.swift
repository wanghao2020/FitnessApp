import SwiftUI
import FitnessRPGCore

struct ReadinessPanel: View {
    let readiness: ReadinessResult

    private var accent: Color {
        switch readiness.color {
        case .green:
            return .green
        case .yellow:
            return .orange
        case .red:
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(readiness.title)
                    .font(.headline)
                Spacer()
                Text("\(readiness.score)")
                    .font(.title2.bold())
                    .foregroundStyle(accent)
            }

            Text(readiness.explanation)
                .font(.subheadline)

            Text(readiness.safetyGuidance)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
