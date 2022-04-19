//
//  DirectionViewController.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/19.
//

import UIKit
import MapKit

class DirectionViewController: UIViewController {

    @IBOutlet private var mapView: MKMapView!
    // 目前先連Journey 的 mapView
    
    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!

    private let cellIdentifier = "DirectionsCell"
    private let distanceFormatter = MKDistanceFormatter()


    private var mapRoutes: [MKRoute] = []
    private var totalTravelTime: TimeInterval = 0
    private var totalDistance: CLLocationDistance = 0

    private var groupedRoutes: [(startItem: MKMapItem, endItem: MKMapItem)] = []

      
    private let route: DrawRoute
      
    init(route: DrawRoute) {
      self.route = route

      super.init(nibName: String(describing: DirectionViewController.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
      super.viewDidLoad()

      groupAndRequestDirections()

      headerLabel.text = route.label

      tableView.dataSource = self

      mapView.delegate = self
      mapView.showAnnotations(route.annotations, animated: false)
    }

    // MARK: - Helpers

    private func groupAndRequestDirections() {
      guard let firstStop = route.stops.first else {
        return
      }

      groupedRoutes.append((route.origin, firstStop))

      if route.stops.count == 2 {
        let secondStop = route.stops[1]

        groupedRoutes.append((firstStop, secondStop))
          
        groupedRoutes.append((secondStop, route.origin))
      }

      fetchNextRoute()
    }

    private func fetchNextRoute() {
      guard !groupedRoutes.isEmpty else {
        activityIndicatorView.stopAnimating()
        return
      }

      let nextGroup = groupedRoutes.removeFirst()
      let request = MKDirections.Request()

      request.source = nextGroup.startItem
      request.destination = nextGroup.endItem

      let directions = MKDirections(request: request)

      directions.calculate { response, error in
        guard let mapRoute = response?.routes.first else {
          self.informationLabel.text = error?.localizedDescription
          self.activityIndicatorView.stopAnimating()
          return
        }
      
          
        self.updateView(with: mapRoute)
      
        self.fetchNextRoute()
      }
    }

    private func updateView(with mapRoute: MKRoute) {
      let padding: CGFloat = 8
      mapView.addOverlay(mapRoute.polyline)
        
  //
      mapView.setVisibleMapRect(
        mapView.visibleMapRect.union(
          mapRoute.polyline.boundingMapRect
        ),
        edgePadding: UIEdgeInsets(
          top: 0,
          left: padding,
          bottom: padding,
          right: padding
        ),
        animated: true
      )

      totalDistance += mapRoute.distance
      totalTravelTime += mapRoute.expectedTravelTime

      let informationComponents = [
        totalTravelTime.formatted,
        "• \(distanceFormatter.string(fromDistance: totalDistance))"
      ]
      informationLabel.text = informationComponents.joined(separator: " ")

      mapRoutes.append(mapRoute)
      tableView.reloadData()
    }
  }

  // MARK: - UITableViewDataSource

  extension DirectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
      return mapRoutes.isEmpty ? 0 : mapRoutes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      let route = mapRoutes[section]
      return route.steps.count - 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = { () -> UITableViewCell in
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) else {
          let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
          cell.selectionStyle = .none
          return cell
        }
        return cell
      }()

      let route = mapRoutes[indexPath.section]
      let step = route.steps[indexPath.row + 1]

      cell.textLabel?.text = "\(indexPath.row + 1): \(step.notice ?? step.instructions)"
      cell.detailTextLabel?.text = distanceFormatter.string(
        fromDistance: step.distance
      )

      return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      let route = mapRoutes[section]
      return route.name
    }
  }

  // MARK: - MKMapViewDelegate

  extension DirectionViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
      let renderer = MKPolylineRenderer(overlay: overlay)

      renderer.strokeColor = .systemBlue
      renderer.lineWidth = 3

      return renderer
    }


}
