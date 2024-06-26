//  RideTogether
//
//  Created by Kai Fu Jhuang on 2022/4/8.
//

import MapKit

class ParkMapOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect

    init(park: Park) {
        coordinate = park.midCoordinate
        boundingMapRect = park.overlayBoundingMapRect
    }
}
