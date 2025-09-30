//
//  HKimporter.swift
//  HealthKitImporter
//
//  Created by boaz saragossi on 11/7/17.
//  Copyright © 2017 boaz saragossi. All rights reserved.
//

import UIKit
import HealthKit
import CoreLocation
// 需要在 Xcode 中手动添加 CoreGPX 包依赖
// File -> Add Package Dependencies -> https://github.com/vincentneo/CoreGPX
// import CoreGPX

extension CustomStringConvertible {
    var description : String {
        var description: String = ""
        //if self is AnyObject {
        //    description = "***** \(type(of: self)) - <\(unsafeAddressOf((self as AnyObject)))>***** \n"
        //} else {
        description = "***** \(type(of: self)) *****\n"
        //}
        let selfMirror = Mirror(reflecting: self)
        for child in selfMirror.children {
            if let propertyName = child.label {
                description += "\(propertyName): \(child.value)\n"
            }
        }
        return description
    }
}

class HKRecord: CustomStringConvertible {
    var type: String = String()
    var value: Double = 0
    var unit: String?
    var sourceName: String = String()
    var sourceVersion: String = String()
    var startDate: Date = Date()
    var endDate: Date = Date()
    var creationDate: Date = Date()
    
    //for workouts
    var activityType: HKWorkoutActivityType? = HKWorkoutActivityType(rawValue: 0)
    var totalEnergyBurned: Double = 0
    var totalDistance: Double = 0
    var totalEnergyBurnedUnit: String = String()
    var totalDistanceUnit: String = String()
    
    // for workout routes
    var routeFilePath: String?
    
    var metadata = [String:Any]()
}

class HKimporter : NSObject, XMLParserDelegate {
    
    var healthStore:HKHealthStore?
    
    var allHKRecords: [HKRecord] = []
    var allHKSampels: [HKSample] = []
    
    var eName: String = String()
    var currRecord: HKRecord = HKRecord.init()
    
    var readCounterLabel: UILabel? = nil
    var writeCounterLabel: UILabel? = nil
    
    var activityTypeFilter:[HKWorkoutActivityType]?
    var workoutSourceNameFilter:[String]?
    
    
    convenience init(completion:@escaping ()->Void) {
        
        self.init()
        
        self.healthStore = HKHealthStore.init()
        
        let shareReadObjectTypes:Set<HKSampleType>? = [
            HKQuantityType.quantityType(forIdentifier:HKQuantityTypeIdentifier.stepCount)!,
            HKQuantityType.quantityType(forIdentifier:HKQuantityTypeIdentifier.flightsClimbed)!,
            // Body Measurements
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)!,
            // Nutrient
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!,
            //                        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatSaturated)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!,
            //                        HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!,
            // Fitness
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
            HKWorkoutType.workoutType(),
            // Category
            HKQuantityType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!,
            
            //Heart rate
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)!,
            
