# HealthKit Read-Only Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a read-only HealthKit MVP that maps Apple Health data into `HealthSummary` and lets the iOS app derive readiness from real data with conservative fallback.

**Architecture:** Keep HealthKit framework usage isolated to the iOS target. Add a pure Swift `HealthSignals` mapper to `FitnessRPGCore` so fallback and scoring heuristics can be tested without HealthKit permissions. The iOS app requests read authorization, loads HealthKit samples into normalized signals, maps them to `HealthSummary`, and passes the resulting readiness into the existing Today Command Center UI.

**Tech Stack:** Swift 6, SwiftUI, HealthKit, XCTest, Xcode project file, generated Info.plist keys, iOS HealthKit entitlement.

---

## File Structure

- Create `native/FitnessRPGCore/Sources/FitnessRPGCore/HealthSignals.swift`: normalized health signal model and pure mapper to `HealthSummary`.
- Modify `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`: add mapper tests.
- Create `native/AppSources/iOS/HealthKit/HealthKitHealthSummaryProvider.swift`: iOS-only HealthKit adapter.
- Create `native/AppSources/iOS/TodayHealthViewModel.swift`: app-facing loading and fallback state.
- Modify `native/AppSources/iOS/FitnessRPGApp.swift`: use the view model instead of hardcoded green mock health.
- Modify `native/AppSources/iOS/TodayCommandCenterView.swift`: display a short source/status line.
- Create `native/AppSources/iOS/FitnessRPG.entitlements`: HealthKit entitlement for the iOS app target.
- Modify `native/FitnessRPG.xcodeproj/project.pbxproj`: add new iOS files to the iOS target, link HealthKit, set HealthKit share usage description, and attach entitlements to iOS only.
- Modify `README.md` and `native/README.md`: document HealthKit read-only MVP and current fallback behavior.

Do not modify watchOS source files except to verify they still build.

---

### Task 1: Add Pure Health Signal Mapping In Core

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/HealthSignals.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: Add failing mapper tests**

Append these tests to `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift` inside `FitnessRPGCoreTests`:

```swift
    func testHealthySignalsMapToGreenLeaningSummary() {
        let summary = HealthSummaryMapper.summary(
            from: HealthSignals(
                sleepHours: 8.1,
                hrvSDNN: 68,
                restingHeartRate: 56,
                restingHeartRateBaseline: 58,
                activeEnergyKcal: 420,
                exerciseMinutes: 38,
                stepCount: 9200,
                workoutCount: 1
            )
        )

        XCTAssertGreaterThanOrEqual(summary.energy, 75)
        XCTAssertGreaterThanOrEqual(summary.recovery, 75)
        XCTAssertLessThan(summary.strain, 70)
        XCTAssertGreaterThanOrEqual(summary.sleep, 80)
        XCTAssertEqual(summary.heartRateTrend, 0)
        XCTAssertTrue(summary.drivers.contains("睡眠稳定"))
        XCTAssertTrue(summary.drivers.contains("恢复良好"))
    }

    func testHighStrainSignalsMapToYellowLeaningSummary() {
        let summary = HealthSummaryMapper.summary(
            from: HealthSignals(
                sleepHours: 6.6,
                hrvSDNN: 45,
                restingHeartRate: 64,
                restingHeartRateBaseline: 58,
                activeEnergyKcal: 960,
                exerciseMinutes: 96,
                stepCount: 16800,
                workoutCount: 2
            )
        )

        let readiness = ReadinessEngine.evaluate(summary)
        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertGreaterThan(summary.strain, 72)
        XCTAssertTrue(summary.drivers.contains("昨日负荷偏高"))
    }

    func testPoorSleepAndElevatedHeartRateMapToRedLeaningSummary() {
        let summary = HealthSummaryMapper.summary(
            from: HealthSignals(
                sleepHours: 4.2,
                hrvSDNN: 24,
                restingHeartRate: 76,
                restingHeartRateBaseline: 60,
                activeEnergyKcal: 280,
                exerciseMinutes: 18,
                stepCount: 4200,
                workoutCount: 0
            )
        )

        let readiness = ReadinessEngine.evaluate(summary)
        XCTAssertEqual(readiness.color, .red)
        XCTAssertLessThan(summary.sleep, 50)
        XCTAssertGreaterThanOrEqual(summary.heartRateTrend, 12)
        XCTAssertTrue(summary.drivers.contains("睡眠不足"))
        XCTAssertTrue(summary.drivers.contains("心率趋势偏高"))
    }

    func testMissingSignalsUseConservativeHealthKitFallback() {
        let summary = HealthSummaryMapper.summary(from: .missing)

        XCTAssertEqual(summary, MockHealthProfiles.missing)

        let readiness = ReadinessEngine.evaluate(summary)
        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertTrue(readiness.explanation.contains("HealthKit 数据缺失"))
    }
```

