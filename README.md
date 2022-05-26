# RideTogether
RideTogether is an app allows users to record routes and to share with friends. Moreover, users can handily create or join groups to enjoy cycling.


1. Implemented MapKit, Core Location and CoreGPX to draw line of navigation for users to follow.

Below is code :

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

2. Established project from OpenWeather APIs and notify users about weather condition according to users' location. 

Below is code :

ˋˋˋSwift

import CoreLocation

class WeatherManager {
    
    func getGroupAPI(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (ResponseBody) -> Void) {
        
        let urlString = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)...)
        
        guard let urlString = urlString else { return }
        let url = URLRequest(url: urlString)
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
            
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                let firstData = try decoder.decode(ResponseBody.self, from: data)
                completion(firstData)
                
                LKProgressHUD.showSuccess()
               
            } catch {
                LKProgressHUD.showFailure()
            }
            
        }) .resume()
    }
    
}


ˋˋˋ

3. Utilized MapKit and Core Location framework to enhance accessibility for user to find the nearby bikes.

Below is code:

ˋˋˋSwift 

class UBikeViewController {

        func layOutTaichungBike() {
        
        for bike in taichungBikeData!.retVal {
            
            let coordinate = CLLocationCoordinate2D(latitude: Double(bike.value.lat) ?? 0.0, longitude: Double(bike.value.lng) ?? 0.0)
            
            let title = bike.value.sna
             
            let subtitle = "return:\(bike.value.bemp), rent :\(bike.value.sbi)"
            
            let annotation = BikeAnnotation(title: title, subtitle: subtitle, coordinate: coordinate)

            ...
            
            let distance = usersCoordinate.distance(from: bikeStopCoordinate)

                    if  distance < 1000 {
                        bikeMapView.addAnnotation(annotation)
                    }
        }
        
    }

}


ˋˋˋ
