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
