//
//  GPXMapView.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import CoreLocation
import Foundation
import MapKit
import UIKit

class GPXMapView: MKMapView {
    let session = GPXSession()

    var waypoints: [GPXWaypoint] = []

    var currentSegmentOverlay: MKPolyline

    var extent: GPXExtentCoordinates = .init()

    var headingOffset: CGFloat?

    var heading: CLHeading?

    var headingImageView: UIImageView?

    var rotationGesture = UIRotationGestureRecognizer()

    init() {
        waypoints = .init()
        currentSegmentOverlay = .init()
        headingOffset = .init()
        heading = .init()
        headingImageView = .init()
        super.init(frame: .zero)
    }

//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    required init?(coder aDecoder: NSCoder) {
        var tmpCoords: [CLLocationCoordinate2D] = []

        currentSegmentOverlay = MKPolyline(coordinates: &tmpCoords, count: 0)
//        fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)

        isUserInteractionEnabled = true

        isMultipleTouchEnabled = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let compassView = subviews.first(where: { $0.isKind(of: NSClassFromString("MKCompassView")!) }) {
            compassView.frame.origin = CGPoint(x: UIScreen.width / 2 - 18, y: 30)
        }
    }

    func addPointToCurrentTrackSegmentAtLocation(_ location: CLLocation) {
        session.addPointToCurrentTrackSegmentAtLocation(location)
        removeOverlay(currentSegmentOverlay)
        currentSegmentOverlay = session.currentSegment.overlay
        addOverlay(currentSegmentOverlay)
        extent.extendAreaToIncludeLocation(location.coordinate)
    }

    func startNewTrackSegment() {
        if !session.currentSegment.points.isEmpty {
            session.startNewTrackSegment()
            currentSegmentOverlay = MKPolyline()
        }
    }

    func clearMap() {
        session.reset()
        removeOverlays(overlays)
        removeAnnotations(annotations)
        extent = GPXExtentCoordinates()
    }

    func clearOverlays() {
        removeOverlays(overlays)
    }

    func exportToGPXString() -> String {
        session.exportToGPXString()
    }

    func regionToGPXExtent() {
        setRegion(extent.region, animated: true)
    }

    func importFromGPXRoot(_ gpx: GPXRoot) {
        addTrackSegments(for: gpx)
    }

    private func addTrackSegments(for gpx: GPXRoot) {
        session.tracks = gpx.tracks

        session.waypoints = gpx.waypoints

        for pin in session.waypoints {
            addWaypoint(pin)
        }

        for oneTrack in session.tracks {
            session.totalTrackedDistance += oneTrack.length

            for segment in oneTrack.segments {
                let overlay = segment.overlay
                addOverlay(overlay)

                let segmentTrackpoints = segment.points

                for waypoint in segmentTrackpoints {
                    extent.extendAreaToIncludeLocation(waypoint.coordinate)
                }
            }
        }
    }

    func addWaypointAtViewPoint(_ point: CGPoint) {
        let coords: CLLocationCoordinate2D = convert(point, toCoordinateFrom: self)

        let waypoint = GPXWaypoint(coordinate: coords)

        addWaypoint(waypoint)
    }

    func addWaypoint(_ waypoint: GPXWaypoint) {
        session.addWaypoint(waypoint)

        addAnnotation(waypoint)

        extent.extendAreaToIncludeLocation(waypoint.coordinate)
    }

    func updateHeading() {
        guard let heading else {
            return
        }

        headingImageView?.isHidden = false

        let rotation = CGFloat((heading.trueHeading - camera.heading) / 180 * Double.pi)

        var newRotation = rotation

        if let headingOffset {
            newRotation = rotation + headingOffset
        }

        UIView.animate(withDuration: 0.15) {
            self.headingImageView?.transform = CGAffineTransform(rotationAngle: newRotation)
        }
    }

    func removeWaypoint(_ waypoint: GPXWaypoint) {
        let index = session.waypoints.firstIndex(of: waypoint)

        if index == nil {
            print("Waypoint not found")
            return
        }
        removeAnnotation(waypoint)

        session.waypoints.remove(at: index!)
    }
}
