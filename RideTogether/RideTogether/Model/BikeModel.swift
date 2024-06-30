//
//  BikeModel.swift
//  RideTogether
//
//  Created by 00591630 on 2022/10/26.
//

import Foundation

// MARK: - BikeElement

struct BikeModel: Codable {
    let sno, sna: String
    let tot, sbi: Int
    let sarea, mday: String
    let lat, lng: Double
    let ar, sareaen, snaen, aren: String
    let bemp: Int
    let act, srcUpdateTime, updateTime, infoTime: String
    let infoDate: String
}

struct TaichungBikeModel: Codable {
    let retCode: Int
    let retVal: [String: RetVal]
}

// MARK: - RetVal
struct RetVal: Codable {
    let sno, sna, tot, sbi: String
    let sarea, mday, lat, lng: String
    let ar, sareaen, snaen, aren: String
    let bemp, act: String
}
