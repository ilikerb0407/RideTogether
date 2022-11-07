//
//  BikeModel.swift
//  RideTogether
//
//  Created by 00591630 on 2022/10/26.
//

import Foundation

// MARK: - BikeElement

struct Bike: Codable {
    let sno, sna: String
    let tot, sbi: Int
    let sarea, mday: String
    let lat, lng: Double
    let ar, sareaen, snaen, aren: String
    let bemp: Int
    let act, srcUpdateTime, updateTime, infoTime: String
    let infoDate: String
}

struct TaichungBike: Codable {
    let retCode: Int
    let retVal: [String: TBike]
}

// MARK: - RetVal
struct TBike: Codable {
    let sno, sna, tot, sbi: String
    let sarea, mday, lat, lng: String
    let ar, sareaen, snaen, aren: String
    let bemp, act: String
}
