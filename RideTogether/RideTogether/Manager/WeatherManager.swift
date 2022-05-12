//
//  WeatherManager.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/23.
//

import Foundation
import CoreLocation

protocol weatherProvider {
    func provideWeather(weather : ResponseBody)
}

class WeatherManager {
    
    var delegate: weatherProvider?
    
    func getGroupAPI(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (ResponseBody) -> Void) {
        
        let firstDataRequest = URLRequest(url: URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=d11fc33a5a4003b6bac4bb9d50f25d15&units=metric")!)
        
        URLSession.shared.dataTask(with: firstDataRequest, completionHandler: { [self] (data, response, error) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                let firstData = try decoder.decode(ResponseBody.self, from: data)
                completion(firstData)
                print ("=================\(firstData)===================")
               
            } catch {
                print(error)
            }
            
        }) .resume()
    }
    
    
}

// MARK: - Welcome
struct ResponseBody: Codable {
    let coord: Coord
    let weather: [Weather]
    let base: String
    let main: Main
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let timezone, id: Int
    let name: String
    let cod: Int
}

// MARK: - Clouds
struct Clouds: Codable {
    let all: Int
}

// MARK: - Coord
struct Coord: Codable {
    let lon, lat: Double
}

// MARK: - Main
struct Main: Codable {
    let temp, feelsLike, tempMin, tempMax: Double
    let pressure, humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure, humidity
    }
}

// MARK: - Sys
struct Sys: Codable {
    let type, id: Int
    let country: String
    let sunrise, sunset: Int
}

// MARK: - Weather
struct Weather: Codable {
    let id: Int
    let main, weatherDescription, icon: String

    enum CodingKeys: String, CodingKey {
        case id, main
        case weatherDescription = "description"
        case icon
    }
}

// MARK: - Wind
struct Wind: Codable {
    let speed: Double
    let deg: Int
}