- [ ] **Step 2: Run tests and confirm the new tests fail**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: failure because `HealthSignals` and `HealthSummaryMapper` do not exist yet.

- [ ] **Step 3: Create `HealthSignals.swift`**

Create `native/FitnessRPGCore/Sources/FitnessRPGCore/HealthSignals.swift`:

```swift
public struct HealthSignals: Equatable, Sendable {
    public let sleepHours: Double?
    public let hrvSDNN: Double?
    public let restingHeartRate: Double?
    public let restingHeartRateBaseline: Double?
    public let activeEnergyKcal: Double?
    public let exerciseMinutes: Double?
    public let stepCount: Double?
    public let workoutCount: Int?

    public init(
        sleepHours: Double?,
        hrvSDNN: Double?,
        restingHeartRate: Double?,
        restingHeartRateBaseline: Double?,
        activeEnergyKcal: Double?,
        exerciseMinutes: Double?,
        stepCount: Double?,
        workoutCount: Int?
    ) {
        self.sleepHours = sleepHours
        self.hrvSDNN = hrvSDNN
        self.restingHeartRate = restingHeartRate
        self.restingHeartRateBaseline = restingHeartRateBaseline
        self.activeEnergyKcal = activeEnergyKcal
        self.exerciseMinutes = exerciseMinutes
        self.stepCount = stepCount
        self.workoutCount = workoutCount
    }

    public static let missing = HealthSignals(
        sleepHours: nil,
        hrvSDNN: nil,
        restingHeartRate: nil,
        restingHeartRateBaseline: nil,
        activeEnergyKcal: nil,
        exerciseMinutes: nil,
        stepCount: nil,
        workoutCount: nil
    )
}

public enum HealthSummaryMapper {
    public static func summary(from signals: HealthSignals) -> HealthSummary {
        guard hasUsableData(signals) else {
            return MockHealthProfiles.missing
        }

        let sleep = sleepScore(hours: signals.sleepHours)
        let recovery = recoveryScore(
            hrvSDNN: signals.hrvSDNN,
            restingHeartRate: signals.restingHeartRate,
            baseline: signals.restingHeartRateBaseline
        )
        let strain = strainScore(
            activeEnergyKcal: signals.activeEnergyKcal,
            exerciseMinutes: signals.exerciseMinutes,
            stepCount: signals.stepCount,
            workoutCount: signals.workoutCount
        )
        let heartRateTrend = heartRateTrendScore(
            restingHeartRate: signals.restingHeartRate,
            baseline: signals.restingHeartRateBaseline
        )
        let energy = clamp((sleep + recovery + max(0, 100 - strain)) / 3)

        return HealthSummary(
            energy: energy,
            recovery: recovery,
            strain: strain,
            sleep: sleep,
            heartRateTrend: heartRateTrend,
            drivers: drivers(
                sleep: sleep,
                recovery: recovery,
                strain: strain,
                heartRateTrend: heartRateTrend
            )
        )
    }

    private static func hasUsableData(_ signals: HealthSignals) -> Bool {
        [
            signals.sleepHours,
            signals.hrvSDNN,
            signals.restingHeartRate,
            signals.activeEnergyKcal,
            signals.exerciseMinutes,
            signals.stepCount
        ].contains { $0 != nil } || signals.workoutCount != nil
    }

    private static func sleepScore(hours: Double?) -> Int {
        guard let hours else {
            return 55
        }

        if hours < 4.5 {
            return 38
        }

        if hours < 6 {
            return 52
        }

        if hours < 7 {
            return 66
        }

        if hours <= 9 {
            return 88
        }

        return 76
    }

    private static func recoveryScore(
        hrvSDNN: Double?,
        restingHeartRate: Double?,
        baseline: Double?
    ) -> Int {
        var components: [Int] = []

        if let hrvSDNN {
            components.append(clamp(Int((hrvSDNN / 70.0) * 90.0)))
        }

        if let restingHeartRate {
            let trendPenalty = heartRateTrendScore(restingHeartRate: restingHeartRate, baseline: baseline) * 3
            let absolutePenalty = restingHeartRate > 72 ? 18 : 0
            components.append(clamp(86 - trendPenalty - absolutePenalty))
        }

        guard !components.isEmpty else {
            return 55
        }

        return clamp(components.reduce(0, +) / components.count)
    }

    private static func strainScore(
        activeEnergyKcal: Double?,
        exerciseMinutes: Double?,
        stepCount: Double?,
        workoutCount: Int?
    ) -> Int {
        let energyLoad = normalizedLoad(value: activeEnergyKcal, green: 350, red: 900)
        let exerciseLoad = normalizedLoad(value: exerciseMinutes, green: 30, red: 95)
        let stepLoad = normalizedLoad(value: stepCount, green: 8000, red: 17000)
        let workoutLoad = clamp((workoutCount ?? 0) * 18)

        return clamp((energyLoad + exerciseLoad + stepLoad + workoutLoad) / 4)
    }

    private static func normalizedLoad(value: Double?, green: Double, red: Double) -> Int {
        guard let value else {
            return 45
        }

        if value <= green {
            return 45
        }

        if value >= red {
            return 90
        }

        return clamp(45 + Int(((value - green) / (red - green)) * 45.0))
    }

    private static func heartRateTrendScore(restingHeartRate: Double?, baseline: Double?) -> Int {
        guard let restingHeartRate else {
            return 0
        }

        if let baseline {
            return clamp(Int(max(0, restingHeartRate - baseline) * 2.0), upperBound: 25)
        }

        return clamp(Int(max(0, restingHeartRate - 65) * 1.5), upperBound: 25)
    }

    private static func drivers(
        sleep: Int,
        recovery: Int,
        strain: Int,
        heartRateTrend: Int
    ) -> [String] {
        var result: [String] = []

        result.append(sleep >= 75 ? "睡眠稳定" : "睡眠不足")
        result.append(recovery >= 70 ? "恢复良好" : "恢复偏低")

        if strain > 72 {
            result.append("昨日负荷偏高")
        } else {
            result.append("昨日负荷可控")
        }

        if heartRateTrend >= 12 {
            result.append("心率趋势偏高")
        }

        return result
    }

    private static func clamp(_ value: Int, upperBound: Int = 100) -> Int {
        max(0, min(upperBound, value))
    }
}
```

