//
//  RouteViewModel.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2024/11/2.
//

import Foundation
import Combine

class RouteViewModel {
    var routes = CurrentValueSubject<[Route], Never>([])
    var themeLabel = CurrentValueSubject<String, Never>("")

    init() {
        // 監聽 routes 的變化並更新 themeLabel
        routes
            .map { $0.first?.routeTypes }
            .compactMap { $0 }
            .map { RoutesType.from(value: $0)?.title ?? "未知路徑" } // 使用預設值
            .assign(to: \.value, on: themeLabel)
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // 更新 routes 的方法
    func setRoutes(_ newRoutes: [Route]) {
        routes.send(newRoutes)
    }
}


