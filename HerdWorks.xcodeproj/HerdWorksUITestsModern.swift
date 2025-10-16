//
//  HerdWorksUITestsModern.swift
//  HerdWorksUITests
//
//  Example using Swift Testing framework
//

import Testing
import XCTest

@Suite("HerdWorks UI Tests")
struct HerdWorksUITestsModern {
    
    @Test("App launches successfully")
    @MainActor
    func appLaunchTest() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for the app to be ready
        let appExists = app.waitForExistence(timeout: 10) // Increased timeout for device
        #expect(appExists, "App should launch within 10 seconds")
        
        // Additional check for app state on physical device
        #expect(app.state == .runningForeground, "App should be running in foreground")
    }
    
    @Test("Launch performance benchmark")
    @MainActor 
    func launchPerformanceTest() async throws {
        // This would need custom performance measurement implementation
        // as Swift Testing doesn't have built-in performance testing yet
        let app = XCUIApplication()
        let startTime = CFAbsoluteTimeGetCurrent()
        app.launch()
        let launchTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Expect launch to complete within reasonable time
        #expect(launchTime < 5.0, "App should launch within 5 seconds")
    }
}