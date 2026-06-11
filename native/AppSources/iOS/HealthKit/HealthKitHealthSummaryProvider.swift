import Foundation
import HealthKit
import FitnessRPGCore

enum HealthKitHealthSummaryProviderError: Error, Equatable {
    case unavailable
    case authorizationFailed
}

struct HealthKitHealthSummaryLoadResult: Equatable {
    let summary: HealthSummary
    let sourceSnapshot: HealthDataSourceSnapshot
}

@MainActor
final class HealthKitHealthSummaryProvider {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    init(healthStore: HKHealthStore = HKHealthStore(), calendar: Calendar = .current) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    func requestAuthorizationAndLoadSummary(referenceDate: Date = Date()) async -> HealthSummary {
        await requestAuthorizationAndLoadResult(referenceDate: referenceDate).summary
    }

    func requestAuthorizationAndLoadResult(referenceDate: Date = Date()) async -> HealthKitHealthSummaryLoadResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            return HealthKitHealthSummaryLoadResult(
                summary: MockHealthProfiles.missing,
                sourceSnapshot: .unavailable
            )
        }

        do {
            try await requestAuthorization()
            let signals = await loadSignals(referenceDate: referenceDate)
            let summary = HealthSummaryMapper.summary(from: signals)
            let sourceSnapshot: HealthDataSourceSnapshot

            if summary.drivers.contains("HealthKit 数据缺失") {
                sourceSnapshot = HealthDataSourceSnapshot(
                    status: .insufficientData,
                    missingSignalLabels: missingSignalLabels(from: signals)
                )
            } else {
                sourceSnapshot = .healthKit
            }

            return HealthKitHealthSummaryLoadResult(
                summary: summary,
                sourceSnapshot: sourceSnapshot
            )
        } catch {
            return HealthKitHealthSummaryLoadResult(
                summary: MockHealthProfiles.missing,
                sourceSnapshot: .authorizationDenied
            )
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

    private func missingSignalLabels(from signals: HealthSignals) -> [String] {
        var labels: [String] = []

        if signals.sleepHours == nil {
            labels.append("睡眠")
        }

        if signals.hrvSDNN == nil && signals.restingHeartRate == nil {
            labels.append("恢复")
        }

        let hasActivity = [
            signals.activeEnergyKcal,
            signals.exerciseMinutes,
            signals.stepCount
        ].contains { $0 != nil } || signals.workoutCount != nil

        if !hasActivity {
            labels.append("活动")
        }

        return labels
    }
}
