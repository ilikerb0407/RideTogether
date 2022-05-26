//
//  RideTogetherTests.swift
//  RideTogetherTests
//
//  Created by Kai Fu Jhuang on 2022/5/20.
//

import XCTest
@testable import RideTogether

class RideTogetherTests: XCTestCase {

    var sut: URLSession!
    var sut1 = BikeManager()
    
    override func setUpWithError() throws {
      try super.setUpWithError()
      sut = URLSession(configuration: .default)
        
    }

    override func tearDownWithError() throws {
      sut = nil
      try super.tearDownWithError()
    }
    
    func testApiCallCompletes() throws {
      // given
      let urlString = "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json"
      let url = URL(string: urlString)!
      let promise = expectation(description: "Completion handler invoked")
      var statusCode: Int?
      var responseError: Error?

      // when
      let dataTask = sut.dataTask(with: url) { _, response, error in
        statusCode = (response as? HTTPURLResponse)?.statusCode
        responseError = error
        promise.fulfill()
      }
      dataTask.resume()
      wait(for: [promise], timeout: 10)

      // then
      XCTAssertNil(responseError)
      XCTAssertEqual(statusCode, 200)
    }

}
