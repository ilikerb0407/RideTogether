//
//  AlertTests.swift
//  RideTogetherTests
//
//  Created by TWINB00591630 on 2023/2/24.
//
@testable import RideTogether
import XCTest
import ViewControllerPresentationSpy

final class AlertTests: XCTestCase {

    private var sut: JourneyViewController!
    private var alertVerifier: AlertVerifier!

    @MainActor override func setUp() {
        super.setUp()
        alertVerifier = AlertVerifier()
        let storyboard = UIStoryboard(name: "Journey", bundle: nil)
        sut = storyboard.instantiateViewController(identifier: String(describing: JourneyViewController.self))
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        alertVerifier = nil
        sut = nil
        super.tearDown()
    }

    @MainActor func test_executeAlertAction_withSaveButton() throws {
        tap(sut.trackerButton)
        // 要先按下追蹤才可以按儲存
        tap(sut.saveButton)

        try alertVerifier.executeAction(forButton: "儲存")
    }
}
