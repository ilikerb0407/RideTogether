//
//  ButtonTappedTests.swift
//  RideTogetherTests
//
//  Created by TWINB00591630 on 2023/2/22.
//
@testable import RideTogether
import XCTest

final class ButtonTappedTests: XCTestCase {

    func test_tappingButton() {
        // name 要注意不要填錯
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let sut: LoginViewController = storyboard.instantiateViewController(identifier: String(describing: LoginViewController.self))

        sut.loadViewIfNeeded()
        tap(sut.emailbtn)
    }


}
