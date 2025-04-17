//
//  WeatherManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import CoreLocation
import Foundation

class WeatherManager {
    func getWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (ResponseBody) -> Void) {
        let urlString = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=d11fc33a5a4003b6bac4bb9d50f25d15&units=metric")

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
                let firstData = try decoder.decode(ResponseBody.self, from: data)
                completion(firstData)
                LKProgressHUD.show(.success("讀取成功"))
            } catch {
                LKProgressHUD.show(.failure("網路問題，無法讀取"))
            }
        })
        .resume()
    }
}
