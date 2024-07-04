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

        self.currentSegment.add(trackpoint: point)

        if self.currentSegment.points.count >= 2 {
            let prevPoint = self.currentSegment.points[self.currentSegment.points.count - 2]

            guard let latitude = prevPoint.latitude,
                  let longitude = prevPoint.longitude else {
                return
            }
            let prevPtLoc = CLLocation(latitude: latitude, longitude: longitude)

            let distance = prevPtLoc.distance(from: location)

            self.currentTrackDistance += distance

            self.totalTrackedDistance += distance

            self.currentSegmentDistance += distance
        }
    }

    func startNewTrackSegment() {
        if !self.currentSegment.points.isEmpty {
            self.trackSegments.append(self.currentSegment)

            self.currentSegment = GPXTrackSegment()

            self.currentSegmentDistance = 0.00
        }
    }

    func reset() {
        self.trackSegments = []

        self.tracks = []

        self.currentSegment = GPXTrackSegment()

        self.totalTrackedDistance = 0.00

        self.currentTrackDistance = 0.00

        self.currentSegmentDistance = 0.00
    }

    func exportToGPXString() -> String {
        let gpx = GPXRoot(creator: "RideTogether")

        gpx.add(waypoints: self.waypoints)

        let track = GPXTrack()

        track.add(trackSegments: self.trackSegments)

        if !self.currentSegment.points.isEmpty {
            track.add(trackSegment: self.currentSegment)
        }

        gpx.add(tracks: self.tracks)

        gpx.add(track: track)

        return gpx.gpx()
    }

    func continueFromGPXRoot(_ gpx: GPXRoot) {
        let lastTrack = gpx.tracks.last ?? GPXTrack()

        totalTrackedDistance += lastTrack.length

        self.tracks = gpx.tracks

        self.trackSegments = lastTrack.segments

        self.tracks.removeLast()
    }

    func addWaypoint(_ waypoint: GPXWaypoint) {
        self.waypoints.append(waypoint)
    }
}
