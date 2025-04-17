//
//  RouteBuilder.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/19.
//

import MapKit

enum RouteBuilder {
    enum Segment {
        case text(String)
        case location(CLLocation)
    }

    enum RouteError: Error {
        case invalidSegment(String)
    }

    typealias PlaceCompletionBlock = (MKPlacemark?) -> Void
    typealias RouteCompletionBlock = (Result<DrawRoute, RouteError>) -> Void

    private static let routeQueue = DispatchQueue(label: "route-builder")

    static func buildRoute(origin: Segment, stops: [Segment], within region: MKCoordinateRegion?, completion: @escaping RouteCompletionBlock) {
        routeQueue.async {
            let group = DispatchGroup()

            var originItem: MKMapItem?
            group.enter()
            requestPlace(for: origin, within: region) { place in
                if let requestedPlace = place {
                    originItem = MKMapItem(placemark: requestedPlace)
                }

                group.leave()
            }

            var stopItems = [MKMapItem](repeating: .init(), count: stops.count)
            for (index, stop) in stops.enumerated() {
                group.enter()
                requestPlace(for: stop, within: region) { place in
                    if let requestedPlace = place {
                        stopItems[index] = MKMapItem(placemark: requestedPlace)
                    }

                    group.leave()
                }
            }

            group.notify(queue: .main) {
                if let originMapItem = originItem, !stopItems.isEmpty {
                    let route = DrawRoute(origin: originMapItem, stops: stopItems)

                    completion(.success(route))
                } else {
                    let reason = originItem == nil ? "the origin address" : "one or more of the stops"
                    completion(.failure(.invalidSegment(reason)))
                }
            }
        }
    }

    private static func requestPlace(for segment: Segment, within region: MKCoordinateRegion?, completion: @escaping PlaceCompletionBlock) {
        if case let .text(value) = segment, let nearbyRegion = region {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = value
            request.region = nearbyRegion

            MKLocalSearch(request: request).start { response, _ in
                let place: MKPlacemark?

                if let firstItem = response?.mapItems.first {
                    place = firstItem.placemark
                } else {
                    place = nil
                }

                completion(place)
            }
        } else {
            CLGeocoder().geocodeSegment(segment) { places, _ in
                let place: MKPlacemark?

                if let firstPlace = places?.first {
                    place = MKPlacemark(placemark: firstPlace)
                } else {
                    place = nil
                }

                completion(place)
            }
        }
    }
}

extension CLGeocoder {
    fileprivate func geocodeSegment(_ segment: RouteBuilder.Segment, completionHandler: @escaping CLGeocodeCompletionHandler) {
        switch segment {
        case let .text(value):
            geocodeAddressString(value, completionHandler: completionHandler)

        case let .location(value):
            reverseGeocodeLocation(value, completionHandler: completionHandler)
        }
    }
}
