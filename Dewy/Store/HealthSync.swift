import Foundation
import HealthKit

/// Apple Health sync: every logged drink is written as Dietary Water (tagged with the entry's id,
/// so undo deletes exactly that sample) and body weight is read back to tune the daily goal.
@MainActor
enum HealthSync {
    private static let store = HKHealthStore()
    private static let water = HKQuantityType(.dietaryWater)
    private static let weight = HKQuantityType(.bodyMass)

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Asks for permission. Returns whether the request went through (not whether every type was granted).
    static func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [water], read: [water, weight])
            return true
        } catch {
            return false
        }
    }

    static func write(_ entry: DrinkEntry) {
        guard isAvailable else { return }
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: entry.effective)
        let sample = HKQuantitySample(
            type: water,
            quantity: quantity,
            start: entry.date,
            end: entry.date,
            metadata: [
                HKMetadataKeySyncIdentifier: entry.id.uuidString,
                HKMetadataKeySyncVersion: 1,
                "DewyDrink": entry.kind.rawValue
            ]
        )
        store.save(sample) { _, _ in }
    }

    static func delete(_ entry: DrinkEntry) {
        guard isAvailable else { return }
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier, allowedValues: [entry.id.uuidString])
        store.deleteObjects(of: water, predicate: predicate) { _, _, _ in }
    }

    /// The most recent body weight in kilograms, if Health has one.
    static func latestWeight() async -> Double? {
        guard isAvailable else { return nil }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: weight, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }
}