- [ ] **Step 4: Run core tests and confirm they pass**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: all tests pass, including 4 new mapper tests. Existing expected line should now report 10 tests with 0 failures.

- [ ] **Step 5: Commit core mapper**

Run:

```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/HealthSignals.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "feat: add health signal summary mapper"
```

---

### Task 2: Add iOS HealthKit Provider

**Files:**
- Create: `native/AppSources/iOS/HealthKit/HealthKitHealthSummaryProvider.swift`

- [ ] **Step 1: Create HealthKit provider directory**

Run:

```bash
mkdir -p native/AppSources/iOS/HealthKit
```

- [ ] **Step 2: Create `HealthKitHealthSummaryProvider.swift`**

Create `native/AppSources/iOS/HealthKit/HealthKitHealthSummaryProvider.swift`:

```swift
import Foundation
import HealthKit
import FitnessRPGCore

enum HealthKitHealthSummaryProviderError: Error, Equatable {
    case unavailable
    case authorizationFailed
}

final class HealthKitHealthSummaryProvider {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    init(healthStore: HKHealthStore = HKHealthStore(), calendar: Calendar = .current) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    func requestAuthorizationAndLoadSummary(referenceDate: Date = Date()) async -> HealthSummary {
        guard HKHealthStore.isHealthDataAvailable() else {
            return MockHealthProfiles.missing
        }

        do {
            try await requestAuthorization()
            let signals = await loadSignals(referenceDate: referenceDate)
            return HealthSummaryMapper.summary(from: signals)
        } catch {
            return MockHealthProfiles.missing
        }
    }

    private func requestAuthorization() async throws {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? HealthKitHealthSummaryProviderError.authorizationFailed)
                }
            }
        }
    }

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.workoutType()
        ].compactMap { $0 }.forEach { types.insert($0) }

        return types
    }

    private func loadSignals(referenceDate: Date) async -> HealthSignals {
        async let sleepHours = sleepHours(endingAt: referenceDate)
        async let hrvSDNN = mostRecentQuantity(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), endingAt: referenceDate)
        async let restingHeartRate = mostRecentQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), endingAt: referenceDate)
        async let restingHeartRateBaseline = averageQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), days: 7, endingAt: referenceDate)
        async let activeEnergy = sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), days: 1, endingAt: referenceDate)
        async let exerciseMinutes = sumQuantity(.appleExerciseTime, unit: .minute(), days: 1, endingAt: referenceDate)
        async let stepCount = sumQuantity(.stepCount, unit: .count(), days: 1, endingAt: referenceDate)
        async let workoutCount = workoutCount(days: 1, endingAt: referenceDate)

        return await HealthSignals(
            sleepHours: sleepHours,
            hrvSDNN: hrvSDNN,
            restingHeartRate: restingHeartRate,
            restingHeartRateBaseline: restingHeartRateBaseline,
            activeEnergyKcal: activeEnergy,
            exerciseMinutes: exerciseMinutes,
            stepCount: stepCount,
            workoutCount: workoutCount
        )
    }

    private func sleepHours(endingAt endDate: Date) async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate.addingTimeInterval(-86_400)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let categorySamples = samples as? [HKCategorySample] ?? []
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let seconds = categorySamples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { partial, sample in
                        partial + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                continuation.resume(returning: seconds > 0 ? seconds / 3600.0 : nil)
            }

            healthStore.execute(query)
        }
    }

    private func mostRecentQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, endingAt endDate: Date) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate.addingTimeInterval(-604_800)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func averageQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, days: Int, endingAt endDate: Date) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate.addingTimeInterval(Double(-days * 86_400))
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, _ in
                continuation.resume(returning: statistics?.averageQuantity()?.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    private func sumQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, days: Int, endingAt endDate: Date) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate.addingTimeInterval(Double(-days * 86_400))
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    private func workoutCount(days: Int, endingAt endDate: Date) async -> Int? {
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate.addingTimeInterval(Double(-days * 86_400))
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: samples?.count)
            }

            healthStore.execute(query)
        }
    }
}
```

