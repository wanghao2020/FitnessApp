public enum ReadinessEngine {
    public static func evaluate(_ health: HealthSummary) -> ReadinessResult {
        if health.drivers.contains("HealthKit 数据缺失") {
            return ReadinessResult(
                score: 55,
                color: .yellow,
                title: "共振偏移",
                explanation: "HealthKit 数据缺失，使用保守黄灯策略。",
                safetyGuidance: "降低强度，优先确认身体状态。"
            )
        }

        let score = max(
            0,
            min(
                100,
                (health.energy + health.recovery + health.sleep + (100 - health.strain) + (100 - health.heartRateTrend * 4)) / 5
            )
        )

        if health.recovery < 45 || health.sleep < 50 || health.heartRateTrend >= 12 {
            return ReadinessResult(
                score: score,
                color: .red,
                title: "营火修复",
                explanation: "恢复或睡眠信号不足，今日训练应转为修复。",
                safetyGuidance: "避免高强度训练，恢复也计入成长。"
            )
        }

        if health.energy < 68 || health.recovery < 66 || health.strain > 72 {
            return ReadinessResult(
                score: score,
                color: .yellow,
                title: "共振偏移",
                explanation: "身体可训练但负荷需要下调。",
                safetyGuidance: "降低强度，保持动作质量和可持续完成。"
            )
        }

        return ReadinessResult(
            score: score,
            color: .green,
            title: "共振稳定",
            explanation: "恢复、能量与负荷处在可推进区间。",
            safetyGuidance: "可以执行标准训练，但保留热身和RPE监控。"
        )
    }
}

public enum QuestEngine {
    public static func quest(for readiness: ReadinessResult, storyNode: String) -> DailyQuest {
        switch readiness.color {
        case .green:
            return DailyQuest(
                title: "回声训练厅：力量共振",
                objective: "完成标准力量循环，维持RPE 6-7。",
                difficulty: "标准",
                attributeRewards: ["STR +10", "END +12", "CON +6"],
                storyNode: storyNode,
                watchSteps: [
                    WatchStep(instruction: "动态热身", target: "关节活动 + 轻负荷", duration: "8分钟", safetyNote: "热身完成后再进入主训练。"),
                    WatchStep(instruction: "力量循环", target: "3组，RPE 6-7", duration: "24分钟", safetyNote: "任何过重信号都立即降阶。"),
                    WatchStep(instruction: "冷却记录", target: "呼吸 + 拉伸", duration: "6分钟", safetyNote: "记录RPE和异常感觉。")
                ]
            )
        case .yellow:
            return DailyQuest(
                title: "灰烬坡道：降阶巡航",
                objective: "降低强度，完成动作质量优先的轻量训练。",
                difficulty: "降阶",
                attributeRewards: ["CON +8", "AGI +5", "INT +4"],
                storyNode: storyNode,
                watchSteps: [
                    WatchStep(instruction: "低强度热身", target: "RPE 3-4", duration: "8分钟", safetyNote: "用热身确认状态，不追求速度。"),
                    WatchStep(instruction: "轻量循环", target: "2组，RPE 5以内", duration: "18分钟", safetyNote: "疲劳上升时直接跳过剩余组。"),
                    WatchStep(instruction: "恢复收尾", target: "拉伸 + 呼吸", duration: "8分钟", safetyNote: "恢复完成同样计入成长。")
                ]
            )
        case .red:
            return DailyQuest(
                title: "营火边缘：恢复仪式",
                objective: "恢复优先，完成轻活动、补水和睡眠准备。",
                difficulty: "恢复",
                attributeRewards: ["CON +10", "INT +6"],
                storyNode: storyNode,
                watchSteps: [
                    WatchStep(instruction: "轻步行", target: "舒适配速", duration: "12分钟", safetyNote: "不进入冲刺或力量训练。"),
                    WatchStep(instruction: "呼吸恢复", target: "鼻吸口呼", duration: "5分钟", safetyNote: "若不适则停止。"),
                    WatchStep(instruction: "睡眠准备", target: "放松流程", duration: "10分钟", safetyNote: "今晚目标是恢复资源。")
                ]
            )
        }
    }
}

