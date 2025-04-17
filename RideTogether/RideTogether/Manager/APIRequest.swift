/// <#Brief Description#>
///
/// Created by TWINB00591630 on 2023/7/26.
/// Copyright © 2023 Cathay United Bank. All rights reserved.

import Foundation

protocol APIRequest {
    associatedtype RequestDataType
    associatedtype ResponseDataType

    func makeRequest(from data: RequestDataType) throws -> URLRequest
    func parseResponse(data: Data) throws -> ResponseDataType
}