- [ ] **Step 3: Do not compile yet**

This file is not part of the Xcode project until Task 4. Do not expect `xcodebuild` to compile it before project wiring.

- [ ] **Step 4: Commit provider source**

Run:

```bash
git add native/AppSources/iOS/HealthKit/HealthKitHealthSummaryProvider.swift
git commit -m "feat: add readonly healthkit provider"
```

---

### Task 3: Connect iOS App State To Health Summaries

**Files:**
- Create: `native/AppSources/iOS/TodayHealthViewModel.swift`
- Modify: `native/AppSources/iOS/FitnessRPGApp.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`

- [ ] **Step 1: Create `TodayHealthViewModel.swift`**

Create `native/AppSources/iOS/TodayHealthViewModel.swift`:

```swift
import Combine
import Foundation
import FitnessRPGCore

@MainActor
final class TodayHealthViewModel: ObservableObject {
    @Published private(set) var healthSummary: HealthSummary
    @Published private(set) var sourceNote: String

    private let provider: HealthKitHealthSummaryProvider

    init(
        provider: HealthKitHealthSummaryProvider = HealthKitHealthSummaryProvider(),
        initialSummary: HealthSummary = MockHealthProfiles.missing
    ) {
        self.provider = provider
        self.healthSummary = initialSummary
        self.sourceNote = "正在读取 HealthKit，暂使用保守黄灯。"
    }

    var readiness: ReadinessResult {
        ReadinessEngine.evaluate(healthSummary)
    }

    func loadHealthSummary() async {
        sourceNote = "正在请求 HealthKit 读取权限。"
        let summary = await provider.requestAuthorizationAndLoadSummary()
        healthSummary = summary

        if summary.drivers.contains("HealthKit 数据缺失") {
            sourceNote = "HealthKit 数据不可用或不足，已使用保守黄灯。"
        } else {
            sourceNote = "已根据 Apple Health 数据生成今日状态。"
        }
    }
}
```

