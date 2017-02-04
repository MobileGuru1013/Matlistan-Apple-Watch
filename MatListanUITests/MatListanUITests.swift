//
//  MatListanUITests.swift
//  MatListanUITests
//
//  Created by Artem Bakanov on 17.02.16.
//  Copyright © 2016 Consumiq AB. All rights reserved.
//

import XCTest

class MatListanUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        XCUIDevice.sharedDevice().orientation = .Portrait
        XCUIDevice.sharedDevice().orientation = .Portrait
        XCUIDevice.sharedDevice().orientation = .Portrait
        XCUIDevice.sharedDevice().orientation = .Portrait
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        snapshot("Items")
        
        
        app.navigationBars["ItemsView"].buttons["menu"].tap()
        app.tables.staticTexts["Matplanering"].tap()
        
        
        snapshot("Planned Recipes")

        app.navigationBars["Matplanering"].buttons["menu"].tap()
        app.tables.staticTexts["Receptsamling"].tap()

        let receptsamlingNavigationBar = app.navigationBars["Receptsamling"]
        let sortRecipeButton = receptsamlingNavigationBar.buttons["sort recipe"]
        sortRecipeButton.tap()
        app.pickerWheels.element.adjustToPickerWheelValue("Mest tillagade")
        sortRecipeButton.tap()
        
        
        snapshot("Recipes")
        
        app.tables.cells.containingType(.StaticText, identifier:"Klassiskt pannkaksrecept").staticTexts["pannkakor.se"].tap()
        receptsamlingNavigationBar.buttons["calendar"].tap()
        
        snapshot("Planning")
        

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
