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

    required init?(coder aDecoder: NSCoder) {
        var tmpCoords: [CLLocationCoordinate2D] = []

        currentSegmentOverlay = MKPolyline(coordinates: &tmpCoords, count: 0)

        super.init(coder: aDecoder)

        isUserInteractionEnabled = true

        isMultipleTouchEnabled = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let compassView = subviews.filter({ $0.isKind(of: NSClassFromString("MKCompassView")!) }).first {
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
        if session.currentSegment.points.count > 0 {
            session.startNewTrackSegment()
            currentSegmentOverlay = MKPolyline()
        }
    }

    /// Fully resets the map AND the underlying recording session: clears
    /// tracked points, removes every overlay (including the user's
    /// in-progress route), and removes every annotation. Use only when the
    /// user is actually abandoning/restarting the recording — e.g. when
    /// leaving the Journey screen or explicitly discarding a ride.
    ///
    /// This is intentionally the only place allowed to call
    /// `removeAllOverlaysIncludingTrack()`.
    func resetMapAndRecordingSession() {
        session.reset()
        removeAllOverlaysIncludingTrack()
        removeAnnotations(annotations)
        extent = GPXExtentCoordinates()
    }

    /// Removes every overlay on the map, including the user's in-progress
    /// recorded route. This is a destructive operation — kept `private` so
    /// UI actions like "remove pin" can't reach for it by mistake. Only
    /// `resetMapAndRecordingSession()` should ever call this.
    private func removeAllOverlaysIncludingTrack() {
        removeOverlays(overlays)
    }

    /// Removes navigation/guide-related overlays (e.g. the walking
    /// directions polyline shown after tapping a dropped pin) while
    /// preserving the polyline that represents the user's in-progress
    /// recorded route.
    ///
    /// UI actions like "remove pin" or "drop a new pin" should call this
    /// instead of the destructive, private `removeAllOverlaysIncludingTrack()`,
    /// which wipes the entire overlays collection indiscriminately —
    /// including the route the user is actively recording. That was the
    /// root cause of the route visibly disappearing until the next location
    /// update silently rebuilt it (see `addPointToCurrentTrackSegmentAtLocation`).
    ///
    /// We identify the overlay to keep by object identity (`!==`) rather
    /// than by `title` string comparison, so this stays correct even if a
    /// future overlay type forgets to set its title.
    func removeNavigationOverlays() {
        let overlaysToRemove = overlays.filter { $0 !== currentSegmentOverlay }
        removeOverlays(overlaysToRemove)
    }

    func exportToGPXString() -> String {
        return session.exportToGPXString()
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
        guard let heading = heading else { return }

        headingImageView?.isHidden = false

        let rotation = CGFloat((heading.trueHeading - camera.heading) / 180 * Double.pi)

        var newRotation = rotation

        if let headingOffset = headingOffset {
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