- [ ] **Step 2: Update `FitnessRPGApp.swift`**

Replace the file with:

```swift
import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGApp: App {
    @StateObject private var healthViewModel = TodayHealthViewModel()

    var body: some Scene {
        WindowGroup {
            TodayCommandCenterView(
                readiness: healthViewModel.readiness,
                modelMode: .localFirst,
                sourceNote: healthViewModel.sourceNote
            )
            .task {
                await healthViewModel.loadHealthSummary()
            }
        }
    }
}
```

- [ ] **Step 3: Update `TodayCommandCenterView.swift`**

Replace the file with:

```swift
import SwiftUI
import FitnessRPGCore

struct TodayCommandCenterView: View {
    let readiness: ReadinessResult
    let modelMode: ModelMode
    let sourceNote: String?

    private var quest: DailyQuest {
        QuestEngine.quest(for: readiness, storyNode: "回声训练厅")
    }

    private var harness: ModelHarnessSnapshot {
        ModelHarnessBuilder.snapshot(
            readiness: readiness,
            quest: quest,
            mode: modelMode,
            logs: []
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("今日任务中枢")
                            .font(.largeTitle.bold())
                        Text("iPhone 是大脑，Apple Watch 是执行面。")
                            .foregroundStyle(.secondary)

                        if let sourceNote {
                            Text(sourceNote)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ReadinessPanel(readiness: readiness)
                    QuestPanel(quest: quest)
                    ModelHarnessPanel(snapshot: harness)
                }
                .padding()
            }
            .navigationTitle("Fitness RPG")
        }
    }
}

#Preview {
    TodayCommandCenterView(
        readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
        modelMode: .localFirst,
        sourceNote: "预览使用 mock health summary。"
    )
}
```

- [ ] **Step 4: Commit app state changes**

Run:

```bash
git add native/AppSources/iOS/TodayHealthViewModel.swift native/AppSources/iOS/FitnessRPGApp.swift native/AppSources/iOS/TodayCommandCenterView.swift
git commit -m "feat: connect ios app to health summary state"
```

---

### Task 4: Wire HealthKit Into The Xcode Project

**Files:**
- Create: `native/AppSources/iOS/FitnessRPG.entitlements`
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create the iOS HealthKit entitlements file**

Create `native/AppSources/iOS/FitnessRPG.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.healthkit</key>
	<true/>
</dict>
</plist>
```

- [ ] **Step 2: Add new file references to the iOS group**

Modify `native/FitnessRPG.xcodeproj/project.pbxproj`:

- Add `PBXBuildFile` entries for:
  - `HealthKitHealthSummaryProvider.swift in Sources`
  - `TodayHealthViewModel.swift in Sources`
  - `HealthKit.framework in Frameworks`
- Add `PBXFileReference` entries for:
  - `TodayHealthViewModel.swift`
  - `HealthKitHealthSummaryProvider.swift`
  - `FitnessRPG.entitlements`
  - `HealthKit.framework`
- Add a `HealthKit` subgroup under the existing iOS group containing `HealthKitHealthSummaryProvider.swift`.
- Add `TodayHealthViewModel.swift`, `FitnessRPG.entitlements`, and the new `HealthKit` subgroup to the existing iOS group.
- Add `HealthKit.framework` to the root group or a `Frameworks` group.

Use new deterministic 24-character object ids that do not collide with existing ids. Keep the existing hand-authored project style.

- [ ] **Step 3: Add new files to the iOS target only**

Modify the iOS target build phases:

- Add `TodayHealthViewModel.swift in Sources` to `01D000000000000000000003 /* Sources */`.
- Add `HealthKitHealthSummaryProvider.swift in Sources` to `01D000000000000000000003 /* Sources */`.
- Add `HealthKit.framework in Frameworks` to `01D000000000000000000001 /* Frameworks */`.

Do not add these files or HealthKit.framework to the watchOS build phases.

- [ ] **Step 4: Add iOS build settings for HealthKit**

Add these settings to both iOS target configurations `01AA00000000000000000006 /* Debug */` and `01AA00000000000000000007 /* Release */`:

