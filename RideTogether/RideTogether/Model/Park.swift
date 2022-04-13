/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MapKit

class Park {
  var name: String?
  var boundary: [CLLocationCoordinate2D] = []

  var midCoordinate = CLLocationCoordinate2D()
  var overlayTopLeftCoordinate = CLLocationCoordinate2D()
  var overlayTopRightCoordinate = CLLocationCoordinate2D()
  var overlayBottomLeftCoordinate = CLLocationCoordinate2D()
  var overlayBottomRightCoordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(
      latitude: overlayBottomLeftCoordinate.latitude,
      longitude: overlayTopRightCoordinate.longitude)
  }

  var overlayBoundingMapRect: MKMapRect {
    let topLeft = MKMapPoint(overlayTopLeftCoordinate)
    let topRight = MKMapPoint(overlayTopRightCoordinate)
    let bottomLeft = MKMapPoint(overlayBottomLeftCoordinate)

    return MKMapRect(
      x: topLeft.x,
      y: topLeft.y,
      width: fabs(topLeft.x - topRight.x),
      height: fabs(topLeft.y - bottomLeft.y))
  }

  init(filename: String) {
    guard
      let properties = Park.plist(filename) as? [String: Any],
      let boundaryPoints = properties["boundary"] as? [String]
      else { return }

    midCoordinate = Park.parseCoord(dict: properties, fieldName: "midCoord")
    overlayTopLeftCoordinate = Park.parseCoord(
      dict: properties,
      fieldName: "overlayTopLeftCoord")
    overlayTopRightCoordinate = Park.parseCoord(
      dict: properties,
      fieldName: "overlayTopRightCoord")
    overlayBottomLeftCoordinate = Park.parseCoord(
      dict: properties,
      fieldName: "overlayBottomLeftCoord")

    let cgPoints = boundaryPoints.map { NSCoder.cgPoint(for: $0) }
    boundary = cgPoints.map { CLLocationCoordinate2D(
      latitude: CLLocationDegrees($0.x),
      longitude: CLLocationDegrees($0.y))
    }
  }

  static func plist(_ plist: String) -> Any? {
    guard
      let filePath = Bundle.main.path(forResource: plist, ofType: "plist"),
      let data = FileManager.default.contents(atPath: filePath)
      else { return nil }

    do {
      return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    } catch {
      return nil
    }
  }

  static func parseCoord(dict: [String: Any], fieldName: String) -> CLLocationCoordinate2D {
    if let coord = dict[fieldName] as? String {
      let point = NSCoder.cgPoint(for: coord)
      return CLLocationCoordinate2D(
        latitude: CLLocationDegrees(point.x),
        longitude: CLLocationDegrees(point.y))
    }
    return CLLocationCoordinate2D()
  }
}
