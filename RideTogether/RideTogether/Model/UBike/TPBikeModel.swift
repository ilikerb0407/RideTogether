//
//  TPBikeModel.swift
//  RideTogether
//
//  Created by 00591630 on 2022/10/26.
//

import Foundation

// MARK: - BikeElement

struct TPBikeModel: Codable {
    let sno, sna: String
    let tot, sbi: Int
    let sarea, mday: String
    let lat, lng: Double
    let ar, sareaen, snaen, aren: String
    let bemp: Int
    let act, srcUpdateTime, updateTime, infoTime: String
    let infoDate: String
}