```text
CODE_SIGN_ENTITLEMENTS = AppSources/iOS/FitnessRPG.entitlements;
INFOPLIST_KEY_NSHealthShareUsageDescription = "Fitness RPG uses Apple Health data to estimate readiness and adapt training intensity.";
```

Do not add `NSHealthUpdateUsageDescription` because this pass does not write HealthKit data.

- [ ] **Step 5: Verify the iOS project references**

Run:

```bash
rg -n "HealthKitHealthSummaryProvider|TodayHealthViewModel|FitnessRPG.entitlements|HealthKit.framework|NSHealthShareUsageDescription|CODE_SIGN_ENTITLEMENTS" native/FitnessRPG.xcodeproj/project.pbxproj native/AppSources/iOS/FitnessRPG.entitlements
```

Expected: output shows the new source files in iOS file references/build phases, HealthKit framework in iOS frameworks, and iOS entitlements/settings.

- [ ] **Step 6: Build iOS and watchOS targets**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

Expected: both commands end with `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit Xcode wiring**

Run:

```bash
git add native/FitnessRPG.xcodeproj/project.pbxproj native/AppSources/iOS/FitnessRPG.entitlements
git commit -m "build: wire healthkit into ios target"
```

---

### Task 5: Document HealthKit MVP

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [ ] **Step 1: Update root README native status**

In `README.md`, extend the native status section with:

```text
The iOS target includes a read-only HealthKit MVP that maps available Apple Health data into `HealthSummary`. Missing or denied data falls back to the conservative yellow readiness path.
```

- [ ] **Step 2: Update `native/README.md` integration status**

In `native/README.md`, add a short section:

```markdown
## HealthKit MVP

The iOS target requests read-only HealthKit access for sleep, heart-rate, activity, and workout signals. The app maps available samples into `HealthSummary` and falls back to conservative yellow readiness when HealthKit is unavailable, denied, or incomplete.

The watchOS target does not read HealthKit in this pass.
```

- [ ] **Step 3: Verify docs references**

Run:

```bash
rg -n "HealthKit MVP|read-only HealthKit|HealthSummary|conservative yellow|FitnessRPG.xcodeproj" README.md native/README.md
```

Expected: output includes the HealthKit MVP text and existing Xcode build references.

- [ ] **Step 4: Commit docs**

Run:

```bash
git add README.md native/README.md
git commit -m "docs: document healthkit readonly mvp"
```

---

### Task 6: Final Verification

**Files:**
- No planned file edits.

- [ ] **Step 1: Run Swift Package tests**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: all tests pass, including the new mapper tests, with 0 failures.

- [ ] **Step 2: Run iOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Expected final output:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 3: Run watchOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

Expected final output:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 4: Run browser prototype checks**

Run from the repository root:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node --check prototype/src/execution.js
node --check prototype/src/modelHarness.js
node prototype/tests/prototypeContract.test.mjs
```

Expected final output includes:

```text
prototype contract ok
```

- [ ] **Step 5: Confirm no HealthKit leakage into watchOS/core frameworks**

Run:

```bash
rg -n "import HealthKit|HealthKit.framework|NSHealthShareUsageDescription|com.apple.developer.healthkit" native
```

Expected:

- `import HealthKit` only appears in `native/AppSources/iOS/HealthKit/HealthKitHealthSummaryProvider.swift`.
- `HealthKit.framework`, `NSHealthShareUsageDescription`, and `com.apple.developer.healthkit` appear only in iOS project/entitlement files.
- No watchOS Swift file imports HealthKit.

- [ ] **Step 6: Confirm clean status**

Run:

```bash
git status --short
```

Expected: no output.

---

## Final Verification Checklist

- `HealthSignals` and `HealthSummaryMapper` exist in `FitnessRPGCore`.
- Mapper tests cover green-leaning, yellow-leaning, red-leaning, and missing-data summaries.
- iOS-only HealthKit provider requests read access only and returns conservative fallback on failure.
- iOS app no longer hardcodes `MockHealthProfiles.green` at launch.
- Raw HealthKit samples are not passed to prompts or narrative generation.
- iOS target links HealthKit and has HealthKit read usage text and entitlement.
- watchOS target still builds and does not link or import HealthKit.
- `swift test`, iOS build, watchOS build, and prototype checks pass.
- Worktree is clean.
