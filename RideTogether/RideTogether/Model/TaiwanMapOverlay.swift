

//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//


import MapKit

class ParkMapOverlay: NSObject, MKOverlay {
  let coordinate: CLLocationCoordinate2D
  let boundingMapRect: MKMapRect

  init(park: Park) {
    boundingMapRect = park.overlayBoundingMapRect
    coordinate = park.midCoordinate
  }
}
