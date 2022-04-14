//
//  GPXMap.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import CoreGPX


class GPXMapView: MKMapView {
    
    ///
    let coreDataHelper = CoreDataHelper()

    let session = GPXSession()
    
    var waypoints: [GPXWaypoint] = []

    var currentSegmentOverlay: MKPolyline
    
    var extent: GPXExtentCoordinates = GPXExtentCoordinates()

    var headingOffset: CGFloat?
    
    /// Heading of device
    var heading: CLHeading?
    
    /// Arrow image to display heading (orientation of the device)
    /// initialized on MapViewDelegate
    var headingImageView: UIImageView?
    
    /// Gesture for heading arrow to be updated in realtime during user's map interactions
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
    
    func finishCurrentSegment() {
        startNewTrackSegment()
    }
    
    func clearMap() {
        session.reset()
        removeOverlays(overlays)
        removeAnnotations(annotations)
        extent = GPXExtentCoordinates()
    }

    func exportToGPXString() -> String {
        return session.exportToGPXString()
    }
   
    func regionToGPXExtent() {
        setRegion(extent.region, animated: true)
    }
    
    func importFromGPXRoot(_ gpx: GPXRoot) {
        clearMap()
        addTrackSegments(for: gpx)
    }

    private func addTrackSegments(for gpx: GPXRoot) {
        session.tracks = gpx.tracks
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
    
  //MARK: Parameters: The waypoint to add to the map.
    
    
    func addWaypoint(_ waypoint: GPXWaypoint) {
        session.addWaypoint(waypoint)
        addAnnotation(waypoint)
        extent.extendAreaToIncludeLocation(waypoint.coordinate)
        print("\(waypoint)")
    }
    
 //MARK: 磁鐵
    func updateHeading() {
        guard let heading = heading else { return }
        
        headingImageView?.isHidden = false
        let rotation = CGFloat((heading.trueHeading - camera.heading)/180 * Double.pi)
        
        var newRotation = rotation
        
        if let headingOffset = headingOffset {
            newRotation = rotation + headingOffset
        }
 
        UIView.animate(withDuration: 0.15) {
            self.headingImageView?.transform = CGAffineTransform(rotationAngle: newRotation)
        }
    }
    
    //MARK:  移除座標
    
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
