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