public enum ExecutionEngine {
    public static func resolve(quest: DailyQuest, logs: [ExecutionLog]) -> WorkoutResult {
        let sortedLogs = logs.sorted { $0.order < $1.order }
        let heavyLog = sortedLogs.first { $0.action == .tooHeavy || $0.rpe >= 9 }
        let skippedEverything = !sortedLogs.isEmpty && sortedLogs.allSatisfy { $0.action == .skip }

        if let heavyLog {
            return WorkoutResult(
                completionState: .downgraded,
                safetyFeedback: "检测到过重信号：\(heavyLog.note)。本次结果记录为安全降阶。",
                nextRecommendation: "下一次同类任务降阶一档，并优先检查动作质量。",
                memoryDraft: "任务「\(quest.title)」中出现过重反馈：\(heavyLog.note)。后续推荐降低负荷。"
            )
        }

        if skippedEverything {
            return WorkoutResult(
                completionState: .skipped,
                safetyFeedback: "本次 Watch 步骤均跳过，保持恢复优先。",
                nextRecommendation: "下一次从恢复或轻量任务重新进入。",
                memoryDraft: "任务「\(quest.title)」被跳过，可能需要重新评估当天可训练性。"
            )
        }

        return WorkoutResult(
            completionState: .completed,
            safetyFeedback: "训练完成且未记录过重信号。",
            nextRecommendation: "保持当前节奏，下一次根据 readiness 决定是否推进。",
            memoryDraft: "任务「\(quest.title)」完成，奖励 \(quest.attributeRewards.joined(separator: " / "))。"
        )
    }
}

public enum ModelHarnessBuilder {
    public static func snapshot(
        readiness: ReadinessResult,
        quest: DailyQuest,
        mode: ModelMode,
        logs: [ExecutionLog]
    ) -> ModelHarnessSnapshot {
        let overload = logs.contains { $0.action == .tooHeavy || $0.rpe >= 9 }
        var rules = [
            "安全优先：\(readiness.safetyGuidance)",
            "恢复也计入成长，不能被叙事惩罚。",
            "Watch Payload 必须保持短句、目标、时长和安全提示。"
        ]

        if readiness.color != .green {
            rules.append("非绿灯状态必须降低强度或进入恢复任务。")
        }

        if overload {
            rules.append("Watch 已记录过重，下一轮推荐必须降阶。")
        }

        let generationPath: [String]
        let fallbackPolicy: String
        let modeLabel: String

        switch mode {
        case .localFirst:
            modeLabel = "本地优先"
            generationPath = ["规则过滤", "本地 Gemma / LiteRT-LM 草稿", "安全校验", "Watch Payload"]
            fallbackPolicy = "本地生成失败时使用确定性模板，并保留全部安全规则。"
        case .hybrid:
            modeLabel = "本地 + 远程增强"
            generationPath = ["规则过滤", "本地安全草稿", "安全校验", "远程仅润色周总结", "Watch Payload"]
            fallbackPolicy = "远程不可用时退回本地草稿；远程不参与安全决策。"
        case .remoteDisabled:
            modeLabel = "禁用远程"
            generationPath = ["规则过滤", "确定性模板", "安全校验", "Watch Payload"]
            fallbackPolicy = "禁用远程时使用确定性模板，不请求远程增强。"
        }

        let inputContext = [
            "状态：\(readiness.title) \(readiness.score)",
            "剧情节点：\(quest.storyNode)",
            "任务：\(quest.title)",
            "Watch 记录：\(logs.count) 条"
        ]

        let overloadLine = overload ? "已出现过重反馈，必须降阶。" : "未出现过重反馈。"
        let promptPreview = """
        模式：\(modeLabel)
        Readiness：\(readiness.title)，\(readiness.explanation)
        Quest：\(quest.title)，\(quest.objective)
        Safety：\(rules.joined(separator: "；"))
        Watch：输出短步骤、目标、时长、安全提示。\(overloadLine)
        """

        return ModelHarnessSnapshot(
            inputContext: inputContext,
            skillRules: rules,
            generationPath: generationPath,
            fallbackPolicy: fallbackPolicy,
            promptPreview: promptPreview
        )
    }
}
