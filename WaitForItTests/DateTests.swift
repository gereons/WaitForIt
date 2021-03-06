//
//  DateTests.swift
//  WaitForIt
//
//  Created by Paweł Urbanek on 24/09/2017.
//  Copyright © 2017 PabloWeb. All rights reserved.
//

import Foundation
import XCTest
@testable import WaitForIt

struct BasicDateTest: ScenarioProtocol {
    static var minSecondsSinceFirstEvent: TimeInterval? = 1
    
    static var minEventsRequired: Int? = nil
    static var maxEventsPermitted: Int? = nil
    static var maxExecutionsPermitted: Int? = nil
    static var minSecondsBetweenExecutions: TimeInterval? = nil
    static var customConditions: (() -> Bool)? = nil
}

struct MockedDateTest: ScenarioProtocol {
    static var minSecondsSinceFirstEvent: TimeInterval? = 1500
    
    static var minEventsRequired: Int? = nil
    static var maxEventsPermitted: Int? = nil
    static var maxExecutionsPermitted: Int? = nil
    static var minSecondsBetweenExecutions: TimeInterval? = nil
    static var customConditions: (() -> Bool)? = nil
}

class DateTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        BasicDateTest.reset()
        MockedDateTest.reset()
    }
    
    func testBasicDate() {
        let scenario = BasicDateTest.self
        scenario.triggerEvent()
        sleep(2)
        scenario.tryToExecute { didExecute in
            XCTAssertTrue(didExecute)
        }
    }
    
    func testMockedDate() {
        let fakeNow = Date().addingTimeInterval(-2000)
        let scenario = MockedDateTest.self
        scenario.triggerEvent(timeNow: fakeNow)
        
        scenario.tryToExecute { didExecute in
            XCTAssertTrue(didExecute)
        }
        
        scenario.tryToExecute(timeNow: fakeNow, completion: { didExecute in
            XCTAssertFalse(didExecute)
        })
    }
}
