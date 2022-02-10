import UIKit
import HealthKit

class HealthStore {

    private let healthStore = HKHealthStore()
    private let bodyMassType = HKSampleType.quantityType(forIdentifier: .bodyMass)!

    func authorizeHealthKit(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {

        if !HKHealthStore.isHealthDataAvailable() {
            return
        }

        let readDataTypes: Set<HKSampleType> = [bodyMassType]

        healthStore.requestAuthorization(toShare: nil, read: readDataTypes) { (success, error) in
            completion(success, error)
        }

    }


    //returns the weight entry in Kilos or nil if no data
    func bodyMassKg(completion: @escaping ((_ bodyMass: Double?, _ date: Date?) -> Void)) {

        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, results, error) in
            if let result = results?.first as? HKQuantitySample {
                let bodyMassKg = result.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                completion(bodyMassKg, result.endDate)
                return
            }

            //no data
            completion(nil, nil)
        }
        healthStore.execute(query)
    }

}
