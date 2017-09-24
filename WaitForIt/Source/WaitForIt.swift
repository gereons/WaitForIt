//
//  WaitForIt.swift
//  WaitForIt
//
//  Created by Paweł Urbanek on 23/09/2017.
//  Copyright © 2017 PabloWeb. All rights reserved.
//

import Foundation

public protocol ScenarioProtocol {
    // minimum number of scenario events needed to be trigerred before scenario can be executed
    static var minEventsRequired: Int? { get }
    
    // maximum number of scenario events which can be trigerred before scenario stops executing
    static var maxEventsPermitted: Int? { get }
    
    // maximum number of times that scenario can be executed
    static var maxExecutionsPermitted: Int? { get }
    
    // minimum time interval, after the first scenario event was trigerred, before the scenario can be executed
    static var minSecondsSinceFirstEvent: TimeInterval? { get }
    
    // minimum time interval before scenario can be executed again after previous execution
    static var minSecondsBetweenExecutions: TimeInterval? { get }
    
    // increment scenario specific event counter
    static func triggerEvent()
    
    // same as above but you can mock current date, used internally for testing
    static func triggerEvent(timeNow: Date)
    
    // try to execute a scenario (it counts as executed only if bool param passed into a block was `true`)
    static func execute(completion: @escaping (Bool) -> Void)
    
    // same as above but you can mock current date, used internally for testing
    static func execute(timeNow: Date, completion: @escaping (Bool) -> Void)
    
    // reset scenario event and execution counters
    static func reset()
}

public extension ScenarioProtocol {
    static func triggerEvent() {
        triggerEvent(timeNow: Date())
    }
    
    static func triggerEvent(timeNow: Date) {
        let newCount = currentEventsCount + 1
        userDefaults.setValuesForKeys([kDefaultsEventsCount: newCount])
        
        if userDefaults.object(forKey: kDefaultsFirstEventDate) == nil {
            userDefaults.setValuesForKeys([kDefaultsFirstEventDate: timeNow])
        }
        
        userDefaults.synchronize()
    }
    
    static func execute(timeNow: Date, completion: @escaping (Bool) -> Void) {
        let currentCount = currentEventsCount
        
        var countBasedConditions: Bool
        
        if let max = maxEventsPermitted, let min = minEventsRequired {
            countBasedConditions = (max >= currentCount) && (min <= currentCount)
        } else if let max = maxEventsPermitted {
            countBasedConditions = max >= currentCount
        } else if let min = minEventsRequired {
            countBasedConditions = min <= currentCount
        } else {
            countBasedConditions = true
        }
        
        var dateBasedConditions: Bool
        
        if let minSecondsInterval = minSecondsSinceFirstEvent,
            let firstEventDate = currentFirstEventDate {
            let secondsSinceFirstEvent = timeNow.timeIntervalSince1970 - firstEventDate.timeIntervalSince1970
            
            dateBasedConditions = secondsSinceFirstEvent > minSecondsInterval
        } else {
            dateBasedConditions = true
        }
        
        var executionCountBasedConditions: Bool
        
        if let maxExecutions = maxExecutionsPermitted {
            executionCountBasedConditions = currentExecutionsCount < maxExecutions
        } else {
            executionCountBasedConditions = true
        }
        
        var executionDateBasedConditions: Bool
        
        if let minSecondsInterval = minSecondsBetweenExecutions,
            let lastExecutionDate = currentLastExecutionDate {
            let secondsSinceLastExecution = timeNow.timeIntervalSince1970 - lastExecutionDate.timeIntervalSince1970
            
            executionDateBasedConditions = secondsSinceLastExecution > minSecondsInterval
        } else {
            executionDateBasedConditions = true
        }
        
        let finalResult = countBasedConditions && dateBasedConditions && executionCountBasedConditions && executionDateBasedConditions
        
        if finalResult {
            incrementExecutionsCounter()
            saveLastExecutionDate(timeNow: timeNow)
        }
        
        completion(finalResult)
    }
    
    
    static func execute(completion: @escaping (Bool) -> Void) {
        execute(timeNow: Date(), completion: completion)
    }
    
    static func reset() {
        [
            kDefaultsEventsCount,
            kDefaultsExecutionsCount,
            kDefaultsFirstEventDate,
            kDefaultsLastExecutionDate
        ].forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.synchronize()
    }
    
    private static var currentEventsCount: Int {
        let currentCount = userDefaults.value(forKey: kDefaultsEventsCount)
        var count = 0
        
        if(currentCount != nil) {
          count = currentCount as! Int
        }
        
        return count
    }
    
    private static var currentExecutionsCount: Int {
        let currentCount = userDefaults.value(forKey: kDefaultsExecutionsCount)
        var count = 0
        
        if(currentCount != nil) {
          count = currentCount as! Int
        }
        
        return count
    }
    
    private static func incrementExecutionsCounter() {
        let newCount = currentExecutionsCount + 1
        userDefaults.setValuesForKeys([kDefaultsExecutionsCount: newCount])
        userDefaults.synchronize()
    }
    
    private static func saveLastExecutionDate(timeNow: Date) {
        userDefaults.setValuesForKeys([kDefaultsLastExecutionDate: timeNow])
        userDefaults.synchronize()
    }
    
    private static var currentFirstEventDate: Date? {
        return userDefaults.object(forKey: kDefaultsFirstEventDate) as? Date
    }
    
    private static var currentLastExecutionDate: Date? {
        return userDefaults.object(forKey: kDefaultsLastExecutionDate) as? Date
    }
    
    private static var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    private static var kDefaultsBase: String {
        return "net.pabloweb.WaitForIt.\(String(describing: self))"
    }
    
    private static var kDefaultsEventsCount: String {
        return "\(kDefaultsBase).eventsCount"
    }
    
    private static var kDefaultsExecutionsCount: String {
        return "\(kDefaultsBase).executionsCount"
    }
    
    private static var kDefaultsFirstEventDate: String {
        return "\(kDefaultsBase).firstEventDate"
    }
    
    private static var kDefaultsLastExecutionDate: String {
        return "\(kDefaultsBase).lastExecutionDate"
    }
}
