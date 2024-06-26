/// <#Brief Description#>
///
/// Created by TWINB00591630 on 2023/7/26.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

@testable import RideTogether
import XCTest

final class DistanceLabelTests: XCTestCase {
    private var sut: DistanceLabel!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - init

    /// Case: 驗證各項 properties 符合預期
    func test_init_初始化物件_結果符合預期() {
        sut = .init(frame: .zero)
        XCTAssertNotNil(sut.text)
        XCTAssertEqual(sut.textAlignment, .right)
        XCTAssertEqual(sut.font, .systemFont(ofSize: 20, weight: .regular))
        XCTAssertEqual(sut.textColor, UIColor.B5)
        XCTAssertEqual(sut.distance, 0.00)
    }

    func test_init_帶入distance為0_結果distance應為0() {
        sut = .init(frame: .zero)
        sut.distance = 10
        XCTAssertEqual(sut.distance, 10)
    }
}