            // Measurements
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.leanBodyMass)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!,
            // Nutrients
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatMonounsaturated)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatSaturated)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCholesterol)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySodium)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFiber)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminA)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminB6)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminB12)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminC)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminD)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminE)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryVitaminK)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCalcium)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryIron)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryThiamin)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryRiboflavin)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryNiacin)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFolate)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryBiotin)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryPantothenicAcid)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryPhosphorus)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryIodine)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryMagnesium)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryZinc)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySelenium)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCopper)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryManganese)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryChromium)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryMolybdenum)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryChloride)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryPotassium)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCaffeine)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.uvExposure)!,
            // Fitness
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed)!,
            // Results
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyTemperature)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalBodyTemperature)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodAlcoholContent)!,
            HKSeriesType.workoutRoute(),
        ]
        
        self.healthStore?.requestAuthorization(toShare: shareReadObjectTypes, read: shareReadObjectTypes, completion: { (res, error) in
            if let error = error {
                print(error)
            } else {
                completion()
            }
        })
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
       // print("🔍 开始解析元素: \(elementName)")
        
        if elementName == "Record" {
            print("📊 处理 Record 类型: \(attributeDict["type"] ?? "未知")")
            print("📊 Record 属性: \(attributeDict)")
            currRecord.type = attributeDict["type"]!
            currRecord.sourceName = attributeDict["sourceName"] ??  ""
            currRecord.sourceVersion = attributeDict["sourceVersion"] ??  ""
            currRecord.value = Double(attributeDict["value"] ?? "0") ?? 0
            currRecord.unit = attributeDict["unit"] ?? ""
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd hh:mm:ss Z"
            if let date = formatter.date(from: attributeDict["startDate"]!) {
                currRecord.startDate = date
            }
            if let date = formatter.date(from: attributeDict["endDate"]!){
                currRecord.endDate = date
            }
            
            if currRecord.startDate >  currRecord.endDate {
                currRecord.startDate = currRecord.endDate
            }
            
            if let date = formatter.date(from: attributeDict["creationDate"]!){
                currRecord.creationDate = date
            }
        } else if elementName == "MetadataEntry" {
            //currRecord.metadata = attributeDict
            var key:String?
            var value:Any?
            for (k,v) in attributeDict {
                if(k == "key"){
                    key = v
                }
                if(k == "value"){
                    if let intValue = Int(v){
                        value = intValue
                    } else {
                        value = v
                    }
                }
            }
            if let key = key, let value = value {
                //TODO:NEED 暂时不塞了
               // currRecord.metadata[key] = value
                print(currRecord.metadata)
            }
            
        } else if elementName == "Workout" {
            print("🏃 处理 Workout 类型: \(attributeDict["workoutActivityType"] ?? "未知")")
            print("🏃 Workout 属性: \(attributeDict)")
            currRecord.type = HKObjectType.workoutType().identifier
            currRecord.activityType = activityByName(activityName: attributeDict["workoutActivityType"] ?? "")
            currRecord.sourceName = attributeDict["sourceName"] ??  ""
            currRecord.sourceVersion = attributeDict["sourceVersion"] ??  ""
            currRecord.value = Double(attributeDict["duration"] ?? "0") ?? 0
            currRecord.unit = attributeDict["durationUnit"] ?? ""
            
            //currRecord.totalDistance = Double(attributeDict["totalDistance"] ?? "0") ?? 0
            //currRecord.totalDistanceUnit = attributeDict["totalDistanceUnit"] ??  ""
            //currRecord.totalEnergyBurned = Double(attributeDict["totalEnergyBurned"] ?? "0") ?? 0
            //currRecord.totalEnergyBurnedUnit = attributeDict["totalEnergyBurnedUnit"] ??  ""
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd hh:mm:ss Z"
            if let date = formatter.date(from: attributeDict["startDate"]!) {
                currRecord.startDate = date
            }
            if let date = formatter.date(from: attributeDict["endDate"]!){
                currRecord.endDate = date
            }
            
            if currRecord.startDate >  currRecord.endDate {
                currRecord.startDate = currRecord.endDate
            }
            
            if let date = formatter.date(from: attributeDict["creationDate"]!){
                currRecord.creationDate = date
            }
        }
        else if elementName == "WorkoutStatistics" {
            /*
             <WorkoutStatistics type="HKQuantityTypeIdentifierActiveEnergyBurned" startDate="2024-10-12 07:05:28 +0800" endDate="2024-10-12 09:08:05 +0800" sum="848.567" unit="kcal"/>
  <WorkoutStatistics type="HKQuantityTypeIdentifierHeartRate" startDate="2024-10-12 07:05:28 +0800" endDate="2024-10-12 09:08:05 +0800" average="144.304" minimum="92" maximum="165" unit="count/min"/>
  <WorkoutStatistics type="HKQuantityTypeIdentifierDistanceCycling" startDate="2024-10-12 07:05:28 +0800" endDate="2024-10-12 09:08:05 +0800" sum="37.0543" unit="km"/>
  */
            if(attributeDict["type"] == "HKQuantityTypeIdentifierDistanceCycling" || attributeDict["type"] == "HKQuantityTypeIdentifierDistanceWalkingRunning" || attributeDict["type"] == "HKQuantityTypeIdentifierDistanceHiking" || attributeDict["type"] == "HKQuantityTypeIdentifierDistanceRunning"){
                currRecord.totalDistance = Double(attributeDict["sum"] ?? "0") ?? 0
                currRecord.totalDistanceUnit = attributeDict["unit"] ?? ""
            }
            if(attributeDict["type"] == "HKQuantityTypeIdentifierActiveEnergyBurned"){
                currRecord.totalEnergyBurned = Double(attributeDict["sum"] ?? "0") ?? 0
                currRecord.totalEnergyBurnedUnit = attributeDict["unit"] ?? ""
            }

        }
        else if elementName == "WorkoutRoute" {
            print("🗺️ 处理 WorkoutRoute 元素")
            // WorkoutRoute 开始，不需要特殊处理，只是标记
            return
        }
        else if elementName == "FileReference" {
            print("📁 处理 FileReference 元素")
            // 解析 FileReference 的 path 属性
            if let path = attributeDict["path"] {
                currRecord.routeFilePath = path
                print("🗺️ 找到路由文件路径: \(path)")
            }
        }
        else if elementName == "Correlation" {
            return
        } else {
            return
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("✅ 结束解析元素: \(elementName)")
        
        if elementName == "Record" {
            
            print("📊 完成 Record 解析，准备保存")
            print("📊 Record 详情 - 类型: \(currRecord.type), 来源: \(currRecord.sourceName)")
            allHKRecords.append(currRecord)
            print("📝 已添加 Record 到记录列表，当前总数: \(allHKRecords.count)")
            DispatchQueue.main.async {
                self.readCounterLabel?.text = "\(self.allHKRecords.count)"
            }
            
        }
        
         else if elementName == "Workout" {
            print("🏃 完成 Workout 解析，准备保存")
            print("🏃 Workout 详情 - 类型: \(currRecord.type), 活动: \(currRecord.activityType?.rawValue ?? 0), 来源: \(currRecord.sourceName)")
            // filter you need
            if let typeFilter = self.activityTypeFilter {
                let ret = typeFilter.first(where: {$0 == currRecord.activityType})
                if(ret == nil){
                    return
                }
            }
            allHKRecords.append(currRecord)
            print("📝 已添加到记录列表，当前总数: \(allHKRecords.count)")
            print("📝 记录详情: \(currRecord.description)")
            DispatchQueue.main.async {
                self.readCounterLabel?.text = "\(self.allHKRecords.count)"
            }
            
            // 如果没有设置来源过滤器，或者当前来源在过滤列表中，则保存记录
            if self.workoutSourceNameFilter == nil || self.workoutSourceNameFilter?.contains(currRecord.sourceName) == true {
                print("✅ 来源过滤通过: \(currRecord.sourceName)")
                
                saveHKRecord(item: currRecord, withSuccess: {
                    // success
                    print("success to saveHKRecord")
                }, failure: {
                    // fail
                    print("fail to process record")
                })
            } else {
                print("❌ 来源被过滤: \(currRecord.sourceName)")
            }
        }
        
    }
    
    func saveHKRecord(item:HKRecord, withSuccess successBlock: @escaping () -> Void, failure failiureBlock: @escaping () -> Void) {
        
        let unit = HKUnit.init(from: item.unit!)
        let quantity = HKQuantity(unit: unit, doubleValue: item.value)
        
        var hkSample: HKSample? = nil
        if let type = HKQuantityType.quantityType(forIdentifier:  HKQuantityTypeIdentifier(rawValue: item.type)) {
            hkSample = HKQuantitySample.init(type: type, quantity: quantity, start: item.startDate, end: item.endDate, metadata: item.metadata)
        } else if let type = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: item.type)) {
            hkSample = HKCategorySample.init(type: type, value: Int(item.value), start: item.startDate, end: item.endDate, metadata: item.metadata)
        } else if item.type == HKObjectType.workoutType().identifier {
            var caUnit =  HKUnit.kilocalorie()
            if(item.totalEnergyBurnedUnit.isEmpty == false){
                caUnit = HKUnit.init(from: item.totalEnergyBurnedUnit)
            }
            var lenUnit = HKUnit.meter()
            if(item.totalDistanceUnit.isEmpty == false){
                lenUnit = HKUnit.init(from: item.totalDistanceUnit)
            }
            //duration 单位是秒，请将item.value转换为秒,因为 unit 单位有可能是 min
            if(item.unit == "min"){
                item.value = item.value * 60
            }

            hkSample = HKWorkout.init(activityType: item.activityType!, start: item.startDate, end: item.endDate, duration: item.value, totalEnergyBurned: HKQuantity(unit: caUnit, doubleValue: item.totalEnergyBurned), totalDistance: HKQuantity(unit: lenUnit, doubleValue: item.totalDistance), device: HKDevice.local(), metadata: item.metadata)
            
            // 如果有路由文件路径，异步处理路由数据
            if let routePath = item.routeFilePath, let workout = hkSample as? HKWorkout {
                print("开始处理 workout 路由: \(routePath)")
                Task {
                    await processWorkoutRoute(for: workout, routePath: routePath)
                }
            }
        } else {
            print("didnt catch this item - \(item)")
        }
        
        if let hkSample = hkSample, (self.healthStore?.authorizationStatus(for: hkSample.sampleType) == HKAuthorizationStatus.sharingAuthorized) {
            allHKSampels.append(hkSample)
            successBlock()
        } else {
            failiureBlock()
        }
    }
    
    func saveAllSamples() {
        saveSamplesToHK(samples: self.allHKSampels, withSuccess: {
            //
        }, failure: {
            //
        })
    }
    func saveSamplesToHK (samples:[HKSample], withSuccess successBlock: @escaping () -> Void, failure failiureBlock: @escaping () -> Void) {
        self.healthStore?.save(samples, withCompletion: { (success, error) in
            if (!success) {
                print(String(format: "An error occured saving the sample. The error was: %@.", error.debugDescription))
                failiureBlock()
            }
            DispatchQueue.main.async {
                self.writeCounterLabel?.text = "\(Int((self.writeCounterLabel?.text)!)! + samples.count)"
            }
            successBlock()
        })
    }
    
    func activityByName(activityName: String) -> HKWorkoutActivityType {
        print("🏃 解析活动类型: \(activityName)")
        var res = HKWorkoutActivityType(rawValue: 0)
        switch activityName {
        case "HKWorkoutActivityTypeWalking":
            res = HKWorkoutActivityType.walking
        case "HKWorkoutActivityTypeRunning":
            res = HKWorkoutActivityType.running
        case "HKWorkoutActivityTypeCycling":
            res = HKWorkoutActivityType.cycling
        case "HKWorkoutActivityTypeMixedMetabolicCardioTraining":
            res = HKWorkoutActivityType.mixedMetabolicCardioTraining
        case "HKWorkoutActivityTypeYoga":
            res = HKWorkoutActivityType.yoga
        case "HKWorkoutActivityTypeTraditionalStrengthTraining":
            res = HKWorkoutActivityType.traditionalStrengthTraining
        case "HKWorkoutActivityTypeDance":
            res = HKWorkoutActivityType.dance
        case "HKWorkoutActivityTypeJumpRope":
            res = HKWorkoutActivityType.jumpRope
        case "HKWorkoutActivityTypeSwimming":
            res = HKWorkoutActivityType.swimming
        case "HKWorkoutActivityTypeHiking":
            res = HKWorkoutActivityType.hiking
        default:
            print ("❌ 未知活动类型: \(activityName)")
            print ("💡 需要添加对活动类型的支持: \(activityName)")
            break;
        }
        return res!
    }
    
    // MARK: - Route Processing Methods
    
    /// 从 GPX 文件路径解析位置数据
    /// - Parameter routeFilePath: GPX 文件的相对路径，例如 "/workout-routes/route_2024-11-26_1.12pm.gpx"
    /// - Returns: CLLocation 数组，如果解析失败则返回 nil
    func parseGPXFile(from routeFilePath: String) -> [CLLocation]? {
        // 从路径中提取文件名（去掉文件夹路径）
        let fileName = URL(fileURLWithPath: routeFilePath).lastPathComponent
        let fileNameWithoutExtension = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        
        print("尝试查找 GPX 文件: \(fileName)")
        
        // 首先尝试在主 bundle 中查找文件（不需要文件夹路径）
        if let bundlePath = Bundle.main.path(forResource: fileNameWithoutExtension, ofType: "gpx") {
            print("在 Bundle 中找到文件: \(bundlePath)")
            return parseGPXFromPath(bundlePath)
        }
        
        // 如果没找到，尝试在 Documents 目录中查找（保持原始路径结构）
        let cleanPath = routeFilePath.hasPrefix("/") ? String(routeFilePath.dropFirst()) : routeFilePath
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fullPath = documentsPath + "/" + cleanPath
        
        if FileManager.default.fileExists(atPath: fullPath) {
            print("在 Documents 目录中找到文件: \(fullPath)")
            return parseGPXFromPath(fullPath)
        }
        
        print("GPX 文件未找到: \(fileName) (尝试了 Bundle 和 Documents 目录)")
        return nil
    }
    
    /// 从文件路径解析 GPX 数据
    /// - Parameter filePath: GPX 文件的完整路径
    /// - Returns: CLLocation 数组
    private func parseGPXFromPath(_ filePath: String) -> [CLLocation]? {
        let fileURL = URL(fileURLWithPath: filePath)
        // 临时实现：解析基本的 GPX XML 格式
        return parseGPXManually(from: fileURL)
    }
    
    /// 手动解析 GPX 文件（临时实现，直到添加 CoreGPX 依赖）
    private func parseGPXManually(from fileURL: URL) -> [CLLocation]? {
        guard let data = try? Data(contentsOf: fileURL) else {
            print("无法读取 GPX 文件数据")
            return nil
        }
        
        let parser = XMLParser(data: data)
        let delegate = GPXParserDelegate()
        parser.delegate = delegate
        
        guard parser.parse() else {
            print("GPX XML 解析失败")
            return nil
        }
        
        print("从 GPX 文件解析到 \(delegate.locations.count) 个位置点")
        return delegate.locations
    }
    
    /// 将路由数据添加到 workout 中
    /// - Parameters:
    ///   - workout: 要添加路由的 workout
    ///   - locations: GPS 位置数组
    public func addRouteToWorkout(_ workout: HKWorkout, locations: [CLLocation]) async throws {
        guard !locations.isEmpty else {
            print("位置数据为空，跳过路由添加")
            return
        }
        
        guard let healthStore = self.healthStore else {
            throw NSError(domain: "HealthStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthStore 未初始化"])
        }
        
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        
        // 添加位置数据
        try await routeBuilder.insertRouteData(locations)
        
        // 完成 route 并关联到 workout
        let route = try await routeBuilder.finishRoute(with: workout, metadata: nil)
        print("成功为 workout 添加路由，包含 \(locations.count) 个位置点: \(route)")
    }
    
    /// 异步处理 workout 路由数据
    /// - Parameters:
    ///   - workout: 要添加路由的 workout
    ///   - routePath: GPX 文件路径
    private func processWorkoutRoute(for workout: HKWorkout, routePath: String) async {
        do {
            // 解析 GPX 文件获取位置数据
            guard let locations = parseGPXFile(from: routePath) else {
                print("无法从路径解析 GPX 文件: \(routePath)")
                return
            }
            
            // 添加路由到 workout
            try await addRouteToWorkout(workout, locations: locations)
            
            print("成功处理 workout 路由，路径: \(routePath)")
        } catch {
            print("处理 workout 路由时出错: \(error.localizedDescription)")
        }
    }
}

