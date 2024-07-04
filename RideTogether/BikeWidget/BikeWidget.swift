//
//  BikeWidget.swift
//  BikeWidget
//
//  Created by 00591630 on 2022/10/26.
//

import CoreLocation
import MapKit
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    static let emptyLocationSet = [BikeModel]()

    // TODO: This is just a failsafe in case location services are not updated on launch

    static var sampleUserLocation: MKCoordinateRegion {
        let latitude = CLLocationDegrees(60.2323)
        let longitude = CLLocationDegrees(-60.393377)

        let locationCoord = CLLocationCoordinate2DMake(latitude, longitude)

        return MKCoordinateRegion(center: locationCoord,
                                  latitudinalMeters: 500.0,
                                  longitudinalMeters: 500.0)
    }

    func placeholder(in _: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), nearestStations: Provider.emptyLocationSet, userLocation: Provider.sampleUserLocation, image: UIImage(systemName: "map")!)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        guard !context.isPreview else {
            let mapEntry = SimpleEntry(date: Date(), nearestStations: Provider.emptyLocationSet, userLocation: Provider.sampleUserLocation, image: UIImage(systemName: "map")!)

            completion(mapEntry)

            return
        }

        let updateCompletionAfterFetchUserLocation: (CLLocation) -> Void = { userLocation in
            loadNearestLocations(userLocation: userLocation) { nearbyStations in
                contentUpdate(context: context,
                              locations: nearbyStations,
                              updatedUserLocation: userLocation) { mapEntry in
                    DispatchQueue.main.async {
                        completion(mapEntry)
                    }
                }
            }
        }

        WidgetLocationManager.shared.fetchLocation(handler: updateCompletionAfterFetchUserLocation)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let updateCompletionAfterFetchUserLocation: (CLLocation) -> Void = { userLocation in
            loadNearestLocations(userLocation: userLocation) { nearbyStations in
                contentUpdate(context: context,
                              locations: nearbyStations,
                              updatedUserLocation: userLocation) { mapEntry in
                    let date = Date()
                    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: date)!
                    let timeline = Timeline(entries: [mapEntry], policy: .after(nextUpdate))

                    DispatchQueue.main.async {
                        completion(timeline)
                    }
                }
            }
        }

        WidgetLocationManager.shared.fetchLocation(handler: updateCompletionAfterFetchUserLocation)
    }

    // MARK: Helpers
    private func contentUpdate(context: TimelineProvider.Context, locations: [BikeModel], updatedUserLocation: CLLocation, completionHandler: @escaping (SimpleEntry) -> Void) {
        let region = MKCoordinateRegion(center: updatedUserLocation.coordinate, latitudinalMeters: 500.0, longitudinalMeters: 500.0)
        let mapSnapshotter = makeSnapshotter(for: region, with: context.displaySize)

        mapSnapshotter.start { snapshot, error in
            guard error == nil,
                  let useableSnapShot = snapshot else {
                return
            }

            let image = UIGraphicsImageRenderer(size: useableSnapShot.image.size).image { _ in
                useableSnapShot.image.draw(at: CGPoint.zero)

                let userLocationIconName = "person.crop.circle.fill"
                let nearestStationIconName = "bicycle.circle.fill"

                addAnnotation(snapshot: useableSnapShot, imageName: userLocationIconName, latitude: updatedUserLocation.coordinate.latitude, lontitude: updatedUserLocation.coordinate.longitude)

                for location in locations {
                    addAnnotation(snapshot: useableSnapShot, imageName: nearestStationIconName, latitude: location.lat, lontitude: location.lng)
                }
            }

            let region = MKCoordinateRegion(center: updatedUserLocation.coordinate,
                                            latitudinalMeters: 500.0,
                                            longitudinalMeters: 500.0)

            let entry = SimpleEntry(date: Date(),
                                    nearestStations: locations,
                                    userLocation: region,
                                    image: image)

            completionHandler(entry)
        }
    }

    private func loadNearestLocations(userLocation: CLLocation,
                                      completion: @escaping ([BikeModel]) -> Void) {
        let urlString = URL(string: "https://tcgbusfs.blob.core.windows.net/dotapp/youbike/v2/youbike_immediate.json")

        guard let urlString else {
            return
        }
        let url = URLRequest(url: urlString)

        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data else {
                return
            }
            let decoder = JSONDecoder()
            do {
                let bikeData = try decoder.decode([BikeModel].self, from: data)

                let mappedResult = closestLocations(userLocation: userLocation, stationLocations: bikeData)

                completion(mappedResult)
                print("Hello UBike")

            } catch {
                print(error)
            }

        }).resume()
    }

    private func makeSnapshotter(for userRegion: MKCoordinateRegion, with size: CGSize) -> MKMapSnapshotter {
        let options = MKMapSnapshotter.Options()
        let halfHeightSize = CGSize(width: size.width, height: size.height / 2)

        options.region = userRegion
        options.size = halfHeightSize
        options.mapType = .standard

        // NOTE: Force light mode snapshot
        options.traitCollection = UITraitCollection(traitsFrom: [
            options.traitCollection,
            UITraitCollection(userInterfaceStyle: .light),
        ])

        return MKMapSnapshotter(options: options)
    }

    private func addAnnotation(snapshot: MKMapSnapshotter.Snapshot, imageName: String, latitude: CLLocationDegrees, lontitude: CLLocationDegrees) {
        let pinView = MKMarkerAnnotationView(annotation: nil, reuseIdentifier: nil)

        pinView.image = UIImage(systemName: imageName)

        let pinImage = pinView.image

        var point = snapshot.point(for: CLLocationCoordinate2D(latitude: latitude, longitude: lontitude))

        let containingFrame = CGRect(origin: .zero, size: snapshot.image.size)

        if containingFrame.contains(point) {
            point.x -= pinView.bounds.width / 2
            point.y -= pinView.bounds.height / 2
            point.x += pinView.centerOffset.x
            point.y += pinView.centerOffset.y

            pinImage?.draw(at: point)
        }
    }

    private func closestLocations(userLocation: CLLocation, stationLocations: [BikeModel]) -> [BikeModel] {
        var allDistancesToUser = [(Double, BikeModel)]()

        for location in stationLocations {
            let comparableLocation = CLLocation(latitude: location.lat,
                                                longitude: location.lng)
            let distanceToUser = comparableLocation.distance(from: userLocation)
            let distanceAndStation = (distanceToUser, location)

            if distanceToUser <= 500 {
                allDistancesToUser.append(distanceAndStation)
            }
        }

        let closestStationDistancesToUser = allDistancesToUser.sorted(by: { $0.0 < $1.0 })
        let closestStationsToUser = closestStationDistancesToUser.map { _, station -> BikeModel in

            let updatedStationWithDistance = BikeModel(sno: station.sno,
                                                  sna: station.sna, tot: station.tot, sbi: station.sbi,
                                                  sarea: station.sarea, mday: station.mday, lat: station.lat, lng: station.lng,
                                                  ar: station.ar, sareaen: station.sareaen, snaen: station.snaen,
                                                  aren: station.aren, bemp: station.bemp, act: station.act,
                                                  srcUpdateTime: station.srcUpdateTime, updateTime: station.updateTime,
                                                  infoTime: station.infoTime, infoDate: station.infoDate)

            return updatedStationWithDistance
        }

        return closestStationsToUser
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let nearestStations: [BikeModel]
    let userLocation: MKCoordinateRegion
    let image: UIImage
}

struct BikeWidgetEntryView: View {
    @State var entry: SimpleEntry
    private var upperLimitOnNearbyStations: Int {
        entry.nearestStations.count > 3 ? 3 : entry.nearestStations.count
    }

    var body: some View {
        Link(destination: URL(string: "widget://\(entry.userLocation.center.latitude)/\(entry.userLocation.center.longitude)")!) {
            Image(uiImage: entry.image)

            VStack {
                if !entry.nearestStations.isEmpty {
                    ForEach(entry.nearestStations.indices.prefix(upperLimitOnNearbyStations), id: \.self) { index in
                        NearbyBikesView(bike: entry.nearestStations[index])
                        Spacer()
                        Divider()
                    }
                } else {
                    Text("你附近沒有腳踏車 😥 請再重試試")
                        .font(.caption)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .frame(width: entry.image.size.width,
                   height: entry.image.size.height,
                   alignment: .center)
        }
    }
}

@main
struct BikeWidget: Widget {
    let kind: String = "BikeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BikeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemLarge])
    }
}

struct BikeWidget_Previews: PreviewProvider {
    static var previews: some View {
        BikeWidgetEntryView(entry: SimpleEntry(date: Date(), nearestStations: [], userLocation: .init(), image: .init()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
