//
//  GPXSession.swift
//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import CoreGPX
import CoreLocation
import Foundation

class GPXSession {
    var waypoints: [GPXWaypoint] = []

    var tracks: [GPXTrack] = []

    var trackSegments: [GPXTrackSegment] = []

    var currentSegment: GPXTrackSegment = .init()

    var totalTrackedDistance = 0.00

    var currentTrackDistance = 0.00

    var currentSegmentDistance = 0.00

    func addPointToCurrentTrackSegmentAtLocation(_ location: CLLocation) {
        let point = GPXTrackPoint(location: location)

        currentSegment.add(trackpoint: point)

        if currentSegment.points.count >= 2 {
            let prevPoint = currentSegment.points[currentSegment.points.count - 2]

            guard let latitude = prevPoint.latitude,
                  let longitude = prevPoint.longitude else { return }
            let prevPtLoc = CLLocation(latitude: latitude, longitude: longitude)

            let distance = prevPtLoc.distance(from: location)

            currentTrackDistance += distance

            totalTrackedDistance += distance

            currentSegmentDistance += distance
        }
    }

    func startNewTrackSegment() {
        if currentSegment.points.count > 0 {
            trackSegments.append(currentSegment)

            currentSegment = GPXTrackSegment()

            currentSegmentDistance = 0.00
        }
    }

    func reset() {
        trackSegments = []

        tracks = []

        currentSegment = GPXTrackSegment()

        totalTrackedDistance = 0.00

        currentTrackDistance = 0.00

        currentSegmentDistance = 0.00
    }

    func exportToGPXString() -> String {
        let gpx = GPXRoot(creator: "RideTogether")

        gpx.add(waypoints: waypoints)

        let track = GPXTrack()

        track.add(trackSegments: trackSegments)

        if currentSegment.points.count > 0 {
            track.add(trackSegment: currentSegment)
        }

        gpx.add(tracks: tracks)

        gpx.add(track: track)

        return gpx.gpx()
    }

    func continueFromGPXRoot(_ gpx: GPXRoot) {
        let lastTrack = gpx.tracks.last ?? GPXTrack()

        totalTrackedDistance += lastTrack.length

        tracks = gpx.tracks

        trackSegments = lastTrack.segments

        tracks.removeLast()
    }

    func addWaypoint(_ waypoint: GPXWaypoint) {
        waypoints.append(waypoint)
    }
}
