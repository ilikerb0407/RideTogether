




import MapKit

class ParkMapOverlay: NSObject, MKOverlay {
  let coordinate: CLLocationCoordinate2D
  let boundingMapRect: MKMapRect

  init(park: Park) {
    boundingMapRect = park.overlayBoundingMapRect
    coordinate = park.midCoordinate
  }
}
