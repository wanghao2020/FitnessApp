import Combine
import Foundation
import WatchConnectivity
import FitnessRPGCore

@MainActor
final class WatchQuestSyncModel: NSObject, ObservableObject {
    @Published private(set) var statusText = "Watch 同步尚未启动。"
    @Published private(set) var latestResult: WorkoutResult?
    @Published private(set) var latestExecutionPayload: ExecutionLogSyncPayload?

    private let session: WCSession?
    private var currentQuest: DailyQuest?

    init(session: WCSession? = WCSession.isSupported() ? WCSession.default : nil) {
        self.session = session
        super.init()

        guard let session else {
            statusText = "当前设备不支持 WatchConnectivity。"
            return
        }

        session.delegate = self
        session.activate()
        statusText = "正在激活 Watch 同步。"
    }

    func send(quest: DailyQuest, readinessColor: ReadinessColor) {
        currentQuest = quest

        guard let session else {
            statusText = "当前设备不支持 WatchConnectivity。"
            return
        }

        do {
            let payload = QuestSyncPayload(
                quest: quest,
                readinessColor: readinessColor,
                generatedAt: Date()
            )
            let message = try SyncEnvelope(kind: .quest, payload: payload).toDictionary()

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { [weak self] error in
                    session.transferUserInfo(message)
                    Task { @MainActor in
                        self?.statusText = "Watch 发送失败，今日任务已排队：\(error.localizedDescription)"
                    }
                }
                statusText = "已发送今日任务到 Watch。"
            } else {
                session.transferUserInfo(message)
                statusText = "Watch 暂不可达，今日任务已排队。"
            }
        } catch {
            statusText = "任务同步编码失败。"
        }
    }

    private func receiveEnvelopeData(_ data: Data?) {
        do {
            guard let data else {
                throw SyncPayloadError.missingEnvelopeData
            }

            let envelope = try SyncEnvelope.makeDecoder().decode(SyncEnvelope.self, from: data)
            let payload = try envelope.decodePayload(
                ExecutionLogSyncPayload.self,
                expectedKind: .executionLogs
            )
            latestExecutionPayload = payload

            guard let currentQuest else {
                statusText = "已收到 Watch 记录，正在尝试本地持久化匹配。"
                return
            }

            guard payload.questTitle == currentQuest.title else {
                statusText = "收到 Watch 记录，但任务不匹配。"
                return
            }

            latestResult = ExecutionEngine.resolve(quest: currentQuest, logs: payload.logs)
            statusText = "已收到 Watch 执行记录：\(payload.logs.count) 条。"
        } catch {
            statusText = "Watch 记录解码失败。"
        }
    }
}

extension WatchQuestSyncModel: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                statusText = "Watch 同步激活失败：\(error.localizedDescription)"
            } else {
                statusText = activationState == .activated ? "Watch 同步已激活。" : "Watch 同步未激活。"
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            statusText = "Watch 同步暂时 inactive。"
        }
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
        Task { @MainActor in
            statusText = "正在重新激活 Watch 同步。"
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
