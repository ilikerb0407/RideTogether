# RideTogether
RideTogether is an app allows users to record routes and to share with friends. Moreover, users can handily create or join groups to enjoy cycling.


1. Implemented MapKit, Core Location and CoreGPX to draw line of navigation for users to follow.

ˋˋˋSwift 
import CoreGPX
import MapKit
import CoreLocation

class MapPin {

    func guide(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotationView = MKPinAnnotationView()
        guard let waypoint = view.annotation as? GPXWaypoint else { return }
        let targetCoordinate = annotationView.annotation?.coordinate
        let targetPlaceMark = MKPlacemark(coordinate: targetCoordinate ?? waypoint.coordinate)
        let targetItem = MKMapItem(placemark: targetPlaceMark)
        let userMapItem = MKMapItem.forCurrentLocation()
        ...
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [self]  response, error in
            
            if error == nil {
                
                self.directionsResponse = response!
                
                self.route = self.directionsResponse.routes[0]
                
            } else {
                
                LKProgressHUD.showFailure(text: "無法導航")
            }
        }
    }
}
ˋˋˋ
