import Foundation
import Combine
import WatchConnectivity
import FitnessRPGCore

@MainActor
final class WatchQuestSyncModel: NSObject, ObservableObject {
    @Published private(set) var quest: DailyQuest
    @Published private(set) var logs: [ExecutionLog] = []
    @Published private(set) var statusText = "等待 iPhone 任务。"

    private let session: WCSession?
    private let autoCompleteQuestOnReceipt: Bool

    init(
        initialQuest: DailyQuest = QuestEngine.quest(
            for: ReadinessEngine.evaluate(MockHealthProfiles.green),
            storyNode: "回声训练厅"
        ),
        session: WCSession? = WCSession.isSupported() ? WCSession.default : nil,
        autoCompleteQuestOnReceipt: Bool = WatchQuestSyncModel.debugAutoCompleteQuestOnReceipt
    ) {
        self.quest = initialQuest
        self.session = session
        self.autoCompleteQuestOnReceipt = autoCompleteQuestOnReceipt
        super.init()

        guard let session else {
            statusText = "当前设备不支持 WatchConnectivity，使用本地安全任务。"
            return
        }

        session.delegate = self
        session.activate()
        statusText = "正在连接 iPhone。"
    }

    func record(action: WatchAction, step: WatchStep, order: Int) {
        let log = WatchExecutionLogFactory.log(action: action, step: step, order: order)
        logs.append(log)
        sendLogs()
    }

    private func debugAutoCompleteQuestIfNeeded() {
        guard autoCompleteQuestOnReceipt else {
            return
        }

        logs = WatchExecutionLogFactory.completedLogs(for: quest)
        sendLogs()
    }

    private func sendLogs() {
        guard let session else {
            statusText = "本地已记录，无法同步到 iPhone。"
            return
        }

        do {
            let payload = ExecutionLogSyncPayload(
                questTitle: quest.title,
                logs: logs,
                sentAt: Date()
            )
            let message = try SyncEnvelope(kind: .executionLogs, payload: payload).toDictionary()

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { [weak self] error in
                    let errorDescription = error.localizedDescription
                    session.transferUserInfo(message)

                    Task { @MainActor in
                        self?.statusText = "回传失败，记录已排队：\(errorDescription)"
                    }
                }
                statusText = "已回传 \(logs.count) 条记录。"
            } else {
                session.transferUserInfo(message)
                statusText = "iPhone 暂不可达，记录已排队。"
            }
        } catch {
            statusText = "执行记录编码失败。"
        }
    }

    private func receiveEnvelopeData(_ data: Data?) {
        do {
            guard let data else {
                throw SyncPayloadError.missingEnvelopeData
            }

            let envelope = try SyncEnvelope.makeDecoder().decode(SyncEnvelope.self, from: data)
            let payload = try envelope.decodePayload(
                QuestSyncPayload.self,
                expectedKind: .quest
            )
            quest = payload.quest
            logs = []
            statusText = "已收到 iPhone 今日任务。"
            debugAutoCompleteQuestIfNeeded()
        } catch {
            statusText = "iPhone 任务解码失败，继续使用本地安全任务。"
        }
    }
}

private extension WatchQuestSyncModel {
    static var debugAutoCompleteQuestOnReceipt: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--fitnessrpg-auto-complete-watch-quest")
        #else
        false
        #endif
    }
}

extension WatchQuestSyncModel: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let errorDescription = error?.localizedDescription
        let isActivated = activationState == .activated

        Task { @MainActor in
            if let errorDescription {
                statusText = "iPhone 连接失败：\(errorDescription)"
            } else {
                statusText = isActivated ? "已连接 iPhone。" : "iPhone 连接未激活。"
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let data = message[SyncEnvelope.dictionaryPayloadKey] as? Data

        Task { @MainActor in
            receiveEnvelopeData(data)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        let data = userInfo[SyncEnvelope.dictionaryPayloadKey] as? Data

        Task { @MainActor in
            receiveEnvelopeData(data)
        }
    }
}
