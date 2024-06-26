/// <#Brief Description#>
///
/// Created by TWINB00591630 on 2023/7/26.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

@testable import RideTogether
import XCTest

final class UBikemanagerTests: XCTestCase {
    private var sut: BikeManager!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_MakingRequest() throws {
        let request = BikeRequest() // step 1 打 request
        var response: [Bike]? // step 2 拿到 response
        let apiLoader = APIRequestLoader(apiRequest: request, urlSession: URLSession.shared) // step 3 拿資料
        let expectation = self.expectation(description: "Proper Response comes")

        apiLoader.loadAPIRequest(requestData: "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json") { res, _ in
            response = res
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertNotNil(response?.first)
    }
}
