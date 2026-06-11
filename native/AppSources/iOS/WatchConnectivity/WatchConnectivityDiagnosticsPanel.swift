import SwiftUI
import FitnessRPGCore

struct WatchConnectivityDiagnosticsPanel: View {
    let snapshot: WatchConnectivityDiagnosticsSnapshot

    private var summary: WatchConnectivityDiagnosticsSummary {
        snapshot.summary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: summary.systemImageName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(summary.tintColor)
                    .frame(width: 34, height: 34)
                    .background(summary.tintColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("WatchConnectivity")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(summary.headline)
                        .font(.headline)
                        .lineLimit(2)
                    Text(summary.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.rows) { row in
                    WatchConnectivityDiagnosticsRowView(row: row, tint: summary.tintColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("WatchConnectivity 诊断")
    }
}

private struct WatchConnectivityDiagnosticsRowView: View {
    let row: WatchConnectivityDiagnosticsRow
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: row.systemImageName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(row.value)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private extension WatchConnectivityDiagnosticsSummary {
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
    WatchConnectivityDiagnosticsPanel(
        snapshot: WatchConnectivityDiagnosticsSnapshot(
            isSupported: true,
            activationState: .activated,
            isPaired: true,
            isWatchAppInstalled: true,
            isReachable: false,
            lastOutbound: WatchConnectivityTransferRecord(
                date: Date(),
                transport: .userInfo,
                detail: "回声训练厅：力量共振"
            ),
            lastErrorText: "Watch 暂不可达"
        )
    )
    .padding()
}
