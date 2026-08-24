

import UIKit
import MapKit
import CoreLocation
import Lottie

protocol sendRouteSecond {
    func sendRouteTwice(map: DrawRoute)
}

class RouteSelectionViewController: UIViewController, sendRoutefirst {
    
    var weatherdata : ResponseBody?
    
    let weatherManger = WeatherManager.shared
    
    @IBOutlet weak var feelsLikeTempLabel: UILabel!
    
    @IBOutlet weak var humidityLabel: UILabel!
    
    @IBOutlet weak var showtempLabel: UILabel!
    
    @IBOutlet weak var sunriseLabel: UILabel!
    
    @IBOutlet weak var sunsetLabel: UILabel!
    
    @IBOutlet weak var windLabel: UILabel!
    
    func getWeatherData() {
        
        weatherManger.getGroupAPI(latitude: locationManager.location?.coordinate.latitude ?? 25.1, longitude: locationManager.location?.coordinate.longitude ?? 121.12) { [weak self] result in
            
            guard let self = self else { return }
            
            self.weatherdata = result
            
            DispatchQueue.main.async {
                self.showWeatherInfo()
            }
        }
    }
    
    private func showWeatherInfo(){
        guard let feelslike = weatherdata?.main.feelsLike.roundDouble() else { return }
        feelsLikeTempLabel.text = "\(feelslike) °C"
        guard let humiditydata = weatherdata?.main.humidity else { return }
        humidityLabel.text = "\(humiditydata) %"
        
        guard let tempdata = weatherdata?.main.tempMax.roundDouble() else { return }
        showtempLabel.text = "\(tempdata) °C"
        
        guard let ssunrise = weatherdata?.sys.sunrise else { return }
        let epocTime = TimeInterval(ssunrise)
        
        sunriseLabel.text = "\(epocTime.sunrise()) AM"
        
        guard let ssunset = weatherdata?.sys.sunset else { return }
        let sunsetTime = TimeInterval(ssunset)
        
        sunsetLabel.text = "\(sunsetTime.sunset()) PM"
        
        guard let swind = weatherdata?.wind.speed.roundDouble() else { return }
        windLabel.text = "\(swind) km/h"
        
        guard let weather = weatherdata?.weather[0].main else { return }
        
        if weather == "Rain" {
            rainLottieView.isHidden = false
            rainLottieView.play()
        }
                
        if weather == "Clouds" {
            cloudsLottieView.isHidden = false
            cloudsLottieView.play()
        }
                
        if weather == "Drizzle" {
            rainLottieView.isHidden = false
            rainLottieView.play()
        }
                
        if weather == "Sun" {
            sunLottieView.isHidden = false
            sunLottieView.play()
        }

    }
        
    func sendRoute(map: DrawRoute) {
        mapdata = map
        delegate?.sendRouteTwice(map: mapdata!)
    }
    
    var mapdata : DrawRoute?
    
    var delegate: sendRouteSecond?
    
    private var editingTextField: UITextField?
    private var currentRegion: MKCoordinateRegion?
    private var currentPlace: CLPlacemark?
    
    private let locationManager = CLLocationManager()
    private let completer = MKLocalSearchCompleter()
    
    private let defaultAnimationDuration: TimeInterval = 0.25
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attemptLocationAccess()
        getWeatherData()
        
    }
    
    private lazy var cloudsLottieView: AnimationView = {
        let view = AnimationView(name: "cloud")
        view.loopMode = .loop
        view.frame = CGRect(x: -30, y: -150 , width: 400 , height: 400)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    private lazy var rainLottieView: AnimationView = {
        let view = AnimationView(name: "rain")
        view.loopMode = .loop
        view.frame = CGRect(x: UIScreen.width / 2 - 100, y: -25 , width: 200 , height: 200)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    private lazy var sunLottieView: AnimationView = {
        let view = AnimationView(name: "sun")
        view.loopMode = .loop
        view.frame = CGRect(x: 0, y: 0 , width: 150 , height: 150)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    private lazy var otherLottieView: AnimationView = {
        let view = AnimationView(name: "otherweather")
        view.loopMode = .loop
        view.frame = CGRect(x: 0, y: 0 , width: 150 , height: 150)
        view.contentMode = .scaleAspectFit
        view.play()
        self.view.addSubview(view)
        return view
    }()
    
    private func attemptLocationAccess() {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            locationManager.requestLocation()
        }
    }
    
    private func presentAlert(message: String) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        present(alertController, animated: true)
        
    }
}

// MARK: - CLLocationManagerDelegate

extension RouteSelectionViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else {
            return
        }
        
        let commonDelta: CLLocationDegrees = 25 / 111
        
        let span = MKCoordinateSpan(latitudeDelta: commonDelta, longitudeDelta: commonDelta)
        
        let region = MKCoordinateRegion(center: firstLocation.coordinate, span: span)
        
        currentRegion = region
        completer.region = region
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error requesting location: \(error.localizedDescription)")
    }
}
