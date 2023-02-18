//
//  OverrideViewControllerTests.swift
//  RideTogetherTests
//
//  Created by TWINB00591630 on 2023/2/18.
//
@testable import RideTogether
import XCTest

private class TestableOverrideViewController: TracksViewController {
    override func recordmanager() -> RecordManager {
         RecordManager()
    }
}


final class OverrideViewControllerTests: XCTestCase {

    func test_viewDidAppear() {
        let sut = TestableOverrideViewController()
        sut.loadViewIfNeeded()

        sut.viewDidAppear(false)
    }


}