// MARK: - GPX Parser Delegate

/// 简单的 GPX XML 解析委托（临时实现）
private class GPXParserDelegate: NSObject, XMLParserDelegate {
    var locations: [CLLocation] = []
    private var currentElement: String = ""
    private var currentLatitude: Double?
    private var currentLongitude: Double?
    private var currentElevation: Double?
    private var currentTime: Date?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "trkpt" {
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                currentLatitude = lat
                currentLongitude = lon
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch currentElement {
        case "ele":
            if let elevation = Double(trimmed) {
                currentElevation = elevation
            }
        case "time":
            currentTime = dateFormatter.date(from: trimmed)
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "trkpt" {
            if let lat = currentLatitude, let lon = currentLongitude {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let altitude = currentElevation ?? 0
                let timestamp = currentTime ?? Date()
                
                let location = CLLocation(
                    coordinate: coordinate,
                    altitude: altitude,
                    horizontalAccuracy: kCLLocationAccuracyBest,
                    verticalAccuracy: kCLLocationAccuracyBest,
                    timestamp: timestamp
                )
                
                locations.append(location)
            }
            
            // 重置当前数据
            currentLatitude = nil
            currentLongitude = nil
            currentElevation = nil
            currentTime = nil
        }
        
        currentElement = ""
    }
}
