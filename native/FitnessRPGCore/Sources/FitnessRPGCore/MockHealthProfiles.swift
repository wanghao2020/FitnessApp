public enum MockHealthProfiles {
    public static let green = HealthSummary(
        energy: 82,
        recovery: 78,
        strain: 52,
        sleep: 84,
        heartRateTrend: 2,
        drivers: ["睡眠稳定", "恢复良好", "昨日负荷可控"]
    )

    public static let yellow = HealthSummary(
        energy: 61,
        recovery: 58,
        strain: 76,
        sleep: 66,
        heartRateTrend: 6,
        drivers: ["恢复偏低", "昨日负荷偏高", "建议降低强度"]
    )

    public static let red = HealthSummary(
        energy: 38,
        recovery: 34,
        strain: 82,
        sleep: 42,
        heartRateTrend: 14,
        drivers: ["睡眠不足", "心率趋势偏高", "恢复优先"]
    )

    public static let missing = HealthSummary(
        energy: 55,
        recovery: 55,
        strain: 55,
        sleep: 55,
        heartRateTrend: 0,
        drivers: ["HealthKit 数据缺失", "使用保守黄灯"]
    )
}
