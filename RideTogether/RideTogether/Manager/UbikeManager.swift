//
//  UbikeManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/5/13.
//

import CoreLocation
import Foundation
import MapKit

final class BikeManager {
    private var bikes: [Bike]

    static let shared = BikeManager()

    init() {
        bikes = []
    }

    func getTPBikeData(completion: @escaping ([Bike]) -> Void) {
        let apiLoader = APIRequestLoader(apiRequest: BikeRequest())

        apiLoader.loadAPIRequest(requestData: "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json") { data, _ in
            guard let data else {
                return
            }
            completion(data)
        }
    }

    class func getTCBikeData(completion: @escaping (TaichungBike) -> Void) {
        let urlString = URL(string: "https://datacenter.taichung.gov.tw/swagger/OpenData/34c2aa94-7924-40cc-96aa-b8d090f0ab69")

        guard let urlString else {
            return
        }
        let url = URLRequest(url: urlString)

        URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
            guard let data else {
                return
            }
            let decoder = JSONDecoder()
            do {
                let tBikeData = try decoder.decode(TaichungBike.self, from: data)

                completion(tBikeData)

                LKProgressHUD.showSuccess(text: "讀取成功")

            } catch {
                print(error)
                LKProgressHUD.showFailure(text: "目前僅提供台北市的資料，陸續增加中")
            }

        }).resume()
    }
}

enum RequestError: Error {
    case invalidUrl
}

class APIRequestLoader<T: APIRequest> {
    let apiRequest: T
    let urlSession: URLSession

    init(apiRequest: T, urlSession: URLSession = .shared) {
        self.apiRequest = apiRequest
        self.urlSession = urlSession
    }

    func loadAPIRequest(requestData: T.RequestDataType, completionHandler: @escaping (T.ResponseDataType?, Error?) -> Void) {
        do {
            let urlRequest = try apiRequest.makeRequest(from: requestData)
            URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, _, error in
                guard let data else {
                    return completionHandler(nil, error)
                }
                do {
                    let parseResponse = try self.apiRequest.parseResponse(data: data)
                    completionHandler(parseResponse, nil)
                } catch {
                    completionHandler(nil, error)
                }
            }).resume()
        } catch {
            completionHandler(nil, error)
        }
    }
}

struct BikeRequest: APIRequest {
    // part one's method
    func makeRequest(from stringUrl: String) throws -> URLRequest {
        guard let url = URL(string: stringUrl) else {
            throw RequestError.invalidUrl
        }
        return URLRequest(url: url)
    }

    // part two's method
    func parseResponse(data: Data) throws -> [Bike] {
        try JSONDecoder().decode([Bike].self, from: data)
    }
}
